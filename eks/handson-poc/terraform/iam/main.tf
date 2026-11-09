# Cleaned up from the generated draft:
# - lines that only repeat provider defaults or are empty were removed
#   (path = "/", max_session_duration = 3600, force_detach_policies = false,
#    permissions_boundary = null, description = null, tags_all)
# - real identifiers were replaced with variables and references so the code can
#   be published: the account ID and OIDC issuer come from terraform.tfvars.

# --- IAM OIDC provider of the cluster (needed for IRSA) -----------------------
resource "aws_iam_openid_connect_provider" "cluster" {
  # The AWS API returns the URL without a scheme, but the resource requires one.
  url            = "https://${var.oidc_issuer}"
  client_id_list = ["sts.amazonaws.com"]

  # Kept so the plan shows no difference. EKS OIDC providers no longer depend on
  # it, but it is part of the existing object.
  thumbprint_list = ["06b25927c42a721631c1efd9431e648fa62e1e39"]
}

# --- EKS control-plane role ---------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = local.role_names.cluster

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# --- Worker node role ---------------------------------------------------------
resource "aws_iam_role" "node" {
  name = local.role_names.node

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# --- VPC CNI role (IRSA) ------------------------------------------------------
resource "aws_iam_role" "cni" {
  name        = local.role_names.cni
  description = "AmazonEKS_CNI"

  # Trust only the aws-node service account of this cluster's OIDC provider.
  # Principal = the provider ARN (written once, taken from the resource).
  # Condition keys = the issuer without https:// followed by :aud or :sub.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.cluster.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${var.oidc_issuer}:sub" = "system:serviceaccount:kube-system:aws-node"
        }
      }
    }]
  })

  tags = {
    Team = "infra-team"
  }
}
