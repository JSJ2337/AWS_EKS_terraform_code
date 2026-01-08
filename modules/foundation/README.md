# Foundation Module

KMS 키와 기본 IAM 역할을 생성하는 기반 모듈입니다.

## 개요

이 모듈은 EKS 인프라의 기반이 되는 리소스들을 생성합니다:

- **KMS Key**: EKS secrets 암호화 및 CloudWatch Logs 암호화용
- **IAM Role**: EKS 관리자 역할 (MFA 필수)

## 아키텍처

```text
Foundation Module
├── KMS Key (EKS Encryption)
│   ├── 자동 로테이션 활성화
│   ├── EKS 서비스 접근 허용
│   └── CloudWatch Logs 접근 허용
└── IAM Role (EKS Admin)
    ├── MFA 필수 조건
    └── AdministratorAccess 정책 연결
```

## 사용법

```hcl
module "foundation" {
  source = "../../modules/foundation"

  region      = "ap-northeast-2"
  project     = "my-project"
  environment = "prod"

  enable_kms            = true
  create_eks_admin_role = true

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `region` | AWS 리전 | `string` | - | ✅ |
| `project` | 프로젝트 이름 | `string` | - | ✅ |
| `environment` | 환경 이름 (prod, staging, dev) | `string` | - | ✅ |
| `enable_kms` | KMS 키 생성 여부 | `bool` | `true` | ❌ |
| `create_eks_admin_role` | EKS 관리자 IAM 역할 생성 여부 | `bool` | `true` | ❌ |
| `tags` | 리소스에 적용할 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `kms_key_arn` | KMS 키 ARN |
| `kms_key_id` | KMS 키 ID |
| `eks_admin_role_arn` | EKS 관리자 IAM 역할 ARN |
| `account_id` | AWS 계정 ID |
| `region` | AWS 리전 |

## 생성되는 리소스

### KMS Key

- **이름**: `alias/{project}-eks-{environment}`
- **용도**: EKS secrets 암호화, CloudWatch Logs 암호화
- **키 로테이션**: 자동 활성화 (365일)
- **삭제 대기 기간**: 7일

### IAM Role

- **이름**: `{project}-eks-admin-{environment}`
- **용도**: EKS 클러스터 관리
- **조건**: MFA 인증 필수
- **연결 정책**: `AdministratorAccess`

## 의존성

이 모듈은 다른 모듈에 의존하지 않으며, 인프라 배포의 첫 번째 레이어로 사용됩니다.

## 주의사항

- KMS 키 삭제 시 7일의 대기 기간이 있습니다
- EKS Admin 역할은 MFA가 필수이므로, assume role 시 MFA 토큰이 필요합니다
- IAM 모듈(04-iam)과 역할이 중복될 수 있으므로, 환경에 따라 하나만 사용하세요

## 관련 문서

- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [EKS Encryption](https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html)