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
# Application Namespaces
################################################################################

variable "application_namespaces" {
  description = "Additional namespaces for application Fargate profile"
  type        = list(string)
  default     = []
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
