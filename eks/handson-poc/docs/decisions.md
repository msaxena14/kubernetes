# Decisions

Choices made on this build and the reasoning, including alternatives that were considered.

| Decision | Choice | Why |
|---|---|---|
| API endpoint | Private only | Keeps the control plane off the internet. Costs: needs VPC DNS hostnames, and `kubectl` only works from inside the VPC (bastion). |
| Compute model | Managed node group, Auto Mode off | Full control of AMI, user data, tags. Auto Mode would hide the pieces this POC is meant to teach. |
| Node OS | AL2023 with nodeadm | AL2 is not offered for current versions; nodeadm (`NodeConfig`) replaces `bootstrap.sh`. |
| Architecture | arm64 (Graviton, `c6g`/`c7g`) | Cheaper; the AMI and every listed instance type must match. |
| Instance types | Two types on the node group, none in the launch template | Several types give capacity fallback. A type in the template means one type only; setting it in both places is an error. |
| Launch template | Custom AMI and user data, key pair, tags | Needed for the org's required `Team` tag at launch; the AMI makes the node group type `CUSTOM`. |
| Subnets | On the node group, never in the template | The node group spreads nodes across AZs; a subnet in the template pins them to one. |
| Node security group | None; nodes use the cluster SG | Cluster SG allows all traffic from itself and the control plane ENIs carry it, so no cross-SG rules are needed. |
| CNI credentials | Node role with `AmazonEKS_CNI_Policy` | Simplest for a POC. Pod Identity needs the extra agent add-on and failed once without it; IRSA needs an OIDC provider and role. The IRSA role and provider were built and left unused. |
| CNI add-on | Added after the cluster exists | The create-cluster wizard preselects a Pod Identity role and does not offer "Inherit from node". |
| Node worker policy | `AmazonEKSWorkerNodePolicy` (not the Minimal one) | nodeadm needs `ec2:DescribeInstances` at boot; the minimal policy lacks it, costing about 6 minutes per node. |
| Node access entry | Let EKS create it (`EC2_LINUX`) | A pre-made entry of type `EC2` (Auto Mode style) breaks node registration. |
| Access control | EKS access entries (API and ConfigMap mode) | Managed through the API and Terraform, no hand-edited `aws-auth`. |
| Bastion access | Instance role with `eks:DescribeCluster`/`ListClusters` + `STANDARD` access entry + SG rule | Three independent layers: IAM, Kubernetes, network. No broad managed policies. |
| Deletion protection | On for the cluster | Sensible default; remember to turn it off before teardown. |
| IaC approach | Hand-built first, VPC in Terraform | Learn each piece before encoding it. Everything else is still console/CLI and should move to Terraform. |
| Debugging aids | Console output for boot logs; control plane logging on | No SSH or SSM on private nodes; logs were the missing evidence last time. |
