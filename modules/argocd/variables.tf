################################################################################
# ArgoCD Module Variables
################################################################################

################################################################################
# General
################################################################################

variable "release_name" {
  description = "Helm release name for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.10"
}

variable "argocd_version" {
  description = "ArgoCD application version (empty = chart default)"
  type        = string
  default     = ""
}

variable "wait" {
  description = "Wait for release to be deployed"
  type        = bool
  default     = true
}

variable "timeout" {
  description = "Timeout for Helm release in seconds"
  type        = number
  default     = 600
}

################################################################################
# Server Configuration
################################################################################

variable "server_replicas" {
  description = "Number of ArgoCD server replicas"
  type        = number
  default     = 1
}

variable "server_service_type" {
  description = "Service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"
}

variable "server_insecure" {
  description = "Run server in insecure mode (TLS termination at LB)"
  type        = bool
  default     = true
}

variable "server_resources" {
  description = "Resource limits for ArgoCD server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

################################################################################
# Controller Configuration
################################################################################

variable "controller_replicas" {
  description = "Number of ArgoCD controller replicas"
  type        = number
  default     = 1
}

variable "controller_resources" {
  description = "Resource limits for ArgoCD controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

################################################################################
# Repo Server Configuration
################################################################################

variable "repo_server_replicas" {
  description = "Number of ArgoCD repo server replicas"
  type        = number
  default     = 1
}

variable "repo_server_resources" {
  description = "Resource limits for ArgoCD repo server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

################################################################################
# ApplicationSet Controller
################################################################################

variable "applicationset_enabled" {
  description = "Enable ApplicationSet controller"
  type        = bool
  default     = true
}

variable "applicationset_replicas" {
  description = "Number of ApplicationSet controller replicas"
  type        = number
  default     = 1
}

################################################################################
# Additional Components
################################################################################

variable "dex_enabled" {
  description = "Enable Dex for SSO"
  type        = bool
  default     = false
}

variable "notifications_enabled" {
  description = "Enable ArgoCD notifications"
  type        = bool
  default     = false
}

################################################################################
# Ingress Configuration
################################################################################

variable "ingress_enabled" {
  description = "Enable ingress for ArgoCD server"
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "alb"
}

variable "ingress_hosts" {
  description = "Ingress hosts"
  type        = list(string)
  default     = []
}

variable "ingress_tls" {
  description = "Ingress TLS configuration"
  type = list(object({
    secretName = string
    hosts      = list(string)
  }))
  default = []
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default     = {}
}

################################################################################
# Config
################################################################################

variable "reconciliation_timeout" {
  description = "Application reconciliation timeout"
  type        = string
  default     = "180s"
}

variable "admin_password_hash" {
  description = "Bcrypt hash of admin password"
  type        = string
  default     = ""
  sensitive   = true
}

################################################################################
# Additional Configuration
################################################################################

variable "additional_set_values" {
  description = "Additional Helm set values"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Git Repository Configuration (AWS Secrets Manager 연동)
################################################################################

variable "git_repository_enabled" {
  description = "Enable Git repository connection"
  type        = bool
  default     = false
}

variable "git_repository_name" {
  description = "Name identifier for the Git repository"
  type        = string
  default     = "github"
}

variable "git_repository_url" {
  description = "Git repository URL (HTTPS)"
  type        = string
  default     = ""
}

variable "git_repository_username" {
  description = "Git repository username"
  type        = string
  default     = ""
}

variable "github_pat_secret_id" {
  description = "AWS Secrets Manager secret ID for GitHub PAT"
  type        = string
  default     = ""
}
