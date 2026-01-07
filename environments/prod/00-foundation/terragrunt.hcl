################################################################################
# Foundation Layer
# KMS, IAM baseline
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/foundation"
}

inputs = {
  # KMS key for encryption
  enable_kms = true

  # IAM baseline roles (moved to 04-iam layer)
  create_eks_admin_role = false

  # Common tags
  tags = local.common.locals.common_tags
}
