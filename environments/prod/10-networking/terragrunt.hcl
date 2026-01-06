################################################################################
# Networking Layer
# VPC, Subnets, NAT Gateway
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/networking"
}

dependency "foundation" {
  config_path = "../00-foundation"

  mock_outputs = {
    kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/mock-key"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  vpc_cidr           = local.common.locals.vpc_cidr
  availability_zones = local.common.locals.availability_zones

  public_subnet_cidrs   = local.common.locals.public_subnet_cidrs
  private_subnet_cidrs  = local.common.locals.private_subnet_cidrs
  database_subnet_cidrs = local.common.locals.database_subnet_cidrs
  pod_subnet_cidrs      = local.common.locals.pod_subnet_cidrs

  cluster_name       = local.common.locals.cluster_name
  enable_pod_subnets = local.common.locals.enable_pod_subnets
  single_nat_gateway = local.common.locals.single_nat_gateway
  enable_flow_logs   = local.common.locals.enable_flow_logs

  # Common tags
  tags = local.common.locals.common_tags
}
