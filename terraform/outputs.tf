output "account_id" {
  description = "AWS account this configuration is applied to. Check it before approving a plan."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region this configuration is applied to."
  value       = var.region
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways. Allow-list these at any service the Lambda calls over the internet."
  value       = module.network.nat_public_ips
}

output "database_identifier" {
  description = "RDS instance identifier. Use it with the RDS and CloudWatch APIs."
  value       = module.database.identifier
}
