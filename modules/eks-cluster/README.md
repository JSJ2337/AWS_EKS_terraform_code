# EKS Cluster Module

EKS 컨트롤 플레인과 OIDC Provider를 생성하는 모듈입니다.

## 개요

이 모듈은 Amazon EKS 클러스터의 핵심 구성요소를 생성합니다:

- **EKS Cluster**: Kubernetes 컨트롤 플레인
- **OIDC Provider**: IRSA(IAM Roles for Service Accounts) 지원

## 아키텍처

```text
EKS Cluster
├── Control Plane
│   ├── API Server
│   ├── etcd
│   ├── Controller Manager
│   └── Scheduler
│
├── VPC Configuration
│   ├── Private Endpoint Access
│   ├── Public Endpoint Access
│   └── Security Group
│
├── Encryption
│   └── KMS Key (Secrets)
│
├── Logging
│   └── CloudWatch Logs (api, audit, authenticator, controllerManager, scheduler)
│
└── OIDC Provider
    └── IRSA Support
```

## 사용법

```hcl
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  region      = "ap-northeast-2"
  project     = "my-project"
  environment = "prod"

  cluster_name              = "my-eks-cluster"
  cluster_version           = "1.31"
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  subnet_ids                = module.networking.private_subnet_ids
  cluster_security_group_id = module.security.eks_cluster_security_group_id

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  kms_key_arn = module.foundation.kms_key_arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "prod"
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `region` | AWS 리전 | `string` | - | ✅ |
| `project` | 프로젝트 이름 | `string` | - | ✅ |
| `environment` | 환경 이름 | `string` | - | ✅ |
| `cluster_name` | EKS 클러스터 이름 | `string` | - | ✅ |
| `cluster_version` | Kubernetes 버전 | `string` | `1.31` | ❌ |
| `cluster_role_arn` | EKS 클러스터 IAM Role ARN | `string` | - | ✅ |
| `subnet_ids` | 클러스터 서브넷 ID 목록 | `list(string)` | - | ✅ |
| `cluster_security_group_id` | 클러스터 보안 그룹 ID | `string` | - | ✅ |
| `endpoint_private_access` | Private API 엔드포인트 활성화 | `bool` | `true` | ❌ |
| `endpoint_public_access` | Public API 엔드포인트 활성화 | `bool` | `true` | ❌ |
| `public_access_cidrs` | Public 엔드포인트 접근 허용 CIDR | `list(string)` | `["0.0.0.0/0"]` | ❌ |
| `kms_key_arn` | Secrets 암호화용 KMS 키 ARN | `string` | `null` | ❌ |
| `enabled_cluster_log_types` | 활성화할 로그 타입 목록 | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | ❌ |
| `cluster_log_retention_days` | CloudWatch 로그 보관 기간 | `number` | `30` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `cluster_id` | EKS 클러스터 ID |
| `cluster_name` | EKS 클러스터 이름 |
| `cluster_arn` | EKS 클러스터 ARN |
| `cluster_endpoint` | EKS API 서버 엔드포인트 |
| `cluster_version` | EKS 클러스터 버전 |
| `cluster_certificate_authority_data` | 클러스터 CA 인증서 데이터 |
| `cluster_oidc_issuer_url` | OIDC Issuer URL |
| `oidc_provider_arn` | OIDC Provider ARN |
| `oidc_provider_id` | OIDC Provider ID (URL에서 https:// 제외) |

## Access Config

이 모듈은 EKS Access Config를 사용하여 인증을 관리합니다:

```hcl
access_config {
  authentication_mode                         = "API_AND_CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true
}
```

- **API_AND_CONFIG_MAP**: API와 ConfigMap 모두 지원
- **bootstrap_cluster_creator_admin_permissions**: 생성자에게 자동으로 관리자 권한 부여

## IRSA (IAM Roles for Service Accounts)

이 모듈은 OIDC Provider를 자동으로 생성하여 IRSA를 지원합니다:

```hcl
# Service Account에 IAM Role 연결 예시
resource "aws_iam_role" "example" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks_cluster.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks_cluster.oidc_provider_id}:sub" = "system:serviceaccount:namespace:sa-name"
        }
      }
    }]
  })
}
```

## 의존성

- `00-foundation`: KMS 키
- `04-iam`: EKS Cluster IAM Role
- `10-networking`: Subnet IDs
- `20-security`: Security Group ID

## 클러스터 로그 타입

| 로그 타입 | 설명 |
|-----------|------|
| `api` | Kubernetes API 서버 요청 |
| `audit` | Kubernetes 감사 로그 |
| `authenticator` | IAM 인증 로그 |
| `controllerManager` | 컨트롤러 매니저 로그 |
| `scheduler` | 스케줄러 로그 |

## 보안 권장사항

- `public_access_cidrs`를 특정 IP로 제한하세요
- KMS 암호화를 활성화하여 Secrets를 보호하세요
- 감사 로그(audit)를 활성화하여 API 호출을 추적하세요

## 관련 문서

- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [EKS Access Entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
