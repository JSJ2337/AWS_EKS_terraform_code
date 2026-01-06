################################################################################
# Aurora MySQL Cluster
################################################################################

# Random password if not provided
resource "random_password" "master" {
  count   = var.master_password == null ? 1 : 0
  length  = 16
  special = false
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "aurora" {
  name                    = "${var.cluster_identifier}-credentials"
  description             = "Aurora MySQL credentials for ${var.cluster_identifier}"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "aurora" {
  secret_id = aws_secretsmanager_secret.aurora.id
  secret_string = jsonencode({
    username = var.master_username
    password = local.master_password
    host     = aws_rds_cluster.this.endpoint
    port     = var.port
    database = var.database_name
  })
}

locals {
  master_password = var.master_password != null ? var.master_password : random_password.master[0].result
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "aurora" {
  name        = "${var.cluster_identifier}-sg"
  description = "Security group for Aurora MySQL cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-sg"
  })
}

resource "aws_security_group_rule" "aurora_ingress_sg" {
  count                    = length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.aurora.id
  description              = "Allow MySQL from security group"
}

resource "aws_security_group_rule" "aurora_ingress_cidr" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.aurora.id
  description       = "Allow MySQL from CIDR blocks"
}

resource "aws_security_group_rule" "aurora_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aurora.id
  description       = "Allow all outbound"
}

################################################################################
# Subnet Group
################################################################################

resource "aws_db_subnet_group" "aurora" {
  name        = "${var.cluster_identifier}-subnet-group"
  description = "Aurora MySQL subnet group"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-subnet-group"
  })
}

################################################################################
# Parameter Groups
################################################################################

resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${var.cluster_identifier}-cluster-pg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL cluster parameter group"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  parameter {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "long_query_time"
    value = "1"
  }

  tags = var.tags
}

resource "aws_db_parameter_group" "aurora" {
  name        = "${var.cluster_identifier}-instance-pg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL instance parameter group"

  parameter {
    name  = "max_connections"
    value = "1000"
  }

  tags = var.tags
}

################################################################################
# IAM Role for Enhanced Monitoring
################################################################################

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.cluster_identifier}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# Aurora Cluster
################################################################################

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier
  engine             = "aurora-mysql"
  engine_version     = var.engine_version
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = local.master_password

  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  port = var.port

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final-snapshot"
  deletion_protection       = var.deletion_protection

  apply_immediately = var.apply_immediately

  tags = merge(var.tags, {
    Name = var.cluster_identifier
  })

  lifecycle {
    ignore_changes = [master_password]
  }
}

################################################################################
# Aurora Instances
################################################################################

resource "aws_rds_cluster_instance" "this" {
  for_each = var.instances

  identifier         = "${var.cluster_identifier}-${each.key}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  instance_class     = coalesce(each.value.instance_class, var.instance_class)

  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  db_parameter_group_name = aws_db_parameter_group.aurora.name

  promotion_tier = each.value.promotion_tier

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-${each.key}"
  })
}
