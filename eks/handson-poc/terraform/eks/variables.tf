variable "region" {
  description = "AWS region of the cluster."
  type        = string
  default     = "us-east-1"
}

variable "launch_template_id" {
  description = "The ID of the launch template to import (lt-...). Find it with: aws ec2 describe-launch-templates --launch-template-names <name>"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster the nodes join."
  type        = string
}

variable "ami_id" {
  description = "The ID of the EKS-optimized AMI for the nodes (architecture and Kubernetes version must match the cluster). Find it with the SSM parameter described in the build log."
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 key pair for the nodes."
  type        = string
}

variable "account_id" {
  description = "The 12-digit ID of the AWS account that holds the cluster."
  type        = string
}

variable "admin_role" {
  description = "The IAM role (path and name) that has cluster admin access, exactly as shown after role/ in: aws eks list-access-entries"
  type        = string
}