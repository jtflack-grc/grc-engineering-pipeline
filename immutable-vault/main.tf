terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project         = "grc-engineering-pipeline"
      Environment     = "evidence"
      ManagedBy       = "Terraform"
      ComplianceScope = "NIST-800-53"
      Purpose         = "immutable-evidence-vault"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 6
}

resource "aws_s3_bucket" "evidence_vault" {
  bucket              = "${var.bucket_prefix}-${random_id.suffix.hex}"
  object_lock_enabled = true
  force_destroy       = false
}

resource "aws_s3_bucket_versioning" "evidence_vault" {
  bucket = aws_s3_bucket.evidence_vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence_vault" {
  bucket = aws_s3_bucket.evidence_vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "evidence_vault" {
  bucket = aws_s3_bucket.evidence_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object_lock_configuration" "evidence_vault" {
  depends_on = [aws_s3_bucket_versioning.evidence_vault]
  bucket     = aws_s3_bucket.evidence_vault.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.retention_days
    }
  }
}
