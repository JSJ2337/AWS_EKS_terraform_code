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

        # Helm Ingress 비활성화 - Terraform에서 직접 생성
        ingress = {
          enabled = false
        }

        # 리소스 제한
        resources = var.server_resources
      }

      # Controller 설정
      controller = {
        replicas  = var.controller_replicas
        resources = var.controller_resources
      }

      # Repo Server 설정
      repoServer = {
        replicas  = var.repo_server_replicas
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

################################################################################
# ArgoCD Server Ingress (Terraform 관리)
# Helm 차트의 Ingress는 host 기본값 문제로 비활성화하고 직접 생성
################################################################################

resource "kubernetes_ingress_v1" "argocd_server" {
  count = var.ingress_enabled ? 1 : 0

  metadata {
    name        = "${var.release_name}-server"
    namespace   = var.namespace
    annotations = var.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    # Host 조건 없이 path만 설정 - 모든 호스트에서 접근 가능
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${var.release_name}-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # TLS 설정 (선택적)
    dynamic "tls" {
      for_each = var.ingress_tls
      content {
        secret_name = tls.value.secretName
        hosts       = tls.value.hosts
      }
    }
  }

  depends_on = [helm_release.argocd]
}

################################################################################
# Git Repository Credentials (AWS Secrets Manager 연동)
# ArgoCD에서 Private Git Repository 접근을 위한 인증 정보
################################################################################

# Secrets Manager에서 GitHub PAT 조회
data "aws_secretsmanager_secret_version" "github_pat" {
  count     = var.git_repository_enabled ? 1 : 0
  secret_id = var.github_pat_secret_id
}

# ArgoCD Repository Secret
resource "kubernetes_secret_v1" "git_repository" {
  count = var.git_repository_enabled ? 1 : 0

  metadata {
    name      = "repo-${var.git_repository_name}"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.git_repository_url
    username = var.git_repository_username
    password = data.aws_secretsmanager_secret_version.github_pat[0].secret_string
  }

  depends_on = [helm_release.argocd]
}
