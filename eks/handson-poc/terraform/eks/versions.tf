terraform {
  # import blocks: expressions in `id` need 1.6, `for_each` in import needs 1.7
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
