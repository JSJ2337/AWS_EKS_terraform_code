################################################################################
# ArgoCD Module Outputs
################################################################################

output "namespace" {
  description = "ArgoCD namespace"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.argocd.status
}

output "chart_version" {
  description = "ArgoCD Helm chart version"
  value       = helm_release.argocd.version
}

output "server_service_name" {
  description = "ArgoCD server service name"
  value       = "${var.release_name}-server"
}

output "server_service_port" {
  description = "ArgoCD server service port"
  value       = 443
}

output "server_url" {
  description = "ArgoCD server URL (internal)"
  value       = "https://${var.release_name}-server.${var.namespace}.svc.cluster.local"
}

output "ingress_enabled" {
  description = "Whether Ingress is enabled"
  value       = var.ingress_enabled
}

output "ingress_name" {
  description = "ArgoCD Ingress name"
  value       = var.ingress_enabled ? kubernetes_ingress_v1.argocd_server[0].metadata[0].name : null
}
