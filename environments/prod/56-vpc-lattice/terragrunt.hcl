################################################################################
# VPC Lattice Layer
# AWS VPC Lattice 서비스 네트워크 구성
################################################################################

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
  expose         = true
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/vpc-lattice"
}

# VPC 의존성
dependency "networking" {
  config_path = "../10-networking"

  mock_outputs = {
    vpc_id = "vpc-mock12345"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

# Security Group 의존성 (선택적)
dependency "security" {
  config_path = "../20-security"

  mock_outputs = {
    lattice_security_group_id = "sg-mock12345"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

# EKS 클러스터 의존성 (서비스 연동 시 필요)
dependencies {
  paths = ["../30-eks-cluster", "../50-addons"]
}

inputs = {
  project     = local.common.locals.project
  environment = local.common.locals.environment

  # VPC 설정
  vpc_id = dependency.networking.outputs.vpc_id

  # 인증 설정
  auth_type = local.common.locals.vpc_lattice.auth_type

  # Security Groups (선택적)
  security_group_ids = local.common.locals.vpc_lattice.enable_security_group ? [
    dependency.security.outputs.lattice_security_group_id
  ] : []

  # 서비스 정의
  services = local.common.locals.vpc_lattice.services

  # Access Logs
  enable_access_logs         = local.common.locals.vpc_lattice.enable_access_logs
  access_logs_retention_days = local.common.locals.vpc_lattice.access_logs_retention_days

  # IAM Auth Policy (선택적)
  service_network_auth_policy = local.common.locals.vpc_lattice.service_network_auth_policy

  # Tags
  tags = local.common.locals.common_tags
}
