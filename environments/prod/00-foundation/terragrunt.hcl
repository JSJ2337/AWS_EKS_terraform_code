################################################################################
# Foundation Layer
# KMS, IAM baseline
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/foundation"
}

inputs = {
  # KMS key for encryption
  enable_kms = true

  # IAM baseline roles
  create_eks_admin_role = true
}
