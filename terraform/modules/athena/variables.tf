variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "silver_bucket" {
  type        = string
  description = "S3 bucket name for silver layer"
}

variable "gold_bucket" {
  type        = string
  description = "S3 bucket name for gold layer and Athena query results"
}
