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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role ARNs (from IAM module)
################################################################################

variable "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN (from IAM module)"
  type        = string
  default     = null
}

variable "eks_cluster_role_name" {
  description = "EKS cluster IAM role name (from IAM module)"
  type        = string
  default     = null
}

variable "eks_node_role_arn" {
  description = "EKS node IAM role ARN (from IAM module)"
  type        = string
  default     = null
}

variable "eks_node_role_name" {
  description = "EKS node IAM role name (from IAM module)"
  type        = string
  default     = null
}

variable "create_iam_roles" {
  description = "Whether to create IAM roles in this module (set false when using IAM module)"
  type        = bool
  default     = true
}
