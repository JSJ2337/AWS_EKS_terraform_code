################################################################################
# Outputs
################################################################################

output "system_node_group_id" {
  description = "System node group ID"
  value       = var.create_system_node_group ? aws_eks_node_group.system[0].id : null
}

output "system_node_group_arn" {
  description = "System node group ARN"
  value       = var.create_system_node_group ? aws_eks_node_group.system[0].arn : null
}

output "application_node_group_id" {
  description = "Application node group ID"
  value       = var.create_application_node_group ? aws_eks_node_group.application[0].id : null
}

output "application_node_group_arn" {
  description = "Application node group ARN"
  value       = var.create_application_node_group ? aws_eks_node_group.application[0].arn : null
}

output "spot_node_group_id" {
  description = "Spot node group ID"
  value       = var.create_spot_node_group ? aws_eks_node_group.spot[0].id : null
}

output "spot_node_group_arn" {
  description = "Spot node group ARN"
  value       = var.create_spot_node_group ? aws_eks_node_group.spot[0].arn : null
}
