output "account_id" {
  description = "AWS account this configuration is applied to. Check it before approving a plan."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region this configuration is applied to."
  value       = var.region
}
