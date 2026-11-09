# Control-plane role from the iam layer, read by name.
data "aws_iam_role" "cluster" {
  name = var.role_name
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = data.aws_iam_role.cluster.arn

  # API_AND_CONFIG_MAP: access entries work, aws-auth still honoured.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Creation-time setting; AWS does not return it reliably after import.
  bootstrap_self_managed_addons = true

  enabled_cluster_log_types = ["api", "authenticator"]
  deletion_protection       = false

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  # ARC zonal shift is off.
  zonal_shift_config {
    enabled = false
  }

  # Private-only API endpoint: kubectl works only from inside the VPC.
  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  tags = {
    Team = var.team
    Name = var.cluster_name
  }

  # Safety rail: Terraform must never delete the cluster.
  lifecycle {
    prevent_destroy = true
  }
}
