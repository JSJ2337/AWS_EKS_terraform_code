################################################################################
# VPC Lattice Module - Variables
################################################################################

################################################################################
# Required Variables
################################################################################

variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 이름 (dev, stg, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

################################################################################
# Service Network Configuration
################################################################################

variable "auth_type" {
  description = "Service Network 인증 타입 (NONE 또는 AWS_IAM)"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "AWS_IAM"], var.auth_type)
    error_message = "auth_type은 NONE 또는 AWS_IAM이어야 합니다."
  }
}

variable "security_group_ids" {
  description = "VPC Association에 적용할 Security Group IDs"
  type        = list(string)
  default     = []
}

variable "service_network_auth_policy" {
  description = "Service Network IAM Auth Policy (JSON)"
  type        = string
  default     = null
}

################################################################################
# Services Configuration
################################################################################

variable "services" {
  description = "VPC Lattice 서비스 정의"
  type = map(object({
    # Target Group 설정
    target_type = string  # IP, INSTANCE, LAMBDA, ALB
    port        = number
    protocol    = string  # HTTP, HTTPS

    # Health Check 설정
    health_check_path     = optional(string, "/health")
    health_check_protocol = optional(string, "HTTP")
    health_check_interval = optional(number, 30)
    health_check_timeout  = optional(number, 5)
    healthy_threshold     = optional(number, 2)
    unhealthy_threshold   = optional(number, 2)
    health_check_matcher  = optional(string, "200-299")

    # Listener 설정
    listener_protocol = optional(string, "HTTP")
    listener_port     = optional(number)

    # Auth 설정 (개별 서비스용)
    auth_type   = optional(string)
    auth_policy = optional(string)

    # 고급 라우팅 규칙
    routing_rules = optional(object({
      priority = number
      path_match = optional(object({
        prefix         = string
        case_sensitive = optional(bool, false)
      }))
      header_matches = optional(list(object({
        name           = string
        exact          = string
        case_sensitive = optional(bool, false)
      })))
    }))
  }))
  default = {}
}

################################################################################
# Access Logs Configuration
################################################################################

variable "enable_access_logs" {
  description = "Access Logs 활성화 여부"
  type        = bool
  default     = true
}

variable "access_logs_retention_days" {
  description = "Access Logs 보존 기간 (일)"
  type        = number
  default     = 30
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}
