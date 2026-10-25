resource "aws_security_group" "rds" {
  name        = "anac-rds-${var.environment}"
  description = "Allow PostgreSQL access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_instance" "this" {
  identifier              = "anac-${var.environment}"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.instance_class
  allocated_storage       = 20
  db_name                 = "anac"
  username                = "anac"
  password                = var.db_password
  port                    = 5432
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = true
  storage_encrypted       = true
  skip_final_snapshot     = true
  backup_retention_period = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
