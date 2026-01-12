################################################################################
# Bootstrap IAM Outputs
################################################################################

################################################################################
# GitHub OIDC Provider
################################################################################

output "oidc_provider_arn" {
  description = "ARN of GitHub OIDC provider"
  value       = module.iam.oidc_provider_arn
}

################################################################################
# GitHub Actions Role
################################################################################

output "github_actions_role_arn" {
  description = "ARN of GitHub Actions role"
  value       = module.iam.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "Name of GitHub Actions role"
  value       = module.iam.github_actions_role_name
}

################################################################################
# EKS Admin Role
################################################################################

output "eks_admin_role_arn" {
  description = "ARN of EKS admin role"
  value       = module.iam.eks_admin_role_arn
}

output "eks_admin_role_name" {
  description = "Name of EKS admin role"
  value       = module.iam.eks_admin_role_name
}

################################################################################
# EKS Cluster Role
################################################################################

output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_cluster_role_name" {
  description = "Name of EKS cluster role"
  value       = module.iam.eks_cluster_role_name
}

################################################################################
# VPC Flow Logs Role
################################################################################

output "flow_logs_role_arn" {
  description = "ARN of VPC flow logs role"
  value       = module.iam.flow_logs_role_arn
}

output "flow_logs_role_name" {
  description = "Name of VPC flow logs role"
  value       = module.iam.flow_logs_role_name
}

################################################################################
# RDS Monitoring Role
################################################################################

output "rds_monitoring_role_arn" {
  description = "ARN of RDS enhanced monitoring role"
  value       = module.iam.rds_monitoring_role_arn
}

output "rds_monitoring_role_name" {
  description = "Name of RDS enhanced monitoring role"
  value       = module.iam.rds_monitoring_role_name
}

################################################################################
# Fargate Pod Execution Role
################################################################################

output "fargate_pod_execution_role_arn" {
  description = "ARN of Fargate pod execution role"
  value       = module.iam.fargate_pod_execution_role_arn
}

output "fargate_pod_execution_role_name" {
  description = "Name of Fargate pod execution role"
  value       = module.iam.fargate_pod_execution_role_name
}
