output "bucket_name" {
  description = "Object Lock evidence-vault bucket name."
  value       = aws_s3_bucket.evidence_vault.id
}

output "aws_region" {
  description = "Vault region."
  value       = var.aws_region
}

output "retention_days" {
  description = "Default governance retention in days."
  value       = var.retention_days
}
