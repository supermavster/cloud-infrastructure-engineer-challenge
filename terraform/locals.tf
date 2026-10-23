locals {
  name_prefix = "${var.project}-${var.environment}"
  db_port     = 5432

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "cloud-infrastructure-engineer-challenge"
    Owner       = var.owner
  }
}
