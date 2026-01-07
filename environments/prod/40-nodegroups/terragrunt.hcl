################################################################################
# Node Groups Layer
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/nodegroups"
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

dependency "eks_cluster" {
  config_path = "../30-eks-cluster"

  mock_outputs = {
    cluster_name                       = "eks-prod-cluster"
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "bW9jay1jZXJ0LWRhdGE="
    oidc_provider_arn                  = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_id                   = "oidc.eks.ap-northeast-2.amazonaws.com/id/MOCK"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  cluster_name  = dependency.eks_cluster.outputs.cluster_name
  node_role_arn = dependency.security.outputs.eks_nodes_role_arn
  subnet_ids    = dependency.networking.outputs.private_subnet_ids

  # System Node Group
  create_system_node_group = true
  system_instance_types    = local.common.locals.system_node_group.instance_types
  system_desired_size      = local.common.locals.system_node_group.desired_size
  system_min_size          = local.common.locals.system_node_group.min_size
  system_max_size          = local.common.locals.system_node_group.max_size

  # Application Node Group
  create_application_node_group = true
  application_instance_types    = local.common.locals.application_node_group.instance_types
  application_desired_size      = local.common.locals.application_node_group.desired_size
  application_min_size          = local.common.locals.application_node_group.min_size
  application_max_size          = local.common.locals.application_node_group.max_size

  # Spot Node Group (optional)
  create_spot_node_group = local.common.locals.spot_node_group.enabled
  spot_instance_types    = local.common.locals.spot_node_group.instance_types
  spot_desired_size      = local.common.locals.spot_node_group.desired_size
  spot_min_size          = local.common.locals.spot_node_group.min_size
  spot_max_size          = local.common.locals.spot_node_group.max_size

  # Common tags
  tags = local.common.locals.common_tags
}
