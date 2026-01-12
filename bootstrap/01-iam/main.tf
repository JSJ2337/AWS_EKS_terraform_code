################################################################################
# Bootstrap IAM
# modules/iam을 참조하여 IAM 리소스 생성
#
# 주의: bootstrap 리소스는 로컬에서 수동 실행합니다.
# - 초기 1회 실행 후 State를 S3로 마이그레이션
# - 이후 변경 시에도 로컬에서 실행 (GitHub Actions 실행 전제조건)
################################################################################

terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.82"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Layer       = "bootstrap"
    }
  }
}

################################################################################
# IAM Module
################################################################################

module "iam" {
  source = "../../modules/iam"

  project      = var.project
  environment  = var.environment
  cluster_name = var.cluster_name

  # GitHub Actions Role
  create_github_actions_role      = true
  github_actions_role_name        = var.github_actions_role_name
  github_repositories             = var.github_repositories
  github_actions_session_duration = var.github_actions_session_duration

  # EKS Roles
  create_eks_admin_role   = var.create_eks_admin_role
  eks_admin_require_mfa   = var.eks_admin_require_mfa
  create_eks_cluster_role = var.create_eks_cluster_role

  # Service Roles
  create_flow_logs_role             = var.create_flow_logs_role
  create_rds_monitoring_role        = var.create_rds_monitoring_role
  create_fargate_pod_execution_role = var.create_fargate_pod_execution_role

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Layer       = "bootstrap"
  }
}
