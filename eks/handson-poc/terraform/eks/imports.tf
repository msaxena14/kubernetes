# Record of how the existing resources were brought under Terraform. They are
# already in the state, so these blocks do nothing now; they are kept so the
# state can be rebuilt from scratch. `to` uses the module addresses.
# ID fields come from each resource's identity schema:
#   terraform providers schema -json  (resource_identity_schemas)

import {
  to = module.launch_template.aws_launch_template.nodes
  id = var.launch_template_id
}

import {
  to = module.cluster.aws_eks_cluster.main
  identity = {
    name = var.cluster_name
  }
}

import {
  to = module.node_group.aws_eks_node_group.main
  identity = {
    cluster_name    = var.cluster_name
    node_group_name = "${var.cluster_name}-ng-v1"
  }
}

import {
  to = module.addons.aws_eks_addon.vpc_cni
  identity = {
    cluster_name = var.cluster_name
    addon_name   = "vpc-cni"
  }
}

import {
  to = module.addons.aws_eks_addon.coredns
  identity = {
    cluster_name = var.cluster_name
    addon_name   = "coredns"
  }
}

import {
  to = module.addons.aws_eks_addon.kube_proxy
  identity = {
    cluster_name = var.cluster_name
    addon_name   = "kube-proxy"
  }
}

import {
  to = module.access_entries.aws_eks_access_entry.node
  identity = {
    cluster_name  = var.cluster_name
    principal_arn = "arn:aws:iam::${var.account_id}:role/AmazonEKSAutoNodeRole"
  }
}

import {
  to = module.access_entries.aws_eks_access_entry.bastion
  identity = {
    cluster_name  = var.cluster_name
    principal_arn = "arn:aws:iam::${var.account_id}:role/argocd-poc-bastion-role"
  }
}

import {
  to = module.access_entries.aws_eks_access_policy_association.bastion
  identity = {
    cluster_name  = var.cluster_name
    principal_arn = "arn:aws:iam::${var.account_id}:role/argocd-poc-bastion-role"
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
}

import {
  to = module.access_entries.aws_eks_access_entry.admin
  identity = {
    cluster_name  = var.cluster_name
    principal_arn = "arn:aws:iam::${var.account_id}:role/${var.admin_role}"
  }
}

import {
  to = module.access_entries.aws_eks_access_policy_association.admin
  identity = {
    cluster_name  = var.cluster_name
    principal_arn = "arn:aws:iam::${var.account_id}:role/${var.admin_role}"
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
}
