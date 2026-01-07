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
# EKS Node Role
################################################################################

variable "create_eks_node_role" {
  description = "Whether to create EKS node role"
  type        = bool
  default     = true
}

variable "enable_ssm_for_nodes" {
  description = "Enable SSM access for EKS nodes"
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
# Common
################################################################################

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
