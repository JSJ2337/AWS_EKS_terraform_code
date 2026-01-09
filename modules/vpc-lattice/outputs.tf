################################################################################
# VPC Lattice Module - Outputs
################################################################################

################################################################################
# Service Network Outputs
################################################################################

output "service_network_id" {
  description = "Service Network ID"
  value       = aws_vpclattice_service_network.this.id
}

output "service_network_arn" {
  description = "Service Network ARN"
  value       = aws_vpclattice_service_network.this.arn
}

output "service_network_name" {
  description = "Service Network 이름"
  value       = aws_vpclattice_service_network.this.name
}

################################################################################
# VPC Association Outputs
################################################################################

output "vpc_association_id" {
  description = "VPC Association ID"
  value       = aws_vpclattice_service_network_vpc_association.this.id
}

output "vpc_association_status" {
  description = "VPC Association 상태"
  value       = aws_vpclattice_service_network_vpc_association.this.status
}

################################################################################
# Services Outputs
################################################################################

output "services" {
  description = "생성된 서비스 정보"
  value = {
    for k, v in aws_vpclattice_service.this : k => {
      id         = v.id
      arn        = v.arn
      name       = v.name
      dns_entry  = v.dns_entry
      status     = v.status
    }
  }
}

output "service_dns_entries" {
  description = "각 서비스의 DNS 엔트리 (서비스 호출 시 사용)"
  value = {
    for k, v in aws_vpclattice_service.this : k => try(v.dns_entry[0].domain_name, null)
  }
}

################################################################################
# Target Groups Outputs
################################################################################

output "target_groups" {
  description = "생성된 Target Group 정보"
  value = {
    for k, v in aws_vpclattice_target_group.this : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "target_group_ids" {
  description = "Target Group ID 맵 (서비스명 -> Target Group ID)"
  value = {
    for k, v in aws_vpclattice_target_group.this : k => v.id
  }
}

################################################################################
# Listeners Outputs
################################################################################

output "listeners" {
  description = "생성된 Listener 정보"
  value = {
    for k, v in aws_vpclattice_listener.this : k => {
      id          = v.id
      arn         = v.arn
      listener_id = v.listener_id
    }
  }
}

################################################################################
# Access Logs Outputs
################################################################################

output "access_logs_log_group_name" {
  description = "Access Logs CloudWatch Log Group 이름"
  value       = var.enable_access_logs ? aws_cloudwatch_log_group.access_logs[0].name : null
}

output "access_logs_log_group_arn" {
  description = "Access Logs CloudWatch Log Group ARN"
  value       = var.enable_access_logs ? aws_cloudwatch_log_group.access_logs[0].arn : null
}
