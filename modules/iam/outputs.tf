################################################################################
# IAM Module Outputs
################################################################################

################################################################################
# EKS Admin Role
################################################################################

output "eks_admin_role_arn" {
  description = "ARN of EKS admin role"
  value       = var.create_eks_admin_role ? aws_iam_role.eks_admin[0].arn : null
}

output "eks_admin_role_name" {
  description = "Name of EKS admin role"
  value       = var.create_eks_admin_role ? aws_iam_role.eks_admin[0].name : null
}

################################################################################
# EKS Cluster Role
################################################################################

output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  value       = var.create_eks_cluster_role ? aws_iam_role.eks_cluster[0].arn : null
}

output "eks_cluster_role_name" {
  description = "Name of EKS cluster role"
  value       = var.create_eks_cluster_role ? aws_iam_role.eks_cluster[0].name : null
}

################################################################################
# VPC Flow Logs Role
################################################################################

output "flow_logs_role_arn" {
  description = "ARN of VPC flow logs role"
  value       = var.create_flow_logs_role ? aws_iam_role.flow_logs[0].arn : null
}

output "flow_logs_role_name" {
  description = "Name of VPC flow logs role"
  value       = var.create_flow_logs_role ? aws_iam_role.flow_logs[0].name : null
}

################################################################################
# RDS Monitoring Role
################################################################################

output "rds_monitoring_role_arn" {
  description = "ARN of RDS enhanced monitoring role"
  value       = var.create_rds_monitoring_role ? aws_iam_role.rds_monitoring[0].arn : null
}

output "rds_monitoring_role_name" {
  description = "Name of RDS enhanced monitoring role"
  value       = var.create_rds_monitoring_role ? aws_iam_role.rds_monitoring[0].name : null
}

################################################################################
# Fargate Pod Execution Role
################################################################################

output "fargate_pod_execution_role_arn" {
  description = "ARN of Fargate pod execution role"
  value       = var.create_fargate_pod_execution_role ? aws_iam_role.fargate_pod_execution[0].arn : null
}

output "fargate_pod_execution_role_name" {
  description = "Name of Fargate pod execution role"
  value       = var.create_fargate_pod_execution_role ? aws_iam_role.fargate_pod_execution[0].name : null
}

################################################################################
# GitHub Actions Role
################################################################################

output "github_actions_role_arn" {
  description = "ARN of GitHub Actions role"
  value       = var.create_github_actions_role ? aws_iam_role.github_actions[0].arn : null
}

output "github_actions_role_name" {
  description = "Name of GitHub Actions role"
  value       = var.create_github_actions_role ? aws_iam_role.github_actions[0].name : null
}
