################################################################################
# IAM Module Variables
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
  description = "EKS cluster name"
  type        = string
}

################################################################################
# EKS Admin Role
################################################################################

variable "create_eks_admin_role" {
  description = "Whether to create EKS admin role"
  type        = bool
  default     = true
}

variable "eks_admin_require_mfa" {
  description = "Require MFA for EKS admin role assumption"
  type        = bool
  default     = true
}

################################################################################
# EKS Cluster Role
################################################################################

variable "create_eks_cluster_role" {
  description = "Whether to create EKS cluster role"
  type        = bool
  default     = true
}

################################################################################
# VPC Flow Logs Role
################################################################################

variable "create_flow_logs_role" {
  description = "Whether to create VPC flow logs role"
  type        = bool
  default     = true
}

################################################################################
# RDS Enhanced Monitoring Role
################################################################################

variable "create_rds_monitoring_role" {
  description = "Whether to create RDS enhanced monitoring role"
  type        = bool
  default     = true
}

################################################################################
# Fargate Pod Execution Role
################################################################################

variable "create_fargate_pod_execution_role" {
  description = "Whether to create Fargate pod execution role"
  type        = bool
  default     = true
}

################################################################################
# GitHub Actions Role
################################################################################

variable "create_github_actions_role" {
  description = "Whether to create GitHub Actions role"
  type        = bool
  default     = true
}

variable "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  type        = string
  default     = "github-actions-eks"
}

variable "github_repositories" {
  description = "List of GitHub repositories allowed to assume the role (format: owner/repo)"
  type        = list(string)
  default     = []
}

variable "github_actions_session_duration" {
  description = "Maximum session duration for GitHub Actions role (seconds)"
  type        = number
  default     = 3600
}

################################################################################
# Common
################################################################################

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
