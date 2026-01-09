################################################################################
# VPC Lattice Module
# AWS VPC Lattice 서비스 네트워크 및 서비스 구성
################################################################################

################################################################################
# Service Network
# VPC Lattice의 최상위 리소스 - 서비스들의 논리적 그룹
################################################################################

resource "aws_vpclattice_service_network" "this" {
  name      = "${var.project}-${var.environment}-service-network"
  auth_type = var.auth_type

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-service-network"
  })
}

################################################################################
# Service Network - VPC Association
# VPC를 Service Network에 연결
################################################################################

resource "aws_vpclattice_service_network_vpc_association" "this" {
  vpc_identifier             = var.vpc_id
  service_network_identifier = aws_vpclattice_service_network.this.id
  security_group_ids         = var.security_group_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-vpc-association"
  })
}

################################################################################
# IAM Auth Policy for Service Network (Optional)
# 서비스 네트워크에 대한 IAM 인증 정책
################################################################################

resource "aws_vpclattice_auth_policy" "service_network" {
  count = var.auth_type == "AWS_IAM" && var.service_network_auth_policy != null ? 1 : 0

  resource_identifier = aws_vpclattice_service_network.this.arn
  policy              = var.service_network_auth_policy
}

################################################################################
# VPC Lattice Services
# 개별 서비스 정의
################################################################################

resource "aws_vpclattice_service" "this" {
  for_each = var.services

  name      = "${var.project}-${each.key}-service"
  auth_type = each.value.auth_type != null ? each.value.auth_type : var.auth_type

  tags = merge(var.tags, {
    Name        = "${var.project}-${each.key}-service"
    ServiceName = each.key
  })
}

################################################################################
# Service - Service Network Association
# 서비스를 Service Network에 연결
################################################################################

resource "aws_vpclattice_service_network_service_association" "this" {
  for_each = var.services

  service_identifier         = aws_vpclattice_service.this[each.key].id
  service_network_identifier = aws_vpclattice_service_network.this.id

  tags = merge(var.tags, {
    Name = "${var.project}-${each.key}-association"
  })
}

################################################################################
# Target Groups
# 각 서비스의 Target Group 정의
################################################################################

resource "aws_vpclattice_target_group" "this" {
  for_each = var.services

  name = "${var.project}-${each.key}-tg"
  type = each.value.target_type

  config {
    vpc_identifier = var.vpc_id
    port           = each.value.port
    protocol       = each.value.protocol

    health_check {
      enabled                       = true
      health_check_interval_seconds = each.value.health_check_interval
      health_check_timeout_seconds  = each.value.health_check_timeout
      healthy_threshold_count       = each.value.healthy_threshold
      unhealthy_threshold_count     = each.value.unhealthy_threshold
      path                          = each.value.health_check_path
      protocol                      = each.value.health_check_protocol
      matcher {
        value = each.value.health_check_matcher
      }
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${each.key}-tg"
    ServiceName = each.key
  })
}

################################################################################
# Listeners
# 각 서비스의 Listener 정의
################################################################################

resource "aws_vpclattice_listener" "this" {
  for_each = var.services

  name               = "${var.project}-${each.key}-listener"
  protocol           = each.value.listener_protocol
  port               = each.value.listener_port != null ? each.value.listener_port : each.value.port
  service_identifier = aws_vpclattice_service.this[each.key].id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.this[each.key].id
        weight                  = 100
      }
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${each.key}-listener"
    ServiceName = each.key
  })
}

################################################################################
# Listener Rules (Optional - for advanced routing)
# 고급 라우팅을 위한 Listener Rules
################################################################################

resource "aws_vpclattice_listener_rule" "this" {
  for_each = { for k, v in var.services : k => v if v.routing_rules != null }

  name                = "${var.project}-${each.key}-rule"
  listener_identifier = aws_vpclattice_listener.this[each.key].listener_id
  service_identifier  = aws_vpclattice_service.this[each.key].id
  priority            = each.value.routing_rules.priority

  match {
    http_match {
      dynamic "path_match" {
        for_each = each.value.routing_rules.path_match != null ? [each.value.routing_rules.path_match] : []
        content {
          case_sensitive = path_match.value.case_sensitive
          match {
            prefix = path_match.value.prefix
          }
        }
      }

      dynamic "header_matches" {
        for_each = each.value.routing_rules.header_matches != null ? each.value.routing_rules.header_matches : []
        content {
          name           = header_matches.value.name
          case_sensitive = header_matches.value.case_sensitive
          match {
            exact = header_matches.value.exact
          }
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.this[each.key].id
        weight                  = 100
      }
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${each.key}-rule"
    ServiceName = each.key
  })
}

################################################################################
# Service Auth Policies (Optional)
# 개별 서비스에 대한 IAM 인증 정책
################################################################################

resource "aws_vpclattice_auth_policy" "service" {
  for_each = { for k, v in var.services : k => v if v.auth_policy != null }

  resource_identifier = aws_vpclattice_service.this[each.key].arn
  policy              = each.value.auth_policy
}

################################################################################
# CloudWatch Log Group for Access Logs
################################################################################

resource "aws_cloudwatch_log_group" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  name              = "/aws/vpc-lattice/${var.project}-${var.environment}"
  retention_in_days = var.access_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-lattice-logs"
  })
}

################################################################################
# Access Log Subscription
################################################################################

resource "aws_vpclattice_access_log_subscription" "this" {
  count = var.enable_access_logs ? 1 : 0

  resource_identifier = aws_vpclattice_service_network.this.id
  destination_arn     = aws_cloudwatch_log_group.access_logs[0].arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-access-logs"
  })
}
