environment = "prod"
region      = "us-east-1"
owner       = "supermavster"

# One NAT gateway per zone: losing a zone does not cut egress for the others.
nat_gateway_mode        = "per_az"
flow_log_retention_days = 30

# Prod keeps a standby, a longer restore window and a final snapshot.
db_multi_az              = true
db_backup_retention_days = 14
log_retention_days       = 30

# Set to your account ID so a wrong AWS profile fails fast:
# allowed_account_ids = ["<AWS_ACCOUNT_ID>"]
