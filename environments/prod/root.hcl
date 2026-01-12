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

# Common inputs for all modules
inputs = {
  region      = local.region
  project     = local.project
  environment = local.environment
}
