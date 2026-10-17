provider "aws" {
  region = var.aws_region
}

module "s3_bronze" {
  source      = "./modules/s3"
  bucket_name = "anac-raw-${var.environment}"
  environment = var.environment
}

module "s3_silver" {
  source      = "./modules/s3"
  bucket_name = "anac-silver-${var.environment}"
  environment = var.environment
}

module "s3_gold" {
  source      = "./modules/s3"
  bucket_name = "anac-gold-${var.environment}"
  environment = var.environment
}

module "rds" {
  source       = "./modules/rds"
  environment  = var.environment
  db_password  = var.db_password
  allowed_cidr = var.allowed_cidr
}
