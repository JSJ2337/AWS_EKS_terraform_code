################################################################################
# Outputs
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "pod_subnet_ids" {
  description = "List of pod subnet IDs"
  value       = var.enable_pod_subnets ? aws_subnet.pod[*].id : []
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

################################################################################
# VPC Endpoint Outputs
################################################################################

output "vpc_endpoint_s3_id" {
  description = "S3 VPC Endpoint ID"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_ecr_api_id" {
  description = "ECR API VPC Endpoint ID"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ECR DKR VPC Endpoint ID"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "vpc_endpoint_logs_id" {
  description = "CloudWatch Logs VPC Endpoint ID"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.logs[0].id : null
}

output "vpc_endpoint_sts_id" {
  description = "STS VPC Endpoint ID"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.sts[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "Security Group ID for VPC Endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}
