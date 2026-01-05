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

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "oidc_provider_id" {
  description = "OIDC provider ID (URL without https://)"
  type        = string
}

################################################################################
# Add-on Versions
################################################################################

variable "vpc_cni_version" {
  description = "VPC CNI add-on version"
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "CoreDNS add-on version"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "kube-proxy add-on version"
  type        = string
  default     = null
}

variable "ebs_csi_version" {
  description = "EBS CSI driver add-on version"
  type        = string
  default     = null
}

variable "pod_identity_version" {
  description = "Pod Identity Agent add-on version"
  type        = string
  default     = null
}

################################################################################
# Add-on Toggles
################################################################################

variable "enable_ebs_csi" {
  description = "Enable EBS CSI driver"
  type        = bool
  default     = true
}

variable "enable_pod_identity" {
  description = "Enable Pod Identity Agent"
  type        = bool
  default     = true
}

variable "enable_aws_lb_controller" {
  description = "Enable AWS Load Balancer Controller IRSA"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler IRSA"
  type        = bool
  default     = true
}
