################################################################################
# Outputs
################################################################################

# Security Groups
output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.eks_cluster.id
}

output "eks_pods_security_group_id" {
  description = "EKS pods security group ID (Fargate)"
  value       = aws_security_group.eks_pods.id
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

output "lattice_security_group_id" {
  description = "VPC Lattice security group ID"
  value       = var.enable_vpc_lattice ? aws_security_group.vpc_lattice[0].id : null
}
