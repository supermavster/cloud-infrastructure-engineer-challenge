output "bucket_name" {
  description = "Name of the state bucket. Goes into backend.hcl as bucket."
  value       = aws_s3_bucket.state.id
}

output "region" {
  description = "Region of the state bucket. Goes into backend.hcl as region."
  value       = var.region
}

output "kms_key_arn" {
  description = "KMS key that encrypts the state bucket."
  value       = aws_kms_key.state.arn
}
