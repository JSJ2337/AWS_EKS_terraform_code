################################################################################
# IAM Layer
# Centralized IAM roles and policies
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/iam"
}

# Import existing GitHub Actions IAM resources
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Import GitHub Actions Role
import {
  to = aws_iam_role.github_actions[0]
  id = "${local.common.locals.github_actions.role_name}"
}

# Import attached managed policies
import {
  to = aws_iam_role_policy_attachment.github_actions_ec2[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_iam[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/IAMFullAccess"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_eks_cluster[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_vpc[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_dynamodb[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_eks_worker[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_s3[0]
  id = "${local.common.locals.github_actions.role_name}/arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Import inline policy (기존 정책명: git_hub_action_custom_role)
import {
  to = aws_iam_role_policy.github_actions_custom[0]
  id = "${local.common.locals.github_actions.role_name}:git_hub_action_custom_role"
}
EOF
}

dependency "foundation" {
  config_path = "../00-foundation"

  mock_outputs = {
    kms_key_arn        = "arn:aws:kms:ap-northeast-2:123456789012:key/mock-key"
    kms_key_id         = "mock-key-id"
    eks_admin_role_arn = "arn:aws:iam::123456789012:role/mock-eks-admin"
    account_id         = "123456789012"
    region             = "ap-northeast-2"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  project      = local.common.locals.project
  environment  = local.common.locals.environment
  cluster_name = local.common.locals.cluster_name

  # EKS 역할 생성
  create_eks_admin_role   = true
  create_eks_cluster_role = true
  eks_admin_require_mfa   = true

  # Fargate Pod Execution 역할 생성
  create_fargate_pod_execution_role = true

  # 서비스 역할 생성
  create_flow_logs_role      = true
  create_rds_monitoring_role = true

  # GitHub Actions 역할 생성
  create_github_actions_role      = local.common.locals.github_actions.create_role
  github_actions_role_name        = local.common.locals.github_actions.role_name
  github_repositories             = local.common.locals.github_actions.repositories
  github_actions_session_duration = local.common.locals.github_actions.session_duration

  # Common tags
  tags = local.common.locals.common_tags
}
