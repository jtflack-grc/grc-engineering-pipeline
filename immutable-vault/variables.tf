variable "aws_region" {
  description = "AWS region for the evidence vault."
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Globally unique bucket-name prefix; a random suffix is appended."
  type        = string
  default     = "jtflack-grc-evidence-vault"
}

variable "retention_days" {
  description = "Governance-mode retention applied to uploaded evidence. One day minimizes this demonstration's lifetime and cost."
  type        = number
  default     = 1

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days must be at least 1."
  }
}
