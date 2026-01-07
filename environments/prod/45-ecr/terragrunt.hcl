################################################################################
# ECR Layer
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/ecr"
}

dependency "foundation" {
  config_path = "../00-foundation"

  mock_outputs = {
    kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/mock-key"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "state", "providers"]
}

inputs = {
  project     = local.common.locals.project
  environment = local.common.locals.environment

  # ECR 리포지토리 목록
  repositories = local.common.locals.ecr.repositories

  # KMS 암호화 (foundation의 KMS 키 사용)
  kms_key_arn = local.common.locals.ecr.use_kms_encryption ? dependency.foundation.outputs.kms_key_arn : null

  # 라이프사이클 정책
  untagged_image_retention_days = local.common.locals.ecr.lifecycle.untagged_retention_days
  max_image_count               = local.common.locals.ecr.lifecycle.max_image_count
  cleanup_dev_images            = local.common.locals.ecr.lifecycle.cleanup_dev_images
  dev_image_retention_days      = local.common.locals.ecr.lifecycle.dev_retention_days

  # Force delete (테스트 환경용)
  force_delete = local.common.locals.ecr.force_delete

  # Pull Through Cache
  enable_pull_through_cache = local.common.locals.ecr.enable_pull_through_cache

  # Enhanced Scanning
  enable_enhanced_scanning = local.common.locals.ecr.enable_enhanced_scanning

  # Common tags
  tags = local.common.locals.common_tags
}
