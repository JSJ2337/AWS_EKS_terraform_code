################################################################################
# Outputs
################################################################################

# Security Groups
output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID"
  value       = aws_security_group.eks_nodes.id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.elasticache.id
}

# IAM Roles
locals {
  # Use external role ARN/name if provided, otherwise use internally created role
  eks_cluster_role_arn  = var.create_iam_roles ? aws_iam_role.eks_cluster[0].arn : var.eks_cluster_role_arn
  eks_cluster_role_name = var.create_iam_roles ? aws_iam_role.eks_cluster[0].name : var.eks_cluster_role_name
  eks_nodes_role_arn    = var.create_iam_roles ? aws_iam_role.eks_nodes[0].arn : var.eks_node_role_arn
  eks_nodes_role_name   = var.create_iam_roles ? aws_iam_role.eks_nodes[0].name : var.eks_node_role_name
}

output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = local.eks_cluster_role_arn
}

output "eks_cluster_role_name" {
  description = "EKS cluster IAM role name"
  value       = local.eks_cluster_role_name
}

output "eks_nodes_role_arn" {
  description = "EKS nodes IAM role ARN"
  value       = local.eks_nodes_role_arn
}

output "eks_nodes_role_name" {
  description = "EKS nodes IAM role name"
  value       = local.eks_nodes_role_name
}

output "eks_nodes_instance_profile_arn" {
  description = "EKS nodes instance profile ARN"
  value       = aws_iam_instance_profile.eks_nodes.arn
}

output "eks_nodes_instance_profile_name" {
  description = "EKS nodes instance profile name"
  value       = aws_iam_instance_profile.eks_nodes.name
}
