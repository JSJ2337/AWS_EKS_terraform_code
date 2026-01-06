################################################################################
# CloudWatch Module Outputs
################################################################################

################################################################################
# EKS Log Group
################################################################################

output "eks_log_group_name" {
  description = "EKS cluster log group name"
  value       = try(aws_cloudwatch_log_group.eks_cluster[0].name, null)
}

output "eks_log_group_arn" {
  description = "EKS cluster log group ARN"
  value       = try(aws_cloudwatch_log_group.eks_cluster[0].arn, null)
}

################################################################################
# ECS Log Group
################################################################################

output "ecs_log_group_name" {
  description = "ECS cluster log group name"
  value       = try(aws_cloudwatch_log_group.ecs_cluster[0].name, null)
}

output "ecs_log_group_arn" {
  description = "ECS cluster log group ARN"
  value       = try(aws_cloudwatch_log_group.ecs_cluster[0].arn, null)
}

################################################################################
# EC2 Log Group
################################################################################

output "ec2_log_group_name" {
  description = "EC2 log group name"
  value       = try(aws_cloudwatch_log_group.ec2[0].name, null)
}

output "ec2_log_group_arn" {
  description = "EC2 log group ARN"
  value       = try(aws_cloudwatch_log_group.ec2[0].arn, null)
}

################################################################################
# Lambda Log Groups
################################################################################

output "lambda_log_group_names" {
  description = "Map of Lambda function names to log group names"
  value       = { for k, v in aws_cloudwatch_log_group.lambda : k => v.name }
}

output "lambda_log_group_arns" {
  description = "Map of Lambda function names to log group ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.lambda : k => v.arn }
}

################################################################################
# VPC Flow Logs
################################################################################

output "vpc_flow_log_group_name" {
  description = "VPC flow logs log group name"
  value       = try(aws_cloudwatch_log_group.vpc_flow_logs[0].name, null)
}

output "vpc_flow_log_group_arn" {
  description = "VPC flow logs log group ARN"
  value       = try(aws_cloudwatch_log_group.vpc_flow_logs[0].arn, null)
}

################################################################################
# Application Log Groups
################################################################################

output "application_log_group_names" {
  description = "Map of application log group keys to names"
  value       = { for k, v in aws_cloudwatch_log_group.application : k => v.name }
}

output "application_log_group_arns" {
  description = "Map of application log group keys to ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.application : k => v.arn }
}
