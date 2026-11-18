resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "${local.name}-db-subnets" }
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${local.name}-pg${var.db_engine_version}"
  family = "postgres${var.db_engine_version}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "main" {
  identifier                 = "${local.name}-postgres"
  engine                     = "postgres"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  parameter_group_name       = aws_db_parameter_group.postgres.name
  auto_minor_version_upgrade = true

  storage_type          = "gp3"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_encrypted     = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true # password lives in Secrets Manager

  db_subnet_group_name         = aws_db_subnet_group.main.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  availability_zone            = local.azs[0]
  publicly_accessible          = false
  multi_az                     = false
  port                         = 5432
  ca_cert_identifier           = "rds-ca-rsa2048-g1"
  backup_retention_period      = local.is_prod ? 7 : 1
  backup_window                = "00:00-01:00"
  maintenance_window           = "sun:01:30-sun:02:30"
  copy_tags_to_snapshot        = true
  deletion_protection          = local.is_prod
  skip_final_snapshot          = !local.is_prod
  final_snapshot_identifier    = local.is_prod ? "${local.name}-postgres-final" : null
  delete_automated_backups     = !local.is_prod
  apply_immediately            = !local.is_prod
  performance_insights_enabled = false
  monitoring_interval          = 0
  tags                         = { Name = "${local.name}-postgres" }
}

