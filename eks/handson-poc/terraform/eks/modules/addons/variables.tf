variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "cni_role_name" {
  description = "The name of the IAM role the VPC CNI uses through IRSA (created in the iam layer)."
  type        = string
  default     = "AmazonEKS_CNI"
}

variable "vpc_cni_version" {
  description = "Pinned version of the vpc-cni add-on. Bump on purpose to upgrade."
  type        = string
  default     = "v1.22.4-eksbuild.10"
}

variable "coredns_version" {
  description = "Pinned version of the coredns add-on."
  type        = string
  default     = "v1.14.7-eksbuild.28"
}

variable "kube_proxy_version" {
  description = "Pinned version of the kube-proxy add-on."
  type        = string
  default     = "v1.37.0-eksbuild.34"
}
