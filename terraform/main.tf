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

module "network" {
  source = "./modules/network"

  name                    = local.name_prefix
  cidr_block              = var.vpc_cidr_block
  az_count                = var.az_count
  nat_gateway_mode        = var.nat_gateway_mode
  flow_log_retention_days = var.flow_log_retention_days
  log_kms_key_arn         = module.kms.key_arns["observability"]
}

module "security" {
  source = "./modules/security"

  name    = local.name_prefix
  vpc_id  = module.network.vpc_id
  db_port = local.db_port
}

module "database" {
  source = "./modules/database"

  name                  = local.name_prefix
  subnet_ids            = module.network.data_subnet_ids
  security_group_id     = module.security.database_security_group_id
  kms_key_arn           = module.kms.key_arns["data"]
  log_kms_key_arn       = module.kms.key_arns["observability"]
  port                  = local.db_port
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
  apply_immediately     = var.db_apply_immediately
  log_retention_days    = var.log_retention_days
}

module "lambda" {
  source = "./modules/lambda"

  name                           = "${local.name_prefix}-info"
  source_dir                     = var.lambda_package_dir
  subnet_ids                     = module.network.app_subnet_ids
  security_group_id              = module.security.lambda_security_group_id
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  log_retention_days             = var.log_retention_days
  log_kms_key_arn                = module.kms.key_arns["observability"]

  environment = {
    DB_HOST        = module.database.address
    DB_PORT        = tostring(module.database.port)
    DB_NAME        = module.database.database_name
    DB_SECRET_ARN  = module.database.master_secret_arn
    DB_INSTANCE_ID = module.database.identifier
  }

  policy_statements = [
    {
      sid       = "ReadDatabaseSecret"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.database.master_secret_arn]
    },
    {
      sid       = "DecryptDatabaseSecret"
      actions   = ["kms:Decrypt"]
      resources = [module.kms.key_arns["data"]]
      conditions = [{
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["secretsmanager.${var.region}.amazonaws.com"]
      }]
    },
    {
      sid       = "DescribeDatabaseInstance"
      actions   = ["rds:DescribeDBInstances"]
      resources = [module.database.arn]
    },
  ]
}
