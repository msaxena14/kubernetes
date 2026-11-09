output "id" {
  description = "The ID of the launch template."
  value       = aws_launch_template.nodes.id
}

output "latest_version" {
  description = "The latest version number of the launch template."
  value       = aws_launch_template.nodes.latest_version
}
