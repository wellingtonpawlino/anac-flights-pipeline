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

module "athena" {
  source        = "./modules/athena"
  environment   = var.environment
  silver_bucket = module.s3_silver.bucket_name
  gold_bucket   = module.s3_gold.bucket_name
}
