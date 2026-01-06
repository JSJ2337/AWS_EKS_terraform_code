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
    kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/mock-key"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "networking" {
  config_path = "../10-networking"

  mock_outputs = {
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security" {
  config_path = "../20-security"

  mock_outputs = {
    eks_cluster_security_group_id = "sg-mock"
    eks_cluster_role_arn          = "arn:aws:iam::123456789012:role/mock-role"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
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
