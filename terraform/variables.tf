variable "environment" {
  type        = string
  description = "Deployment environment (dev or prod)"
}

variable "aws_region" {
  type        = string
  default     = "sa-east-1"
  description = "AWS region"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS master password"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed to connect to RDS (your IP /32)"
}
