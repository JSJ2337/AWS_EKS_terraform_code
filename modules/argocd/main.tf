################################################################################
# ArgoCD Module
# Helm Provider를 사용하여 ArgoCD 설치
################################################################################

################################################################################
# Namespace
################################################################################

resource "kubernetes_namespace_v1" "argocd" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = {
      name                         = var.namespace
      "app.kubernetes.io/name"     = "argocd"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

################################################################################
# ArgoCD Helm Release
################################################################################

resource "helm_release" "argocd" {
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  create_namespace = !var.create_namespace
  wait             = var.wait
  timeout          = var.timeout

  # 기본 values
  values = [
    yamlencode({
      global = {
        image = {
          tag = var.argocd_version != "" ? var.argocd_version : null
        }
      }

      # Server 설정
      server = {
        replicas = var.server_replicas

        # Service 설정
        service = {
          type = var.server_service_type
        }

        # Ingress 설정 (선택적)
        ingress = {
          enabled = var.ingress_enabled
          ingressClassName = var.ingress_class_name
          hosts   = var.ingress_hosts
          tls     = var.ingress_tls
          annotations = var.ingress_annotations
        }

        # 리소스 제한
        resources = var.server_resources
      }

      # Controller 설정
      controller = {
        replicas = var.controller_replicas
        resources = var.controller_resources
      }

      # Repo Server 설정
      repoServer = {
        replicas = var.repo_server_replicas
        resources = var.repo_server_resources
      }

      # ApplicationSet Controller
      applicationSet = {
        enabled  = var.applicationset_enabled
        replicas = var.applicationset_replicas
      }

      # Redis (HA)
      redis = {
        enabled = true
      }

      # Dex (SSO) - 기본 비활성화
      dex = {
        enabled = var.dex_enabled
      }

      # Notifications
      notifications = {
        enabled = var.notifications_enabled
      }

      # Config
      configs = {
        cm = {
          # Admin 계정 활성화
          "accounts.admin" = "apiKey, login"
          # Application 상태 새로고침 간격
          "timeout.reconciliation" = var.reconciliation_timeout
        }

        params = {
          # Insecure 모드 (TLS termination at LB)
          "server.insecure" = var.server_insecure
        }

        secret = {
          # 초기 admin 비밀번호 (bcrypt hash)
          argocdServerAdminPassword = var.admin_password_hash
        }
      }
    })
  ]

  # 추가 사용자 정의 values
  set = [
    for s in var.additional_set_values : {
      name  = s.name
      value = s.value
    }
  ]

  depends_on = [kubernetes_namespace_v1.argocd]
}
