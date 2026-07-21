variable "aws_region" {
  description = "AWS region for Security Hub and CloudTrail control plane operations."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used in names and tags."
  type        = string
  default     = "grc-week-5"
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "dev"
}
