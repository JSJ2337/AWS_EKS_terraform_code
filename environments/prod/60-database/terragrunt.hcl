################################################################################
# Aurora MySQL Database Layer
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/aurora-mysql"
}

dependency "networking" {
  config_path = "../10-networking"

  mock_outputs = {
    vpc_id               = "vpc-mock"
    private_subnet_ids   = ["subnet-mock-1", "subnet-mock-2"]
    public_subnet_ids    = ["subnet-mock-3", "subnet-mock-4"]
    database_subnet_ids  = ["subnet-mock-5", "subnet-mock-6"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

dependency "security" {
  config_path = "../20-security"

  mock_outputs = {
    eks_cluster_security_group_id = "sg-mock"
    eks_cluster_role_arn          = "arn:aws:iam::123456789012:role/mock-role"
    eks_nodes_role_arn            = "arn:aws:iam::123456789012:role/mock-nodes-role"
    eks_nodes_security_group_id   = "sg-mock-nodes"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

dependency "foundation" {
  config_path = "../00-foundation"

  mock_outputs = {
    kms_key_arn        = "arn:aws:kms:ap-northeast-2:123456789012:key/mock-key"
    kms_key_id         = "mock-key-id"
    eks_admin_role_arn = "arn:aws:iam::123456789012:role/mock-eks-admin"
    account_id         = "123456789012"
    region             = "ap-northeast-2"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  cluster_identifier = local.common.locals.aurora.cluster_identifier
  engine_version     = local.common.locals.aurora.engine_version
  database_name      = local.common.locals.aurora.database_name
  master_username    = local.common.locals.aurora.master_username
  instance_class     = local.common.locals.aurora.instance_class

  instances = local.common.locals.aurora.instances

  vpc_id     = dependency.networking.outputs.vpc_id
  subnet_ids = dependency.networking.outputs.database_subnet_ids

  # EKS 노드에서 접근 허용
  allowed_security_group_ids = [dependency.security.outputs.eks_nodes_security_group_id]
  allowed_cidr_blocks        = dependency.networking.outputs.private_subnet_cidrs

  # Encryption
  kms_key_id = dependency.foundation.outputs.kms_key_arn

  # Backup & Maintenance
  backup_retention_period      = local.common.locals.aurora.backup_retention_period
  preferred_backup_window      = local.common.locals.aurora.preferred_backup_window
  preferred_maintenance_window = local.common.locals.aurora.preferred_maintenance_window

  # For testing - disable deletion protection
  skip_final_snapshot = local.common.locals.aurora.skip_final_snapshot
  deletion_protection = local.common.locals.aurora.deletion_protection
  apply_immediately   = local.common.locals.aurora.apply_immediately

  # Monitoring
  monitoring_interval                   = local.common.locals.aurora.monitoring_interval
  performance_insights_enabled          = local.common.locals.aurora.performance_insights_enabled
  performance_insights_retention_period = local.common.locals.aurora.performance_insights_retention_period

  # Logs
  enabled_cloudwatch_logs_exports = local.common.locals.aurora.enabled_cloudwatch_logs_exports

  tags = local.common.locals.common_tags
}
