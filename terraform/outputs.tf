output "s3_bronze_bucket" {
  value = module.s3_bronze.bucket_name
}

output "s3_silver_bucket" {
  value = module.s3_silver.bucket_name
}

output "s3_gold_bucket" {
  value = module.s3_gold.bucket_name
}

output "athena_workgroup" {
  value = module.athena.athena_workgroup
}

output "glue_silver_database" {
  value = module.athena.glue_silver_database
}

output "glue_gold_database" {
  value = module.athena.glue_gold_database
}
