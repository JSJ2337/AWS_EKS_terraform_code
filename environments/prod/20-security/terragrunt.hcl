################################################################################
# Security Layer
# Security Groups (IAM Roles from 04-iam module)
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

dependency "iam" {
  config_path = "../04-iam"

  mock_outputs = {
    eks_admin_role_arn      = "arn:aws:iam::123456789012:role/mock-eks-admin"
    eks_cluster_role_arn    = "arn:aws:iam::123456789012:role/mock-eks-cluster"
    eks_cluster_role_name   = "mock-eks-cluster"
    flow_logs_role_arn      = "arn:aws:iam::123456789012:role/mock-flow-logs"
    rds_monitoring_role_arn = "arn:aws:iam::123456789012:role/mock-rds-monitoring"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  vpc_id       = dependency.networking.outputs.vpc_id
  cluster_name = local.common.locals.cluster_name

  # IAM roles from 04-iam module
  create_iam_roles      = false
  eks_cluster_role_arn  = dependency.iam.outputs.eks_cluster_role_arn
  eks_cluster_role_name = dependency.iam.outputs.eks_cluster_role_name

  # EC2 Node Groups vs Fargate
  use_ec2_nodegroups = local.common.locals.use_ec2_nodegroups

  # Common tags
  tags = local.common.locals.common_tags
}
