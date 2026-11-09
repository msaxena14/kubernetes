variable "cluster_name" {
  description = "The name of the EKS cluster the nodes join. Also used to name the template."
  type        = string
}

variable "ami_id" {
  description = "The ID of the EKS-optimized AMI for the nodes (architecture and Kubernetes version must match the cluster)."
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 key pair for the nodes."
  type        = string
}

variable "api_endpoint" {
  description = "The cluster's API server endpoint (https://...)."
  type        = string
}

variable "certificate_authority" {
  description = "The cluster's certificate authority data, base64 encoded, on one line."
  type        = string
}

variable "service_cidr" {
  description = "The cluster's Kubernetes Service CIDR. The DNS address is computed as its .10 address."
  type        = string
}

variable "team" {
  description = "Value of the Team tag applied to launched instances."
  type        = string
  default     = "infra-team"
}
