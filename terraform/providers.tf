provider "aws" {
  region = var.region

  # Refuses to run against any account that is not listed. Empty means no guard.
  allowed_account_ids = length(var.allowed_account_ids) > 0 ? var.allowed_account_ids : null

  default_tags {
    tags = local.tags
  }
}
