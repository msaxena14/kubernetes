# Credentials come from the environment (export AWS_PROFILE=<profile>), so no
# profile name is written in code.
provider "aws" {
  region = var.region
}
