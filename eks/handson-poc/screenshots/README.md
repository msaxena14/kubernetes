# Screenshots and log evidence

Evidence from the EKS 1.37 build documented in [../docs](../docs). Identifiers are masked: AWS account ID, public IPs, the cluster endpoint, the certificate, resource IDs (VPC, subnet, security group, instance, AMI, launch template), the SSO role hash and personal details. The cluster and everything around it have since been deleted.

## Screenshots
| # | File | What it shows |
|---|---|---|
| 1 | [01-bastion-ssh-kubectl-get-nodes.png](01-bastion-ssh-kubectl-get-nodes.png) | SSH to the bastion, then `kubectl get po -A` and `get nodes -o wide`: one `Ready` arm64 node, CoreDNS, kube-proxy and aws-node all `Running` |
| 2 | [02-eks-compute-nodes-and-nodegroup.png](02-eks-compute-nodes-and-nodegroup.png) | EKS console, Compute tab: cluster Active on 1.37, a Ready node, the managed node group Active on a custom launch template |
| 3 | [03-eks-addons.png](03-eks-addons.png) | The three add-ons Active; the VPC CNI gets credentials from its own IRSA role, not Pod Identity |
| 4 | [04-eks-access-entries.png](04-eks-access-entries.png) | The five IAM access entries: the node role (`EC2_LINUX`, group `system:nodes`), the bastion and admin roles (`STANDARD` with `AmazonEKSClusterAdminPolicy`) and the AWS-managed service role |
| 5 | [05-eks-networking.png](05-eks-networking.png) | Private-only API endpoint, IPv4, service CIDR `172.20.0.0/16` |
| 6 | [06-vpc-resource-map.png](06-vpc-resource-map.png) | VPC resource map: public and private subnets in two AZs, route tables, internet gateway and NAT gateway |
| 7 | [07-launch-template-details.png](07-launch-template-details.png) | The node launch template: custom AMI, key pair, no subnet, security group or instance type (those live on the node group) |
| 8 | [08-launch-template-user-data.png](08-launch-template-user-data.png) | The nodeadm `NodeConfig` user data (endpoint and certificate masked) |
| 9 | [09-bastion-instance-and-security-group.png](09-bastion-instance-and-security-group.png) | The bastion instance and its security group: SSH from one address only |
| 10 | [10-terraform-state-list.png](10-terraform-state-list.png) | `terraform state list` after importing the stack (taken before the layer was split into modules) |
| 11 | [11-nodegroup-create-failed.png](11-nodegroup-create-failed.png) | A failed node group: `NodeCreationFailure`, "Instances failed to join the kubernetes cluster" |

## Logs
| File | What it shows |
|---|---|
| [logs/01-nodeadm-403-retries.txt](logs/01-nodeadm-403-retries.txt) | nodeadm retrying `ec2:DescribeInstances` and getting HTTP 403 on a new node, then succeeding once the right policy was attached |
| [logs/02-authenticator-access-granted.txt](logs/02-authenticator-access-granted.txt) | The EKS authenticator granting the node role the `system:nodes` group |

The errors behind screenshot 11 and the first log are written up in [../docs/issues.md](../docs/issues.md).
