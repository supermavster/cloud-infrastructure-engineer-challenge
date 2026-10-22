environment = "dev"
region      = "us-east-1"
owner       = "supermavster"

# A short window keeps dev create/destroy cycles from piling up scheduled keys.
kms_deletion_window_in_days = 7

# Set to your account ID so a wrong AWS profile fails fast:
# allowed_account_ids = ["<AWS_ACCOUNT_ID>"]
