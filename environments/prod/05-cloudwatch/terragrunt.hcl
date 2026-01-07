################################################################################
# 05-cloudwatch Layer
# CloudWatch Log Groups (EKS 클러스터 생성 전에 먼저 생성되어야 함)
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "../../../modules/cloudwatch"
}

dependency "foundation" {
  config_path = "../00-foundation"

  mock_outputs = {
    kms_key_arn        = "arn:aws:kms:ap-northeast-2:123456789012:key/mock-key-id"
    kms_key_id         = "mock-key-id"
    eks_admin_role_arn = "arn:aws:iam::123456789012:role/mock-eks-admin"
    account_id         = "123456789012"
    region             = "ap-northeast-2"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  project      = local.common.project
  environment  = local.common.environment
  cluster_name = local.common.cluster_name

  # EKS Log Group 설정
  create_eks_log_group   = length(local.common.enabled_cluster_log_types) > 0
  eks_log_retention_days = local.common.cluster_log_retention_days

  # VPC Flow Logs Log Group 설정
  create_vpc_flow_log_group   = local.common.enable_flow_logs
  vpc_flow_log_retention_days = 14

  # KMS 암호화 (optional)
  kms_key_arn = try(dependency.foundation.outputs.kms_key_arn, null)

  tags = local.common.common_tags
}
