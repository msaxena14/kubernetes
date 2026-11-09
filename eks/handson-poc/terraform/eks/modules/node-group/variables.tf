variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "node_group_name" {
  description = "The name of the node group."
  type        = string
}

variable "node_role_name" {
  description = "The name of the IAM role the nodes use (created in the iam layer)."
  type        = string
  default     = "AmazonEKSAutoNodeRole"
}

variable "subnet_ids" {
  description = "The IDs of the subnets the nodes run in (one per availability zone)."
  type        = list(string)
}

variable "launch_template_id" {
  description = "The ID of the launch template the nodes use."
  type        = string
}

variable "launch_template_version" {
  description = "The version of the launch template the nodes use."
  type        = string
}

variable "instance_types" {
  description = "Instance types for the nodes; all must match the AMI's architecture."
  type        = list(string)
  default     = ["c6g.large", "c7g.large"]
}

variable "team" {
  description = "Value of the Team tag."
  type        = string
  default     = "infra-team"
}
