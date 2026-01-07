################################################################################
# EKS Cluster Layer
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/eks-cluster"
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

# CloudWatch Log Group이 EKS보다 먼저 생성되어야 함
dependency "cloudwatch" {
  config_path = "../05-cloudwatch"

  mock_outputs = {
    eks_log_group_name     = "/aws/eks/mock-cluster/cluster"
    eks_log_group_arn      = "arn:aws:logs:ap-northeast-2:123456789012:log-group:/aws/eks/mock-cluster/cluster"
    vpc_flow_log_group_arn = "arn:aws:logs:ap-northeast-2:123456789012:log-group:vpc-flow-logs"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  cluster_name              = local.common.locals.cluster_name
  cluster_version           = local.common.locals.cluster_version
  cluster_role_arn          = dependency.security.outputs.eks_cluster_role_arn
  subnet_ids                = dependency.networking.outputs.private_subnet_ids
  cluster_security_group_id = dependency.security.outputs.eks_cluster_security_group_id
  kms_key_arn               = dependency.foundation.outputs.kms_key_arn

  endpoint_private_access = local.common.locals.endpoint_private_access
  endpoint_public_access  = local.common.locals.endpoint_public_access
  public_access_cidrs     = local.common.locals.public_access_cidrs

  enabled_cluster_log_types  = local.common.locals.enabled_cluster_log_types
  cluster_log_retention_days = local.common.locals.cluster_log_retention_days

  # Common tags
  tags = local.common.locals.common_tags
}
