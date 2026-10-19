# Build log

The second, clean build of the cluster, in the order it was done. The first attempt hit a long chain of errors; each one is written up in [issues.md](issues.md) and the checks that prevent them are built into the steps below.

Placeholders: `<ACCOUNT_ID>`, `<CLUSTER>`, `<VPC_ID>`, `<LT_ID>`, `<NODE_ROLE>`, etc. Region is `us-east-1`, profile `<profile>`.

## Overview

| Layer | What |
|---|---|
| Network | VPC `10.60.0.0/16` (Terraform): 2 public + 2 private subnets across 2 AZs, IGW, one NAT gateway, DNS support and DNS hostnames on |
| Control plane | EKS 1.36, Auto Mode off, **private-only** API endpoint, access entries enabled |
| Nodes | Managed node group on AL2023 (arm64), custom launch template, `c6g.large` / `c7g.large`, 1 to 2 nodes, private subnets |
| CNI credentials | Node role carries `AmazonEKS_CNI_Policy` (no Pod Identity) |
| Access | Private endpoint, reached from a bastion in the VPC |

---

## 1. Prerequisites

- AWS CLI profile with a `[profile <name>]` header in `~/.aws/config` (a bare `[name]` header is ignored by Terraform; see issues.md).
- Find out the organization's required tags before creating anything. Here an SCP denies `ec2:RunInstances` unless the instance carries a `Team` tag.
- Terraform for the VPC; the rest was done in the console and CLI first, to learn each piece.

## 2. VPC (Terraform)

Created with Terraform (modules for public subnets, private subnets, IGW, NAT, route tables).

Key points:
- Both `enable_dns_support` and `enable_dns_hostnames` must be `true`. A private-only EKS endpoint resolves through a private hosted zone that needs both.
- The NAT gateway sits in a **public** subnet; the private route table points `0.0.0.0/0` at it. The public route table points `0.0.0.0/0` at the IGW.
- Public subnets do not auto-assign public IPs.

Verify:
```bash
aws ec2 describe-vpc-attribute --vpc-id <VPC_ID> --attribute enableDnsHostnames
aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=<PRIVATE_SUBNET_ID> \
  --query 'RouteTables[].Routes[?DestinationCidrBlock==`0.0.0.0/0`]'
```
Expect `true`, and a `NatGatewayId` in state `active`.

## 3. Cluster IAM role

Trust `eks.amazonaws.com` (`sts:AssumeRole` and `sts:TagSession`), policy `AmazonEKSClusterPolicy`.

The console role wizard froze the browser (a memory-starved laptop rendering the full managed-policy list), so the role was created from the CLI:
```bash
aws iam create-role --role-name <CLUSTER_ROLE> --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}'
aws iam attach-role-policy --role-name <CLUSTER_ROLE> --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```
Verify: `aws iam list-attached-role-policies --role-name <CLUSTER_ROLE>` lists the policy. A role with the right trust but no policy attached is a silent trap.

## 4. Create the cluster (console wizard)

| Area | Setting |
|---|---|
| Name / version | `<CLUSTER>`, Kubernetes 1.36, standard upgrade support |
| EKS Auto Mode | Disabled (managed node groups instead) |
| Cluster IAM role | The role from step 3 |
| Authentication mode | EKS API and ConfigMap (access entries supported) |
| Cluster admin access | Allowed (creator gets admin) |
| Control plane scaling tier | Standard |
| Deletion protection | Enabled (must be turned off before `delete-cluster` at teardown) |
| Tags | `Team`, `Environment` |
| VPC / subnets | The Terraform VPC, the two **private** subnets |
| Additional security group | The VPC default SG (self-referencing) |
| IP family | IPv4 |
| API endpoint access | **Private** |
| Control plane egress | AWS managed |
| Network flow monitoring | Disabled |
| Control plane logs | All off at creation (turn on later, see step 11) |
| Add-ons in the wizard | `coredns`, `kube-proxy` only |
| Pod Identity associations | None |

Things to watch in this wizard:
- Step 5 shows a **Pod Identity IAM role for service account** dropdown for the CNI. It started empty, then showed the cluster role selected. The cluster role trusts `eks.amazonaws.com`, so it is wrong for Pod Identity (needs `pods.eks.amazonaws.com`) and would also need the `eks-pod-identity-agent` add-on. VPC CNI was removed from the wizard and added after the cluster existed.
- The "Inherit from node" option only appears on an existing cluster's Add-ons tab, not in the wizard.

## 5. VPC CNI add-on

Added from the cluster's Add-ons tab after the cluster was `ACTIVE`, before any node group.

Decision: **the CNI gets credentials from the node role** (the node role carries `AmazonEKS_CNI_Policy`, step 6). Pod Identity was rejected because it needs an extra add-on (the agent); an IRSA role was created and then not used (see decisions.md).

IRSA setup, for reference. It needs an IAM OIDC provider, which EKS does not create for you:
```bash
aws iam create-open-id-connect-provider --url <OIDC_ISSUER_URL> --client-id-list sts.amazonaws.com
```
Trust policy for the role (note the `${ISS}` braces if you build this in a zsh heredoc):
```json
{"Version":"2012-10-17","Statement":[{"Effect":"Allow",
 "Principal":{"Federated":"arn:aws:iam::<ACCOUNT_ID>:oidc-provider/<OIDC_ISSUER_HOST_AND_PATH>"},
 "Action":"sts:AssumeRoleWithWebIdentity",
 "Condition":{"StringEquals":{
   "<OIDC_ISSUER_HOST_AND_PATH>:aud":"sts.amazonaws.com",
   "<OIDC_ISSUER_HOST_AND_PATH>:sub":"system:serviceaccount:kube-system:aws-node"}}}]}
```
Attach `AmazonEKS_CNI_Policy`, then set it on the add-on only if you choose IRSA:
```bash
aws eks update-addon --cluster-name <CLUSTER> --addon-name vpc-cni --service-account-role-arn <IRSA_ROLE_ARN>
```

Verify there is no stray Pod Identity association:
```bash
aws eks list-pod-identity-associations --cluster-name <CLUSTER>
```
Expect an empty list.

## 6. Node IAM role

Trust `ec2.amazonaws.com`. Policies:

| Policy | Why |
|---|---|
| `AmazonEKSWorkerNodePolicy` | kubelet and nodeadm. Includes `ec2:DescribeInstances`, which nodeadm needs at boot; the "minimal" worker policy lacks it and nodeadm waited ~6 minutes. |
| `AmazonEC2ContainerRegistryReadOnly` | Pull images from ECR |
| `AmazonEKS_CNI_Policy` | The CNI (`aws-node`) uses the node role for credentials |

Do **not** pre-create an access entry for this role. EKS creates the correct `EC2_LINUX` entry (`system:node:{{EC2PrivateDNSName}}`) when the node group is created, but only if none exists. A hand-made entry of type `EC2` (Auto Mode style) breaks node registration.

## 7. Launch template

Sets: AMI, user data, key pair, tags. Deliberately does **not** set: subnet, instance profile, instance type (types live on the node group), security groups.

- AMI: EKS-optimized AL2023, arm64, matching the cluster version. Using a custom AMI makes the node group type `CUSTOM`, so user data is mandatory.
- Tags: `Team` and `Environment` in `tag_specifications` for `instance` (the console field is "Resource tags", not "Template tags"; template tags do not reach the instances).
- No security groups: EKS then attaches the **cluster security group** to the nodes. That group allows all traffic from itself and the control plane ENIs carry it too, so nodes, control plane and the 10250/443 paths need no extra rules.

User data (every line at column 0, whole `--node-labels` flag on one line):
```
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    apiServerEndpoint: <API_ENDPOINT>
    certificateAuthority: <BASE64_CA_ONE_LINE>
    cidr: <SERVICE_CIDR>
    name: <CLUSTER>
  kubelet:
    config:
      maxPods: 29
      clusterDNS:
      - <SERVICE_CIDR_DOT_10>
    flags:
    - "--node-labels=product=infra,project=<CLUSTER>,env=dev"

--//--
```
- `cidr` is the Kubernetes **service** CIDR (from `describe-cluster`), not the VPC CIDR. `clusterDNS` is its `.10` address.
- `name` must equal the real cluster name; nodeadm uses it for kubelet authentication. After a rebuild this was left at the old cluster's name.
- `maxPods: 29` matches `c6g/c7g.large` (3 ENIs x (10 IPs - 1) + 2).

Verify after creating a template version: decode the stored user data and check line 1 is exactly `MIME-Version: 1.0` and `name:` is the right cluster:
```bash
aws ec2 describe-launch-template-versions --launch-template-id <LT_ID> --versions '$Latest' \
  --query 'LaunchTemplateVersions[0].LaunchTemplateData.UserData' --output text | base64 -d | head -20
```
Also confirm tags: `...LaunchTemplateData.TagSpecifications` must not be `null`.

## 8. Node group

| Area | Setting |
|---|---|
| Node IAM role | The role from step 6 |
| Launch template | Used, version pinned to the corrected one (a node group in `CREATING` cannot change version; delete and recreate) |
| AMI type | "Specified in launch template" |
| Capacity type | On-Demand |
| Instance types | `c6g.large`, `c7g.large` (on the node group; both arm64 to match the AMI) |
| Scaling | min 1, max 2, desired 1 |
| Update config | Max unavailable 1, default strategy |
| ASG warm pool | Off |
| Subnets | The two private subnets, one per AZ (never in the launch template) |

Order of events on the successful run: launch template v1 had the previous cluster's name in the user data, so that node group was deleted and recreated on v2. The node booted, nodeadm finished in about 0.3 s, and the node group reached `ACTIVE` in about 5 minutes.

## 9. Verify

```bash
aws eks describe-nodegroup --cluster-name <CLUSTER> --nodegroup-name <NG> --query 'nodegroup.[status,health.issues]'
aws eks describe-addon --cluster-name <CLUSTER> --addon-name vpc-cni --query 'addon.[status,health.issues]'
aws eks describe-addon --cluster-name <CLUSTER> --addon-name coredns --query 'addon.[status,health.issues]'
```
Node group `ACTIVE` with no issues; `vpc-cni`, `coredns`, `kube-proxy` all `ACTIVE` (add-on health lags a few minutes behind the node, so `DEGRADED` right after the node joins is normal).

Boot-time debugging without SSH or SSM:
```bash
aws ec2 get-console-output --instance-id <ID> --latest --query Output --output text | grep -E 'nodeadm|FAILED'
```
Look for `done! {"duration": ...}` (sub-second is healthy) and for `UnauthorizedOperation`.

## 10. Bastion (kubectl access to the private endpoint)

Needs three separate things (details and the first-attempt values are in issues.md):
1. **IAM**: instance role with only `eks:DescribeCluster` and `eks:ListClusters`, attached through an instance profile. Do not attach broad managed policies (EC2FullAccess, node/cluster policies).
2. **Network**: the bastion lives in the VPC with a public IP (public subnets do not auto-assign), SSH from your IP only, and the cluster SG allows `443` from the bastion SG.
3. **Kubernetes**: an access entry of type `STANDARD` for the bastion role with `AmazonEKSClusterAdminPolicy` at cluster scope.

Then:
```bash
aws eks update-kubeconfig --name <CLUSTER> --region us-east-1
kubectl get nodes -o wide
```

## 11. After the cluster is up

- Turn on control plane logging (`api`, `authenticator`, `audit`); missing logs made debugging much slower.
- Decide on the unused IRSA role and OIDC provider: keep for a later switch, or delete.

## 12. Teardown order

1. Node group, then wait for it to disappear
2. Bastion instance
3. Turn **deletion protection off**, then delete the cluster (10 to 15 minutes)
4. Security groups: revoke each group's rules one at a time (they reference each other), then delete
5. `terraform destroy` for the VPC, subnets, route tables, IGW, NAT and its EIP
6. Launch template, key pair
7. IAM: detach policies, delete inline policies and instance profiles, then roles; plus the IAM OIDC provider if one was created
