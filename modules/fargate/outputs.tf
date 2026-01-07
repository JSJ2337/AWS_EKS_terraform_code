################################################################################
# EKS Fargate Module - Outputs
################################################################################

output "system_fargate_profile_id" {
  description = "System Fargate profile ID"
  value       = try(aws_eks_fargate_profile.system[0].id, null)
}

output "system_fargate_profile_arn" {
  description = "System Fargate profile ARN"
  value       = try(aws_eks_fargate_profile.system[0].arn, null)
}

output "application_fargate_profile_id" {
  description = "Application Fargate profile ID"
  value       = try(aws_eks_fargate_profile.application[0].id, null)
}

output "application_fargate_profile_arn" {
  description = "Application Fargate profile ARN"
  value       = try(aws_eks_fargate_profile.application[0].arn, null)
}

output "monitoring_fargate_profile_id" {
  description = "Monitoring Fargate profile ID"
  value       = try(aws_eks_fargate_profile.monitoring[0].id, null)
}

output "monitoring_fargate_profile_arn" {
  description = "Monitoring Fargate profile ARN"
  value       = try(aws_eks_fargate_profile.monitoring[0].arn, null)
}
