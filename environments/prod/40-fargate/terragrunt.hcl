################################################################################
# Fargate Profiles Layer
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/fargate"
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
    fargate_pod_execution_role_arn = "arn:aws:iam::123456789012:role/mock-fargate-role"
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
  cluster_name           = dependency.eks_cluster.outputs.cluster_name
  pod_execution_role_arn = dependency.iam.outputs.fargate_pod_execution_role_arn
  subnet_ids             = dependency.networking.outputs.private_subnet_ids

  # System Fargate Profile (kube-system, argocd)
  create_system_profile = local.common.locals.fargate.system_profile.enabled

  # Application Fargate Profile (default, custom namespaces)
  create_application_profile = local.common.locals.fargate.application_profile.enabled
  application_namespaces     = local.common.locals.fargate.application_profile.namespaces

  # Monitoring Fargate Profile (prometheus, grafana, loki)
  create_monitoring_profile = local.common.locals.fargate.monitoring_profile.enabled

  # Common tags
  tags = local.common.locals.common_tags
}
