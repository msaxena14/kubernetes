# Lookups, read from AWS so no real identifier is written in the code.

# The existing cluster (its endpoint, certificate and service CIDR feed the node
# user data; its VPC ID feeds the lookups below).
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# The private subnets of the cluster's VPC.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.this.vpc_config[0].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*Private-Subnet*"]
  }
}

# The VPC's default security group, attached to the control plane network
# interfaces as the additional group (the cluster's own group is owned by EKS).
data "aws_security_group" "vpc_default" {
  name   = "default"
  vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
}
