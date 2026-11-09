output "name" {
  description = "The name of the node group."
  value       = aws_eks_node_group.main.node_group_name
}
