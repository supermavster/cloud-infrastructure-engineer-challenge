data "aws_caller_identity" "current" {}

module "kms" {
  source = "./modules/kms"

  name                    = local.name_prefix
  deletion_window_in_days = var.kms_deletion_window_in_days

  keys = {
    data = {
      description = "Encrypts the database storage and its master password secret"
    }
    observability = {
      description             = "Encrypts log groups and the alarm notification topic"
      allow_cloudwatch_logs   = true
      allow_cloudwatch_alarms = true
    }
  }
}
