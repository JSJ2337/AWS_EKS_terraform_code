################################################################################
# EKS Add-ons Layer
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/addons"
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

# Fargate 사용 시 Fargate Profile이 먼저 생성되어야 CoreDNS가 스케줄링됨
dependency "fargate" {
  config_path  = "../40-fargate"
  skip_outputs = true

  mock_outputs = {
    system_fargate_profile_id      = "mock-system-profile"
    application_fargate_profile_id = "mock-app-profile"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  cluster_name      = dependency.eks_cluster.outputs.cluster_name
  oidc_provider_arn = dependency.eks_cluster.outputs.oidc_provider_arn
  oidc_provider_id  = dependency.eks_cluster.outputs.oidc_provider_id

  # Fargate 전용 설정
  use_fargate = true

  # Add-on toggles
  enable_ebs_csi            = local.common.locals.addons.enable_ebs_csi
  enable_pod_identity       = local.common.locals.addons.enable_pod_identity
  enable_aws_lb_controller  = local.common.locals.addons.enable_aws_lb_controller
  enable_cluster_autoscaler = local.common.locals.addons.enable_cluster_autoscaler

  # Add-on versions (null = latest compatible)
  vpc_cni_version      = null
  coredns_version      = null
  kube_proxy_version   = null
  ebs_csi_version      = null
  pod_identity_version = null

  # Common tags
  tags = local.common.locals.common_tags
}
