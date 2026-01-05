################################################################################
# Variables
################################################################################

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for EKS nodes"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for node groups"
  type        = list(string)
}

################################################################################
# System Node Group Variables
################################################################################

variable "create_system_node_group" {
  description = "Create system node group"
  type        = bool
  default     = true
}

variable "system_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["m6i.large"]
}

variable "system_desired_size" {
  description = "Desired size for system node group"
  type        = number
  default     = 2
}

variable "system_min_size" {
  description = "Minimum size for system node group"
  type        = number
  default     = 2
}

variable "system_max_size" {
  description = "Maximum size for system node group"
  type        = number
  default     = 4
}

################################################################################
# Application Node Group Variables
################################################################################

variable "create_application_node_group" {
  description = "Create application node group"
  type        = bool
  default     = true
}

variable "application_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["m6i.xlarge"]
}

variable "application_desired_size" {
  description = "Desired size for application node group"
  type        = number
  default     = 2
}

variable "application_min_size" {
  description = "Minimum size for application node group"
  type        = number
  default     = 2
}

variable "application_max_size" {
  description = "Maximum size for application node group"
  type        = number
  default     = 10
}

################################################################################
# Spot Node Group Variables
################################################################################

variable "create_spot_node_group" {
  description = "Create spot node group"
  type        = bool
  default     = false
}

variable "spot_instance_types" {
  description = "Instance types for spot node group"
  type        = list(string)
  default     = ["m6i.xlarge", "m5.xlarge", "m5a.xlarge"]
}

variable "spot_desired_size" {
  description = "Desired size for spot node group"
  type        = number
  default     = 2
}

variable "spot_min_size" {
  description = "Minimum size for spot node group"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum size for spot node group"
  type        = number
  default     = 10
}
