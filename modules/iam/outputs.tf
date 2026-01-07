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
# EKS Node Role
################################################################################

output "eks_node_role_arn" {
  description = "ARN of EKS node role"
  value       = var.create_eks_node_role ? aws_iam_role.eks_nodes[0].arn : null
}

output "eks_node_role_name" {
  description = "Name of EKS node role"
  value       = var.create_eks_node_role ? aws_iam_role.eks_nodes[0].name : null
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

