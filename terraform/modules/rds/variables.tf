variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS master password"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed to connect to RDS"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "RDS instance type"
}
