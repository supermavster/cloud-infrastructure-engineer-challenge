terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }

  # Bucket, key and region are supplied at init time from
  # environments/<env>/backend.hcl so this code has no account-specific values.
  backend "s3" {}
}
