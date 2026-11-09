# IAM roles and policies

Every role in the EKS build, who assumes it, and which policies it carries. Role names are placeholders.

## At a glance

| Role | Assumed by | Policies | Needed when |
|---|---|---|---|
| Cluster role | The EKS control plane (`eks.amazonaws.com`) | `AmazonEKSClusterPolicy` (+ four more with Auto Mode) | Always |
| Node role | Worker node EC2 instances (`ec2.amazonaws.com`) | `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly` | Managed node groups |
| CNI role | The `aws-node` pod, through IRSA | `AmazonEKS_CNI_Policy` | Always (chosen design); the node role does not carry the CNI policy |
| Bastion role | The bastion EC2 instance (`ec2.amazonaws.com`) | Inline: `eks:DescribeCluster`, `eks:ListClusters` | `kubectl` access to a private endpoint |
| Service-linked role | EKS itself | `AWSServiceRoleForAmazonEKS`, created and managed by AWS | Created automatically; never create or edit it |

Policies only decide what AWS APIs a role may call. Using `kubectl` also needs an EKS **access entry** (see build-log step 10).

---

## 1. Cluster role

Trust: `eks.amazonaws.com`, actions `sts:AssumeRole` and `sts:TagSession`.

**Standard cluster (Auto Mode off), the one used here:**

| Policy | Why |
|---|---|
| `AmazonEKSClusterPolicy` | Lets the control plane manage the cluster's ENIs, security group rules and related EC2/ELB resources |

**With EKS Auto Mode enabled** the role needs these five (this is the set the console creates as `AmazonEKSAutoClusterRole`):

| Policy | Why |
|---|---|
| `AmazonEKSClusterPolicy` | Core control plane permissions |
| `AmazonEKSComputePolicy` | Lets EKS create and manage the EC2 instances Auto Mode runs for you |
| `AmazonEKSBlockStoragePolicyV2` | Create and attach EBS volumes for Auto Mode storage |
| `AmazonEKSLoadBalancingPolicy` | Create and manage load balancers for Services and Ingresses |
| `AmazonEKSNetworkingPolicy` | Manage the networking resources Auto Mode needs |

If Auto Mode is off, the extra four policies are not needed and only add permissions.

## 2. Node role (managed node group)

Trust: `ec2.amazonaws.com`, action `sts:AssumeRole`.

| Policy | Why |
|---|---|
| `AmazonEKSWorkerNodePolicy` | kubelet and nodeadm. Includes `ec2:DescribeInstances`, which nodeadm calls at boot. The "minimal" worker policy lacks it, so nodeadm retried for about 6 minutes before the kubelet started |
| `AmazonEC2ContainerRegistryReadOnly` | Pull images from ECR. (`...PullOnly` is the narrower alternative) |

Do not pre-create an EKS access entry for this role. EKS creates the right `EC2_LINUX` entry when the node group is created, only if none exists yet.

## 3. CNI role (IRSA)

The `aws-node` pod gets its AWS credentials from a dedicated role that carries just `AmazonEKS_CNI_Policy`. The node role deliberately does not carry that policy.

| Item | Value |
|---|---|
| Trust | Federated principal = the cluster's IAM OIDC provider, action `sts:AssumeRoleWithWebIdentity` |
| Conditions | `aud = sts.amazonaws.com` and `sub = system:serviceaccount:kube-system:aws-node` |
| Policy | `AmazonEKS_CNI_Policy` |
| Linked by | `serviceAccountRoleArn` on the `vpc-cni` add-on |
| Needs | An IAM OIDC provider registered for the cluster (EKS does not create it) |

The `sub` condition is what makes it least privilege: no other service account can assume the role.

Alternative not chosen, **Pod Identity**: trust `pods.eks.amazonaws.com` (actions `sts:AssumeRole` and `sts:TagSession`), needs the `eks-pod-identity-agent` add-on installed first, and a pod identity association for `aws-node`. Simpler in Terraform and reusable across clusters, but it failed once in this build when the association existed without the agent.

## Which role gets `AmazonEKS_CNI_Policy`?

Not the cluster role, and in this design not the node role either. The policy is used by the `aws-node` pod running on the nodes, with credentials the pod gets from one of:

1. **The node role** (simplest; used in the first build). Any pod on the node that can reach the instance metadata service could use the same permissions.
2. **A dedicated CNI role** through IRSA or Pod Identity (least privilege: only `aws-node` gets the permission). **This is the chosen design.**

Verify the add-on actually shows the role before creating the node group: if `serviceAccountRoleArn` is empty, `aws-node` falls back to the node role, which has no CNI permission, and nodes stay `NotReady`. See issues.md: "VPC CNI add-on created with no credentials source".

## 4. Bastion role

Trust: `ec2.amazonaws.com`, attached to the instance through an instance profile.

| Permission | Why |
|---|---|
| Inline: `eks:DescribeCluster`, `eks:ListClusters` | `aws eks update-kubeconfig` needs them to read the cluster endpoint and CA |
| Optional: `AmazonSSMManagedInstanceCore` | Only if you reach the bastion with Session Manager instead of SSH |

Do not attach broad managed policies (EC2FullAccess, node or cluster policies, AdministratorAccess). The bastion also needs an EKS access entry, or `kubectl` fails with "You must be logged in to the server".

## Terraform note

These map to four small `aws_iam_role` resources plus `aws_iam_role_policy_attachment` (managed policies) and `aws_iam_role_policy` (inline), and one `aws_iam_instance_profile` for the bastion. Separate IAM from the expensive layers so it can stay deployed while the cluster is destroyed.
