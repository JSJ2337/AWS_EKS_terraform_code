################################################################################
# Security Layer
# Security Groups for EKS Fargate
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
    vpc_id               = "vpc-mock"
    private_subnet_ids   = ["subnet-mock-1", "subnet-mock-2"]
    public_subnet_ids    = ["subnet-mock-3", "subnet-mock-4"]
    database_subnet_ids  = ["subnet-mock-5", "subnet-mock-6"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  vpc_id       = dependency.networking.outputs.vpc_id
  cluster_name = local.common.locals.cluster_name

  # Common tags
  tags = local.common.locals.common_tags
}
