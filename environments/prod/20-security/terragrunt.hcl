################################################################################
# Security Layer
# Security Groups, IAM Roles
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/security"
}

dependency "networking" {
  config_path = "../10-networking"

  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  vpc_id       = dependency.networking.outputs.vpc_id
  cluster_name = local.common.locals.cluster_name

  # Common tags
  tags = local.common.locals.common_tags
}
