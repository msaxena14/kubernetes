# These resources used to live directly in this layer; they now live inside
# modules. A moved block tells Terraform "same object, new address", so it
# updates the state instead of destroying and recreating the real resource.
# Safe to delete once every state that held the old addresses has been applied.

moved {
  from = aws_eks_cluster.main
  to   = module.cluster.aws_eks_cluster.main
}

moved {
  from = aws_launch_template.nodes
  to   = module.launch_template.aws_launch_template.nodes
}

moved {
  from = aws_eks_node_group.main
  to   = module.node_group.aws_eks_node_group.main
}

moved {
  from = aws_eks_addon.vpc_cni
  to   = module.addons.aws_eks_addon.vpc_cni
}

moved {
  from = aws_eks_addon.coredns
  to   = module.addons.aws_eks_addon.coredns
}

moved {
  from = aws_eks_addon.kube_proxy
  to   = module.addons.aws_eks_addon.kube_proxy
}

moved {
  from = aws_eks_access_entry.node
  to   = module.access_entries.aws_eks_access_entry.node
}

moved {
  from = aws_eks_access_entry.bastion
  to   = module.access_entries.aws_eks_access_entry.bastion
}

moved {
  from = aws_eks_access_policy_association.bastion
  to   = module.access_entries.aws_eks_access_policy_association.bastion
}

moved {
  from = aws_eks_access_entry.admin
  to   = module.access_entries.aws_eks_access_entry.admin
}

moved {
  from = aws_eks_access_policy_association.admin
  to   = module.access_entries.aws_eks_access_policy_association.admin
}
