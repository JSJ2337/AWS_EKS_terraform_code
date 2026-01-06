################################################################################
# CloudWatch Module
# Log Groups for EKS, ECS, EC2, VPC and other AWS services
################################################################################

################################################################################
# EKS Cluster Log Group
################################################################################

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.create_eks_log_group ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.eks_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name    = "/aws/eks/${var.cluster_name}/cluster"
    Service = "eks"
  })
}

################################################################################
# ECS Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "ecs_cluster" {
  count = var.create_ecs_log_group ? 1 : 0

  name              = "/aws/ecs/${var.project}-${var.environment}"
  retention_in_days = var.ecs_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name    = "/aws/ecs/${var.project}-${var.environment}"
    Service = "ecs"
  })
}

################################################################################
# EC2 Log Groups (CloudWatch Agent)
################################################################################

resource "aws_cloudwatch_log_group" "ec2" {
  count = var.create_ec2_log_group ? 1 : 0

  name              = "/aws/ec2/${var.project}-${var.environment}"
  retention_in_days = var.ec2_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name    = "/aws/ec2/${var.project}-${var.environment}"
    Service = "ec2"
  })
}

################################################################################
# Lambda Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.lambda_functions

  name              = "/aws/lambda/${each.value}"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name    = "/aws/lambda/${each.value}"
    Service = "lambda"
  })
}

################################################################################
# VPC Flow Logs Log Group
################################################################################

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.create_vpc_flow_log_group ? 1 : 0

  name              = "/aws/vpc/${var.project}-${var.environment}/flow-logs"
  retention_in_days = var.vpc_flow_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name    = "/aws/vpc/${var.project}-${var.environment}/flow-logs"
    Service = "vpc"
  })
}

################################################################################
# Application Log Groups (Custom)
################################################################################

resource "aws_cloudwatch_log_group" "application" {
  for_each = var.application_log_groups

  name              = "/${var.project}/${var.environment}/${each.key}"
  retention_in_days = each.value.retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name    = "/${var.project}/${var.environment}/${each.key}"
    Service = "application"
  })
}
