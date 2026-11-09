variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "account_id" {
  description = "The 12-digit ID of the AWS account that holds the cluster. Used to build role ARNs."
  type        = string
}

variable "node_role_name" {
  description = "The name of the IAM role the worker nodes use."
  type        = string
  default     = "AmazonEKSAutoNodeRole"
}

variable "bastion_role_name" {
  description = "The name of the IAM role of the bastion host."
  type        = string
  default     = "argocd-poc-bastion-role"
}

variable "admin_role" {
  description = "The IAM role (path and name) with cluster admin access, exactly as shown after role/ in: aws eks list-access-entries"
  type        = string
}
