variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the control plane."
  type        = string
  default     = "1.37"
}

variable "role_name" {
  description = "The name of the IAM role the control plane assumes (created in the iam layer)."
  type        = string
  default     = "AmazonEKSAutoClusterRole"
}

variable "subnet_ids" {
  description = "The IDs of the subnets the control plane network interfaces are placed in."
  type        = list(string)
}

variable "security_group_ids" {
  description = "The IDs of additional security groups attached to the control plane network interfaces."
  type        = list(string)
}

variable "service_ipv4_cidr" {
  description = "The CIDR block Kubernetes Service IPs are allocated from. Cannot be changed after creation."
  type        = string
  default     = "172.20.0.0/16"
}

variable "team" {
  description = "Value of the Team tag."
  type        = string
  default     = "infra-team"
}
