################################################################################
# EKS Add-ons Layer
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
  source = "${get_terragrunt_dir()}/../../../modules/addons"
}

# Helm Provider 추가 (AWS Load Balancer Controller 설치용)
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

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

  # 로컬 Helm 설정 파일 사용하지 않음 (OCI repository 직접 사용)
  repository_config_path = "/dev/null"
  repository_cache       = "/tmp/helm-cache"
}
EOF
}

dependency "networking" {
  config_path = "../10-networking"

  mock_outputs = {
    vpc_id = "vpc-mock12345"
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

# Fargate 사용 시 Fargate Profile이 먼저 생성되어야 CoreDNS가 스케줄링됨
# outputs을 사용하지 않으므로 dependencies 블록으로 순서만 보장
dependencies {
  paths = ["../40-fargate"]
}

inputs = {
  cluster_name      = dependency.eks_cluster.outputs.cluster_name
  oidc_provider_arn = dependency.eks_cluster.outputs.oidc_provider_arn
  oidc_provider_id  = dependency.eks_cluster.outputs.oidc_provider_id

  # VPC ID for AWS Load Balancer Controller
  vpc_id = dependency.networking.outputs.vpc_id

  # Fargate 전용 설정
  use_fargate = true

  # Add-on toggles
  enable_ebs_csi           = local.common.locals.addons.enable_ebs_csi
  enable_pod_identity      = local.common.locals.addons.enable_pod_identity
  enable_aws_lb_controller = local.common.locals.addons.enable_aws_lb_controller

  # Add-on versions (null = latest compatible)
  vpc_cni_version      = null
  coredns_version      = null
  kube_proxy_version   = null
  ebs_csi_version      = null
  pod_identity_version = null

  # Common tags
  tags = local.common.locals.common_tags
}
