# EKS access entries: who may use the cluster API, and with what permissions.
# The service-linked role entry (AWSServiceRoleForAmazonEKS) is owned by AWS and
# is deliberately NOT managed here.

# Worker nodes. EC2_LINUX makes the username system:node:<private DNS name>,
# which must match the node name or the kubelet cannot register. No policy needed.
resource "aws_eks_access_entry" "node" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/${var.node_role_name}"
  type          = "EC2_LINUX"
}

# Bastion: kubectl access to the private endpoint.
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/${var.bastion_role_name}"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.bastion.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Cluster admin (the SSO administrator role that created the cluster).
resource "aws_eks_access_entry" "admin" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/${var.admin_role}"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
