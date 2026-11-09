# Node role from the iam layer, read by name.
data "aws_iam_role" "node" {
  name = var.node_role_name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  # CUSTOM: the AMI and bootstrap come from the launch template.
  ami_type       = "CUSTOM"
  capacity_type  = "ON_DEMAND"
  instance_types = var.instance_types

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  scaling_config {
    min_size     = 1
    max_size     = 1
    desired_size = 1
  }

  update_config {
    max_unavailable = 1
    update_strategy = "DEFAULT"
  }

  tags = {
    Team = var.team
    Name = var.node_group_name
  }

  # Safety rail: Terraform must never delete the running node group.
  lifecycle {
    prevent_destroy = true
  }
}
