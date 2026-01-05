################################################################################
# Variables
################################################################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "eks-prod"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}
