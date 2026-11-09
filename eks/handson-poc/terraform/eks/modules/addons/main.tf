# Managed EKS add-ons, pinned to the versions running now so the plan shows no
# change. Bump a version on purpose when you want to upgrade.

# The CNI role lives in the iam layer; read it by name instead of copying an ARN.
data "aws_iam_role" "cni" {
  name = var.cni_role_name
}

# Pod networking. Credentials come from the CNI role through IRSA.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = var.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = var.vpc_cni_version
  service_account_role_arn = data.aws_iam_role.cni.arn
}

# Cluster DNS.
resource "aws_eks_addon" "coredns" {
  cluster_name  = var.cluster_name
  addon_name    = "coredns"
  addon_version = var.coredns_version
}

# Service routing on each node.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = var.cluster_name
  addon_name    = "kube-proxy"
  addon_version = var.kube_proxy_version
}
