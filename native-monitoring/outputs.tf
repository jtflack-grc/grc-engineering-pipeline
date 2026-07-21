output "aws_region" {
  description = "AWS region used for the Week 5 baseline."
  value       = var.aws_region
}

output "account_id" {
  description = "AWS account ID where Week 5 was deployed."
  value       = data.aws_caller_identity.current.account_id
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket receiving CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_name" {
  description = "CloudTrail trail name."
  value       = aws_cloudtrail.account_trail.name
}

output "cloudtrail_arn" {
  description = "CloudTrail trail ARN."
  value       = aws_cloudtrail.account_trail.arn
}

output "securityhub_nist_standard_arn" {
  description = "Security Hub NIST 800-53 Rev 5 standard subscription ARN."
  value       = aws_securityhub_standards_subscription.nist_800_53_rev5.standards_arn
}
