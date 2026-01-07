################################################################################
# ArgoCD Layer
# Terraform Helm Provider를 사용하여 ArgoCD 설치
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
  source = "${get_terragrunt_dir()}/../../../modules/argocd"
}

# EKS 클러스터 의존성
dependency "eks_cluster" {
  config_path = "../30-eks-cluster"

  mock_outputs = {
    cluster_name                       = "mock-cluster"
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "bW9jay1jZXJ0LWRhdGE="
    oidc_provider_arn                  = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_id                   = "oidc.eks.ap-northeast-2.amazonaws.com/id/MOCK"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

# Fargate Profile 의존성 (Fargate가 있어야 ArgoCD 배포 가능)
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

# root.hcl의 provider.tf를 오버라이드하여 AWS + Helm + Kubernetes 통합
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.82"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = "${local.common.locals.region}"

  default_tags {
    tags = {
      Project     = "${local.common.locals.project}"
      Environment = "${local.common.locals.environment}"
      ManagedBy   = "terragrunt"
    }
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${dependency.eks_cluster.outputs.cluster_name}"
}

provider "kubernetes" {
  host                   = "${dependency.eks_cluster.outputs.cluster_endpoint}"
  cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.cluster_certificate_authority_data}")
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = "${dependency.eks_cluster.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.cluster_certificate_authority_data}")
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
EOF
}

inputs = {
  # General
  release_name     = local.common.locals.argocd.release_name
  namespace        = local.common.locals.argocd.namespace
  create_namespace = true
  chart_version    = local.common.locals.argocd.chart_version

  # Replicas
  server_replicas      = local.common.locals.argocd.server_replicas
  controller_replicas  = local.common.locals.argocd.controller_replicas
  repo_server_replicas = local.common.locals.argocd.repo_server_replicas

  # Features
  applicationset_enabled = local.common.locals.argocd.applicationset_enabled
  notifications_enabled  = local.common.locals.argocd.notifications_enabled
  dex_enabled            = local.common.locals.argocd.dex_enabled

  # Server
  server_service_type = local.common.locals.argocd.server_service_type
  server_insecure     = local.common.locals.argocd.server_insecure

  # Ingress (optional)
  ingress_enabled = local.common.locals.argocd.ingress_enabled

  # Tags
  tags = local.common.locals.common_tags
}
