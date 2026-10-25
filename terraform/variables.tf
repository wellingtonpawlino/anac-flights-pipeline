variable "environment" {
  type        = string
  description = "Deployment environment (dev or prod)"
}

variable "aws_region" {
  type        = string
  default     = "sa-east-1"
  description = "AWS region"
}

