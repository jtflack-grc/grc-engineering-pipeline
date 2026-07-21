output "bucket_name" {
  description = "Primary bucket name."
  value       = aws_s3_bucket.primary.id
}

output "bucket_arn" {
  description = "Primary bucket ARN."
  value       = aws_s3_bucket.primary.arn
}

output "log_bucket_name" {
  description = "Log bucket name."
  value       = aws_s3_bucket.log.id
}

output "encryption_algorithm" {
  description = "Machine-readable SC-28 attestation for primary bucket encryption at rest."

  value = one(flatten([
    for rule in aws_s3_bucket_server_side_encryption_configuration.primary.rule : [
      for encryption_default in rule.apply_server_side_encryption_by_default :
      encryption_default.sse_algorithm
    ]
  ]))
}
