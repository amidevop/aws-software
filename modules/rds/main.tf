locals {
  create = var.create
}

resource "aws_db_subnet_group" "this" {
  count       = local.create ? 1 : 0
  name        = "${var.name_prefix}-db-subnets"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for RDS"
  tags        = var.tags
}

resource "aws_security_group" "rds" {
  count       = local.create ? 1 : 0
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description = "App to DB"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
}

resource "aws_db_parameter_group" "this" {
  count  = local.create ? 1 : 0
  name   = "${var.name_prefix}-db-params"
  family = var.family
  tags   = var.tags
}

resource "aws_db_instance" "this" {
  count                        = local.create ? 1 : 0
  identifier                   = "${var.name_prefix}-db"
  engine                       = var.engine
  engine_version               = var.engine_version
  instance_class               = var.instance_class
  allocated_storage            = var.allocated_storage
  max_allocated_storage        = var.max_allocated_storage
  storage_type                 = var.storage_type
  db_subnet_group_name         = aws_db_subnet_group.this[0].name
  vpc_security_group_ids       = [aws_security_group.rds[0].id]
  username                     = var.username
  password                     = var.password
  db_name                      = var.db_name
  multi_az                     = var.multi_az
  publicly_accessible          = var.publicly_accessible
  backup_retention_period      = var.backup_retention_period
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = true
  parameter_group_name         = aws_db_parameter_group.this[0].name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db"
  })
}


