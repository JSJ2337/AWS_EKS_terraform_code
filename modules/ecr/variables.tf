################################################################################
# ECR Module Variables
################################################################################

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
}

################################################################################
# Repository Configuration
################################################################################

variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")
    scan_on_push         = optional(bool, true)
  }))
  default = {}
}

variable "kms_key_arn" {
  description = "ARN of KMS key for ECR encryption. If null, uses AES256"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Force delete repository even if it contains images"
  type        = bool
  default     = false
}

################################################################################
# Lifecycle Policy Configuration
################################################################################

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 1
}

variable "max_image_count" {
  description = "Maximum number of tagged images to keep"
  type        = number
  default     = 30
}

variable "cleanup_dev_images" {
  description = "Whether to cleanup dev/test images faster"
  type        = bool
  default     = true
}

variable "dev_image_retention_days" {
  description = "Number of days to retain dev/test images"
  type        = number
  default     = 14
}

################################################################################
# Repository Policy Configuration
################################################################################

variable "create_repository_policy" {
  description = "Whether to create repository policy for cross-account access"
  type        = bool
  default     = false
}

variable "pull_access_principal_arns" {
  description = "List of IAM ARNs allowed to pull images"
  type        = list(string)
  default     = []
}

variable "push_access_principal_arns" {
  description = "List of IAM ARNs allowed to push images"
  type        = list(string)
  default     = []
}

################################################################################
# Pull Through Cache Configuration
################################################################################

variable "enable_pull_through_cache" {
  description = "Enable pull through cache for public registries"
  type        = bool
  default     = false
}

variable "docker_hub_secret_arn" {
  description = "ARN of Secrets Manager secret for Docker Hub credentials"
  type        = string
  default     = null
}

################################################################################
# Enhanced Scanning Configuration
################################################################################

variable "enable_enhanced_scanning" {
  description = "Enable enhanced scanning with AWS Inspector"
  type        = bool
  default     = false
}

################################################################################
# Common Tags
################################################################################

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
