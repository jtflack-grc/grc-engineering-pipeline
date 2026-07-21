terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.region

  # CM-6: required configuration metadata applied to every taggable resource.
  default_tags {
    tags = {
      Project         = var.project_name
      Environment     = var.environment
      ManagedBy       = "Terraform"
      ComplianceScope = "NIST-800-53"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  primary_name = "${var.project_name}-${var.environment}-data-${random_id.suffix.hex}"
  log_name     = "${var.project_name}-${var.environment}-logs-${random_id.suffix.hex}"
}

# Primary data bucket.
resource "aws_s3_bucket" "primary" {
  bucket = local.primary_name
}

# Dedicated access-log bucket.
resource "aws_s3_bucket" "log" {
  bucket = local.log_name
}

# SC-28: protect information at rest with default SSE-S3 encryption.
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CM-6: configuration baseline requiring versioning on the primary bucket.
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# AC-3: enforce access restrictions by blocking public access on all four vectors.
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket = aws_s3_bucket.log.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AU-3/AU-6: prepare the log bucket to receive S3 server access logs.
# Sequence matters: ownership controls first, then ACL, then logging.
resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log" {
  depends_on = [
    aws_s3_bucket_ownership_controls.log
  ]

  bucket = aws_s3_bucket.log.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "primary" {
  depends_on = [
    aws_s3_bucket_acl.log
  ]

  bucket        = aws_s3_bucket.primary.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "access-logs/"
}
