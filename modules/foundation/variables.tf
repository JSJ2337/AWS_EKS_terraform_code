################################################################################
# Variables
################################################################################

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_kms" {
  description = "Enable KMS key creation for EKS encryption"
  type        = bool
  default     = true
}

variable "create_eks_admin_role" {
  description = "Create IAM role for EKS administration"
  type        = bool
  default     = true
}
