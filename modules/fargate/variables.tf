################################################################################
# EKS Fargate Module - Variables
################################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "pod_execution_role_arn" {
  description = "ARN of the Fargate Pod Execution Role"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for Fargate"
  type        = list(string)
}

################################################################################
# Profile Toggles
################################################################################

variable "create_system_profile" {
  description = "Whether to create system Fargate profile"
  type        = bool
  default     = true
}

variable "create_application_profile" {
  description = "Whether to create application Fargate profile"
  type        = bool
  default     = true
}

variable "create_monitoring_profile" {
  description = "Whether to create monitoring Fargate profile"
  type        = bool
  default     = false
}

################################################################################
# Application Namespace Pattern (와일드카드 지원)
# AWS Best Practice: 와일드카드를 사용하여 네임스페이스 그룹화
# https://aws.amazon.com/about-aws/whats-new/2022/08/wildcard-support-amazon-eks-fargate-profile-selectors/
################################################################################

variable "application_namespace_pattern" {
  description = "Namespace pattern for application Fargate profile (supports wildcards: *, ?). Example: app-* matches app-demo, app-test, app-petclinic"
  type        = string
  default     = "app-*"
}

variable "include_default_namespace" {
  description = "Whether to include default namespace in application profile"
  type        = bool
  default     = false
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
