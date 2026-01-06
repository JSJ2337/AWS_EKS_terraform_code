################################################################################
# CloudWatch Module Variables
################################################################################

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for log group naming"
  type        = string
  default     = ""
}

################################################################################
# EKS Log Group Settings
################################################################################

variable "create_eks_log_group" {
  description = "Whether to create EKS cluster log group"
  type        = bool
  default     = false
}

variable "eks_log_retention_days" {
  description = "EKS cluster log retention in days"
  type        = number
  default     = 7
}

################################################################################
# ECS Log Group Settings
################################################################################

variable "create_ecs_log_group" {
  description = "Whether to create ECS cluster log group"
  type        = bool
  default     = false
}

variable "ecs_log_retention_days" {
  description = "ECS cluster log retention in days"
  type        = number
  default     = 7
}

################################################################################
# EC2 Log Group Settings (CloudWatch Agent)
################################################################################

variable "create_ec2_log_group" {
  description = "Whether to create EC2 log group for CloudWatch Agent"
  type        = bool
  default     = false
}

variable "ec2_log_retention_days" {
  description = "EC2 log retention in days"
  type        = number
  default     = 7
}

################################################################################
# Lambda Log Group Settings
################################################################################

variable "lambda_functions" {
  description = "Set of Lambda function names to create log groups for"
  type        = set(string)
  default     = []
}

variable "lambda_log_retention_days" {
  description = "Lambda log retention in days"
  type        = number
  default     = 14
}

################################################################################
# VPC Flow Logs Settings
################################################################################

variable "create_vpc_flow_log_group" {
  description = "Whether to create VPC flow logs log group"
  type        = bool
  default     = false
}

variable "vpc_flow_log_retention_days" {
  description = "VPC flow logs retention in days"
  type        = number
  default     = 14
}

################################################################################
# Application Log Groups (Custom)
################################################################################

variable "application_log_groups" {
  description = "Map of custom application log groups"
  type = map(object({
    retention_days = number
  }))
  default = {}
}

################################################################################
# Common Settings
################################################################################

variable "kms_key_arn" {
  description = "KMS key ARN for log group encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
