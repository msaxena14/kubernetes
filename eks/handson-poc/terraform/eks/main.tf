# The eks layer, one module per component. Each module's inputs are listed in its
# variables.tf.

module "cluster" {
  source = "./modules/cluster"

  cluster_name       = var.cluster_name
  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.vpc_default.id]
}

module "launch_template" {
  source = "./modules/launch-template"

  cluster_name          = var.cluster_name
  ami_id                = var.ami_id
  key_name              = var.key_name
  api_endpoint          = data.aws_eks_cluster.this.endpoint
  certificate_authority = data.aws_eks_cluster.this.certificate_authority[0].data
  service_cidr          = data.aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr
}

module "node_group" {
  source = "./modules/node-group"

  cluster_name            = var.cluster_name
  node_group_name         = "${var.cluster_name}-ng-v1"
  subnet_ids              = data.aws_subnets.private.ids
  launch_template_id      = module.launch_template.id
  launch_template_version = tostring(module.launch_template.latest_version)
}

module "addons" {
  source = "./modules/addons"

  cluster_name = var.cluster_name
}

module "access_entries" {
  source = "./modules/access-entries"

  cluster_name = var.cluster_name
  account_id   = var.account_id
  admin_role   = var.admin_role
}
