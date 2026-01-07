################################################################################
# IAM Layer
# Centralized IAM roles and policies
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/iam"
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
  project      = local.common.locals.project
  environment  = local.common.locals.environment
  cluster_name = local.common.locals.cluster_name

  # EKS 기본 역할 생성
  create_eks_admin_role   = true
  create_eks_cluster_role = true
  create_eks_node_role    = true
  eks_admin_require_mfa   = true
  enable_ssm_for_nodes    = true

  # 서비스 역할 생성
  create_flow_logs_role      = true
  create_rds_monitoring_role = true

  # Common tags
  tags = local.common.locals.common_tags
}
