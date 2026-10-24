resource "aws_glue_catalog_database" "silver" {
  name = "anac_silver_${var.environment}"
}

resource "aws_glue_catalog_database" "gold" {
  name = "anac_gold_${var.environment}"
}

resource "aws_iam_role" "glue_crawler" {
  name = "anac-glue-crawler-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3" {
  name = "anac-glue-s3-${var.environment}"
  role = aws_iam_role.glue_crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::${var.silver_bucket}",
        "arn:aws:s3:::${var.silver_bucket}/*"
      ]
    }]
  })
}

# Sem schedule = trigger manual apenas (sem custo adicional)
resource "aws_glue_crawler" "silver" {
  name          = "anac-silver-${var.environment}"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.silver.name

  s3_target {
    path = "s3://${var.silver_bucket}/dados_estatisticos/"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_athena_workgroup" "anac" {
  name = "anac-${var.environment}"

  configuration {
    result_configuration {
      output_location = "s3://${var.gold_bucket}/athena-results/"
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
