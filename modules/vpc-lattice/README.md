# VPC Lattice Module

AWS VPC Lattice 서비스 네트워크를 구성하는 모듈입니다.

## 개요

VPC Lattice는 AWS의 애플리케이션 네트워킹 서비스로, 서비스 간 통신을 관리합니다.

- **Service Network**: 서비스들의 논리적 그룹
- **Service**: 개별 애플리케이션 서비스
- **Target Group**: 서비스의 대상 (Pod, Lambda 등)
- **Listener**: 트래픽 수신 규칙

## 아키텍처

```text
┌─────────────────────────────────────────────────────────────┐
│                    VPC Lattice Service Network               │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  Service A  │    │  Service B  │    │  Service C  │     │
│  │  (Frontend) │    │  (Backend)  │    │    (API)    │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │              │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐     │
│  │  Listener   │    │  Listener   │    │  Listener   │     │
│  │  (HTTP:80)  │    │  (HTTP:8080)│    │  (HTTP:3000)│     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │              │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐     │
│  │Target Group │    │Target Group │    │Target Group │     │
│  │ (EKS Pods)  │    │ (EKS Pods)  │    │  (Lambda)   │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │    VPC (EKS)      │
                    │  - Fargate Pods   │
                    │  - Services       │
                    └───────────────────┘
```

## 사용법

### 기본 사용법

```hcl
module "vpc_lattice" {
  source = "../../modules/vpc-lattice"

  project     = "my-project"
  environment = "prod"
  vpc_id      = module.networking.vpc_id

  # 인증 없이 사용
  auth_type = "NONE"

  # 서비스 정의
  services = {
    frontend = {
      target_type           = "IP"
      port                  = 80
      protocol              = "HTTP"
      health_check_path     = "/health"
      health_check_protocol = "HTTP"
    }

    backend = {
      target_type           = "IP"
      port                  = 8080
      protocol              = "HTTP"
      health_check_path     = "/api/health"
      health_check_protocol = "HTTP"
    }
  }

  tags = {
    Environment = "prod"
  }
}
```

### IAM 인증 사용

```hcl
module "vpc_lattice" {
  source = "../../modules/vpc-lattice"

  project     = "my-project"
  environment = "prod"
  vpc_id      = module.networking.vpc_id

  # IAM 인증 활성화
  auth_type = "AWS_IAM"

  # Service Network Auth Policy
  service_network_auth_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "vpc-lattice-svcs:Invoke"
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-xxxxxxxxxx"
          }
        }
      }
    ]
  })

  services = {
    api = {
      target_type       = "IP"
      port              = 3000
      protocol          = "HTTP"
      health_check_path = "/health"

      # 개별 서비스 Auth Policy
      auth_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect    = "Allow"
            Principal = "*"
            Action    = "vpc-lattice-svcs:Invoke"
            Resource  = "*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "prod"
  }
}
```

### 고급 라우팅 규칙

```hcl
services = {
  api = {
    target_type           = "IP"
    port                  = 8080
    protocol              = "HTTP"
    health_check_path     = "/health"

    # 고급 라우팅 규칙
    routing_rules = {
      priority = 10
      path_match = {
        prefix         = "/api/v2"
        case_sensitive = false
      }
      header_matches = [
        {
          name           = "X-Api-Version"
          exact          = "v2"
          case_sensitive = false
        }
      ]
    }
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `project` | 프로젝트 이름 | `string` | - | ✅ |
| `environment` | 환경 이름 | `string` | - | ✅ |
| `vpc_id` | VPC ID | `string` | - | ✅ |
| `auth_type` | 인증 타입 (NONE/AWS_IAM) | `string` | `NONE` | ❌ |
| `security_group_ids` | VPC Association Security Groups | `list(string)` | `[]` | ❌ |
| `services` | 서비스 정의 맵 | `map(object)` | `{}` | ❌ |
| `enable_access_logs` | Access Logs 활성화 | `bool` | `true` | ❌ |
| `access_logs_retention_days` | 로그 보존 기간 | `number` | `30` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

### services 객체 구조

| 속성 | 설명 | 타입 | 기본값 |
|------|------|------|--------|
| `target_type` | 대상 유형 (IP/INSTANCE/LAMBDA/ALB) | `string` | - |
| `port` | Target Group 포트 | `number` | - |
| `protocol` | Target Group 프로토콜 (HTTP/HTTPS) | `string` | - |
| `health_check_path` | 헬스체크 경로 | `string` | `/health` |
| `health_check_protocol` | 헬스체크 프로토콜 | `string` | `HTTP` |
| `health_check_interval` | 헬스체크 주기 (초) | `number` | `30` |
| `health_check_timeout` | 헬스체크 타임아웃 (초) | `number` | `5` |
| `healthy_threshold` | 정상 판단 횟수 | `number` | `2` |
| `unhealthy_threshold` | 비정상 판단 횟수 | `number` | `2` |
| `listener_protocol` | Listener 프로토콜 | `string` | `HTTP` |
| `listener_port` | Listener 포트 | `number` | `port`와 동일 |
| `auth_type` | 서비스별 인증 타입 | `string` | Network 설정 상속 |
| `auth_policy` | 서비스별 IAM 정책 | `string` | `null` |
| `routing_rules` | 고급 라우팅 규칙 | `object` | `null` |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `service_network_id` | Service Network ID |
| `service_network_arn` | Service Network ARN |
| `service_network_name` | Service Network 이름 |
| `vpc_association_id` | VPC Association ID |
| `services` | 생성된 서비스 정보 맵 |
| `service_dns_entries` | 각 서비스의 DNS 엔트리 |
| `target_groups` | Target Group 정보 맵 |
| `target_group_ids` | Target Group ID 맵 |
| `listeners` | Listener 정보 맵 |
| `access_logs_log_group_name` | Access Logs Log Group 이름 |

## EKS Fargate와 연동

### Target 등록

VPC Lattice Target Group에 EKS Pod를 등록하려면 AWS Gateway API Controller를 사용합니다.

```bash
# AWS Gateway API Controller 설치
helm install gateway-api-controller \
  oci://public.ecr.aws/aws-application-networking-k8s/aws-gateway-controller-chart \
  --version=v1.0.4 \
  --namespace aws-application-networking-system \
  --create-namespace \
  --set=serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="<IAM_ROLE_ARN>"
```

### Kubernetes Gateway API 사용

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: amazon-vpc-lattice
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
    - name: my-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: my-service
          port: 8080
```

## 서비스 간 호출 방법

VPC Lattice 서비스를 호출할 때는 서비스 DNS를 사용합니다.

```python
# Python 예시
import requests

# 서비스 DNS 엔트리 사용
response = requests.get("http://backend-service.vpc-lattice-xxx.on.aws/api/data")
```

```bash
# curl 예시
curl http://backend-service.vpc-lattice-xxx.on.aws/api/health
```

## ALB와의 차이점

| 항목 | ALB | VPC Lattice |
|------|-----|-------------|
| 트래픽 방향 | North-South (외부→내부) | East-West (내부↔내부) |
| 주 용도 | 외부 사용자 진입점 | 서비스 간 통신 |
| 인증 | 없음 (별도 구현) | IAM 네이티브 |
| 크로스 VPC | 불가 | 지원 |
| 크로스 계정 | 불가 | 지원 |
| 프록시 | 있음 | 없음 (AWS 인프라) |

## 비용

VPC Lattice 비용은 다음으로 구성됩니다:

- Service Network: 시간당 과금
- 데이터 처리: GB당 과금
- 요청 수: 백만 요청당 과금

자세한 내용은 [AWS VPC Lattice Pricing](https://aws.amazon.com/vpc/lattice/pricing/) 참조

## 의존성

- `10-networking`: VPC ID
- `20-security`: Security Group (선택적)

## 관련 문서

- [AWS VPC Lattice Documentation](https://docs.aws.amazon.com/vpc-lattice/latest/ug/what-is-vpc-lattice.html)
- [AWS VPC Lattice Pricing](https://aws.amazon.com/vpc/lattice/pricing/)
- [AWS Gateway API Controller](https://www.gateway-api-controller.eks.aws.dev/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
