################################################################################
# Root Terragrunt Configuration
# Production Environment
################################################################################

# Import common variables
locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract commonly used variables
  region      = local.common.locals.region
  project     = local.common.locals.project
  environment = local.common.locals.environment

  # State backend configuration
  state_bucket         = "${local.project}-terraform-state-${local.environment}"
  state_dynamodb_table = "${local.project}-terraform-lock-${local.environment}"
}

# Remote state configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = local.state_dynamodb_table
  }
}

# Generate provider configuration
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
  }
}

provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Project     = "${local.project}"
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}

# Generate bootstrap IAM remote state data source
# Bootstrap IAM은 순수 Terraform이므로 terraform_remote_state로 참조
generate "bootstrap_iam" {
  path      = "bootstrap_iam.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "terraform_remote_state" "bootstrap_iam" {
  backend = "s3"
  config = {
    bucket = "${local.state_bucket}"
    key    = "bootstrap/01-iam/terraform.tfstate"
    region = "${local.region}"
  }
}

# Bootstrap IAM outputs를 로컬 변수로 노출
locals {
  bootstrap_iam = {
    flow_logs_role_arn             = try(data.terraform_remote_state.bootstrap_iam.outputs.flow_logs_role_arn, null)
    eks_cluster_role_arn           = try(data.terraform_remote_state.bootstrap_iam.outputs.eks_cluster_role_arn, null)
    eks_admin_role_arn             = try(data.terraform_remote_state.bootstrap_iam.outputs.eks_admin_role_arn, null)
    rds_monitoring_role_arn        = try(data.terraform_remote_state.bootstrap_iam.outputs.rds_monitoring_role_arn, null)
    fargate_pod_execution_role_arn = try(data.terraform_remote_state.bootstrap_iam.outputs.fargate_pod_execution_role_arn, null)
    github_actions_role_arn        = try(data.terraform_remote_state.bootstrap_iam.outputs.github_actions_role_arn, null)
  }
}
EOF
}

# Common inputs for all modules
inputs = {
  region      = local.region
  project     = local.project
  environment = local.environment
}
