# ArgoCD Module

Helm을 사용하여 ArgoCD를 설치하는 모듈입니다.

## 개요

이 모듈은 GitOps 기반 배포를 위한 ArgoCD를 EKS 클러스터에 설치합니다:

- **ArgoCD Server**: Web UI 및 API
- **ArgoCD Controller**: Git 동기화 컨트롤러
- **ArgoCD Repo Server**: Git 리포지토리 연결
- **ApplicationSet Controller**: 멀티 클러스터 배포
- **Redis**: 세션 및 캐시 저장소

## 아키텍처

```text
ArgoCD Components
├── Server
│   ├── Web UI
│   ├── API Server
│   └── Service (ClusterIP/LoadBalancer)
│
├── Application Controller
│   └── Git 동기화 및 상태 관리
│
├── Repo Server
│   ├── Git Clone
│   ├── Helm Template
│   └── Kustomize Build
│
├── ApplicationSet Controller
│   └── 멀티 클러스터/환경 배포
│
├── Redis
│   └── 세션 및 캐시
│
└── Dex (선택적)
    └── SSO 인증
```

## 사용법

```hcl
module "argocd" {
  source = "../../modules/argocd"

  release_name     = "argocd"
  namespace        = "argocd"
  create_namespace = true

  chart_version  = "7.7.10"
  argocd_version = ""  # 차트 기본값 사용

  # Server 설정
  server_replicas      = 1
  server_service_type  = "ClusterIP"
  server_insecure      = true  # TLS termination at LB

  # Controller 설정
  controller_replicas = 1

  # Repo Server 설정
  repo_server_replicas = 1

  # ApplicationSet
  applicationset_enabled  = true
  applicationset_replicas = 1

  # 추가 컴포넌트
  dex_enabled           = false
  notifications_enabled = false

  # Ingress (선택적)
  ingress_enabled    = false
  ingress_class_name = "alb"

  # Admin 비밀번호 (bcrypt hash)
  admin_password_hash = ""  # 기본값 사용

  tags = {
    Environment = "prod"
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `release_name` | Helm Release 이름 | `string` | `argocd` | ❌ |
| `namespace` | Kubernetes 네임스페이스 | `string` | `argocd` | ❌ |
| `create_namespace` | 네임스페이스 생성 여부 | `bool` | `true` | ❌ |
| `chart_version` | ArgoCD Helm 차트 버전 | `string` | `7.7.10` | ❌ |
| `argocd_version` | ArgoCD 애플리케이션 버전 | `string` | `""` | ❌ |
| `wait` | 배포 완료 대기 | `bool` | `true` | ❌ |
| `timeout` | Helm 타임아웃 (초) | `number` | `600` | ❌ |
| `server_replicas` | Server 레플리카 수 | `number` | `1` | ❌ |
| `server_service_type` | Server 서비스 타입 | `string` | `ClusterIP` | ❌ |
| `server_insecure` | Insecure 모드 (TLS at LB) | `bool` | `true` | ❌ |
| `server_resources` | Server 리소스 제한 | `object` | 기본값 | ❌ |
| `controller_replicas` | Controller 레플리카 수 | `number` | `1` | ❌ |
| `controller_resources` | Controller 리소스 제한 | `object` | 기본값 | ❌ |
| `repo_server_replicas` | Repo Server 레플리카 수 | `number` | `1` | ❌ |
| `repo_server_resources` | Repo Server 리소스 제한 | `object` | 기본값 | ❌ |
| `applicationset_enabled` | ApplicationSet 활성화 | `bool` | `true` | ❌ |
| `applicationset_replicas` | ApplicationSet 레플리카 수 | `number` | `1` | ❌ |
| `dex_enabled` | Dex SSO 활성화 | `bool` | `false` | ❌ |
| `notifications_enabled` | Notifications 활성화 | `bool` | `false` | ❌ |
| `ingress_enabled` | Ingress 활성화 | `bool` | `false` | ❌ |
| `ingress_class_name` | Ingress 클래스 이름 | `string` | `alb` | ❌ |
| `ingress_hosts` | Ingress 호스트 목록 | `list(string)` | `[]` | ❌ |
| `ingress_tls` | Ingress TLS 설정 | `list(object)` | `[]` | ❌ |
| `ingress_annotations` | Ingress 어노테이션 | `map(string)` | `{}` | ❌ |
| `reconciliation_timeout` | 동기화 타임아웃 | `string` | `180s` | ❌ |
| `admin_password_hash` | Admin 비밀번호 (bcrypt) | `string` | `""` | ❌ |
| `additional_set_values` | 추가 Helm set 값 | `list(object)` | `[]` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `namespace` | ArgoCD 네임스페이스 |
| `release_name` | Helm Release 이름 |
| `release_status` | Helm Release 상태 |
| `chart_version` | 설치된 차트 버전 |
| `server_service_name` | Server 서비스 이름 |
| `server_service_port` | Server 서비스 포트 |
| `server_url` | Server 내부 URL |
| `ingress_enabled` | Ingress 활성화 여부 |
| `ingress_name` | Ingress 리소스 이름 |

## 리소스 기본값

### Server

```hcl
resources = {
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  limits = {
    cpu    = "500m"
    memory = "512Mi"
  }
}
```

### Controller

```hcl
resources = {
  requests = {
    cpu    = "100m"
    memory = "256Mi"
  }
  limits = {
    cpu    = "500m"
    memory = "512Mi"
  }
}
```

### Repo Server

```hcl
resources = {
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  limits = {
    cpu    = "500m"
    memory = "512Mi"
  }
}
```

## Admin 비밀번호 설정

bcrypt 해시로 비밀번호를 설정합니다:

```bash
# 비밀번호 해시 생성
htpasswd -nbBC 10 "" "your-password" | tr -d ':\n' | sed 's/$2y/$2a/'

# 또는 Python 사용
python3 -c "import bcrypt; print(bcrypt.hashpw(b'your-password', bcrypt.gensalt()).decode())"
```

## 초기 로그인

설치 후 초기 admin 비밀번호 확인:

```bash
# 자동 생성된 비밀번호 조회
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 포트 포워딩
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 브라우저에서 접속
# https://localhost:8080
# ID: admin
# PW: (위에서 조회한 비밀번호)
```

## Ingress 설정 예시

### AWS ALB (Host 없이 직접 접속)

이 모듈은 Helm 차트의 Ingress 대신 Terraform `kubernetes_ingress_v1`로 직접 Ingress를 생성합니다.
이를 통해 Host 조건 없이 ALB URL로 직접 접속할 수 있습니다.

```hcl
ingress_enabled    = true
ingress_class_name = "alb"
ingress_hosts      = [""]  # 빈 값 = 모든 호스트 허용 (HOSTS: *)

ingress_annotations = {
  "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
  "alb.ingress.kubernetes.io/target-type"        = "ip"
  "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTP\": 80}]"
  "alb.ingress.kubernetes.io/healthcheck-path"   = "/healthz"
  "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
  "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
}
```

### AWS ALB (특정 도메인 사용)

```hcl
ingress_enabled    = true
ingress_class_name = "alb"
ingress_hosts      = ["argocd.example.com"]

ingress_annotations = {
  "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
  "alb.ingress.kubernetes.io/target-type"      = "ip"
  "alb.ingress.kubernetes.io/certificate-arn"  = "arn:aws:acm:..."
  "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\": 443}]"
  "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
}
```

### Ingress 구현 상세

ArgoCD Helm 차트의 Ingress는 `hosts`가 비어있으면 기본값 `argocd.example.com`을 강제 설정하는 문제가 있습니다.
이를 해결하기 위해 Helm Ingress를 비활성화하고 Terraform으로 직접 Ingress를 생성합니다.

```hcl
# modules/argocd/main.tf
resource "kubernetes_ingress_v1" "argocd_server" {
  count = var.ingress_enabled ? 1 : 0

  metadata {
    name        = "${var.release_name}-server"
    namespace   = var.namespace
    annotations = var.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    # Host 조건 없이 path만 설정 - HOSTS: *
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
  }
}
```

## Fargate 고려사항

Fargate에서 ArgoCD를 실행할 때:

1. **Fargate Profile**: `argocd` 네임스페이스 선택자 필요
2. **리소스**: Fargate는 요청한 리소스 기준으로 과금
3. **스토리지**: PVC 대신 ConfigMap/Secret 사용

## 의존성

- `30-eks-cluster`: EKS 클러스터
- `40-fargate`: Fargate Profile (argocd 네임스페이스)
- `50-addons`: VPC CNI, CoreDNS 등

## GitOps 워크플로우

```text
1. 개발자가 애플리케이션 코드 커밋
2. CI가 이미지 빌드 및 ECR Push
3. CI가 K8s 매니페스트 리포지토리 업데이트
4. ArgoCD가 변경 감지 및 자동 동기화
5. 클러스터에 새 버전 배포
```

## 보안 권장사항

1. **RBAC**: 사용자별 프로젝트/앱 접근 제한
2. **SSO 연동**: GitHub/GitLab/OIDC 인증
3. **Secret 관리**: Vault, AWS Secrets Manager 연동
4. **네트워크 정책**: ArgoCD 컴포넌트 간 통신 제한

## 관련 문서

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm)
- [ArgoCD on EKS](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-argocd-eks.html)
- [GitOps Best Practices](https://www.gitops.tech/)
