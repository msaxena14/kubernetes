variable "region" {
  description = "AWS region of the cluster."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "The 12-digit ID of the AWS account that holds the cluster. Only used to build the ARN of the OIDC provider for import. Keep the real value in terraform.tfvars, which is git-ignored."
  type        = string
}

variable "oidc_issuer" {
  description = "The cluster's OIDC issuer WITHOUT https://, for example oidc.eks.<region>.amazonaws.com/id/<ID>. Read it with: aws eks describe-cluster --name <cluster> --query cluster.identity.oidc.issuer --output text"
  type        = string
}
