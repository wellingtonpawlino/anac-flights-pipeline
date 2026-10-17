output "s3_bronze_bucket" {
  value = module.s3_bronze.bucket_name
}

output "s3_silver_bucket" {
  value = module.s3_silver.bucket_name
}

output "s3_gold_bucket" {
  value = module.s3_gold.bucket_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
