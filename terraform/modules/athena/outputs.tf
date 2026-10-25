output "athena_workgroup" {
  value = aws_athena_workgroup.anac.name
}

output "glue_silver_database" {
  value = aws_glue_catalog_database.silver.name
}

output "glue_gold_database" {
  value = aws_glue_catalog_database.gold.name
}

output "glue_crawler_name" {
  value = aws_glue_crawler.silver.name
}
