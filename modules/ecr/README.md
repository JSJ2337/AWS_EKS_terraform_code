# ECR Module

Amazon ECR 리포지토리를 생성하고 관리하는 모듈입니다.

## 개요

이 모듈은 컨테이너 이미지 저장소를 위한 ECR 리포지토리를 생성합니다:

- **ECR Repositories**: 컨테이너 이미지 저장소
- **Lifecycle Policies**: 자동 이미지 정리
- **Repository Policies**: Cross-account 접근 제어
- **Pull Through Cache**: 퍼블릭 이미지 캐싱
- **Enhanced Scanning**: Inspector 통합 취약점 스캔

## 아키텍처

```text
Amazon ECR
├── Repositories
│   ├── {project}-{app-name}
│   ├── Image Tag Mutability (IMMUTABLE 권장)
│   ├── Image Scanning (on_push)
│   └── Encryption (KMS/AES256)
│
├── Lifecycle Policies
│   ├── Untagged images → 1일 후 삭제
│   ├── Tagged images → 최대 30개 유지
│   └── Dev/Test images → 14일 후 삭제
│
├── Repository Policies
│   ├── Pull Access (Cross-account)
│   └── Push Access (CI/CD)
│
├── Pull Through Cache
│   ├── ECR Public
│   └── Docker Hub (credentials 필요)
│
└── Enhanced Scanning
    └── AWS Inspector 통합
```

## 사용법

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project     = "my-project"
  environment = "prod"

  repositories = {
    "api" = {
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
    }
    "worker" = {
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
    }
  }

  # KMS 암호화
  kms_key_arn = module.foundation.kms_key_arn

  # Lifecycle 정책
  untagged_image_retention_days = 1
  max_image_count               = 30
  cleanup_dev_images            = true
  dev_image_retention_days      = 14

  # Pull Through Cache
  enable_pull_through_cache = false

  # Enhanced Scanning
  enable_enhanced_scanning = false

  tags = {
    Environment = "prod"
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `project` | 프로젝트 이름 | `string` | - | ✅ |
| `environment` | 환경 이름 | `string` | - | ✅ |
| `repositories` | ECR 리포지토리 맵 | `map(object)` | `{}` | ❌ |
| `kms_key_arn` | KMS 암호화 키 ARN | `string` | `null` | ❌ |
| `force_delete` | 이미지가 있어도 삭제 허용 | `bool` | `false` | ❌ |
| `untagged_image_retention_days` | Untagged 이미지 보관 기간 | `number` | `1` | ❌ |
| `max_image_count` | Tagged 이미지 최대 개수 | `number` | `30` | ❌ |
| `cleanup_dev_images` | Dev/Test 이미지 빠른 정리 | `bool` | `true` | ❌ |
| `dev_image_retention_days` | Dev/Test 이미지 보관 기간 | `number` | `14` | ❌ |
| `create_repository_policy` | Repository Policy 생성 여부 | `bool` | `false` | ❌ |
| `pull_access_principal_arns` | Pull 허용 IAM ARN 목록 | `list(string)` | `[]` | ❌ |
| `push_access_principal_arns` | Push 허용 IAM ARN 목록 | `list(string)` | `[]` | ❌ |
| `enable_pull_through_cache` | Pull Through Cache 활성화 | `bool` | `false` | ❌ |
| `docker_hub_secret_arn` | Docker Hub 인증 Secret ARN | `string` | `null` | ❌ |
| `enable_enhanced_scanning` | Enhanced Scanning 활성화 | `bool` | `false` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `repository_arns` | 리포지토리 ARN 맵 |
| `repository_urls` | 리포지토리 URL 맵 |
| `repository_registry_ids` | 리포지토리 Registry ID 맵 |
| `repository_names` | 리포지토리 전체 이름 맵 |

## Lifecycle Policy 상세

### 규칙 1: Untagged 이미지 정리

```json
{
  "rulePriority": 1,
  "description": "Remove untagged images after 1 day",
  "selection": {
    "tagStatus": "untagged",
    "countType": "sinceImagePushed",
    "countUnit": "days",
    "countNumber": 1
  },
  "action": {
    "type": "expire"
  }
}
```

### 규칙 2: Tagged 이미지 개수 제한

```json
{
  "rulePriority": 2,
  "description": "Keep only 30 tagged images",
  "selection": {
    "tagStatus": "tagged",
    "tagPrefixList": ["v", "release", "prod", "staging"],
    "countType": "imageCountMoreThan",
    "countNumber": 30
  },
  "action": {
    "type": "expire"
  }
}
```

### 규칙 3: Dev/Test 이미지 빠른 정리

```json
{
  "rulePriority": 3,
  "description": "Remove dev/test images after 14 days",
  "selection": {
    "tagStatus": "tagged",
    "tagPrefixList": ["dev", "test", "feature", "pr"],
    "countType": "sinceImagePushed",
    "countUnit": "days",
    "countNumber": 14
  },
  "action": {
    "type": "expire"
  }
}
```

## Image Tag Mutability

| 설정 | 설명 | 사용 사례 |
|------|------|----------|
| `IMMUTABLE` | 동일 태그 덮어쓰기 불가 | 프로덕션 (권장) |
| `MUTABLE` | 동일 태그 덮어쓰기 가능 | 개발/테스트 |

## Pull Through Cache

퍼블릭 레지스트리의 이미지를 자동으로 캐싱합니다:

```text
# ECR Public
{account}.dkr.ecr.{region}.amazonaws.com/ecr-public/image:tag

# Docker Hub (인증 필요)
{account}.dkr.ecr.{region}.amazonaws.com/docker-hub/library/nginx:latest
```

## Enhanced Scanning

AWS Inspector와 통합하여 지속적인 취약점 스캔을 수행합니다:

- **Basic Scanning**: Push 시 CVE 스캔 (기본)
- **Enhanced Scanning**: 지속적 스캔 + OS/언어 패키지 취약점

## 사용 예시

### EKS에서 이미지 Pull

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/my-project-api:v1.0.0
```

### CI/CD에서 이미지 Push

```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com

# 이미지 빌드 및 Push
docker build -t my-project-api:v1.0.0 .
docker tag my-project-api:v1.0.0 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/my-project-api:v1.0.0
docker push 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/my-project-api:v1.0.0
```

## 의존성

- `00-foundation`: KMS 키 (선택적)

## 비용 최적화

1. **Lifecycle Policy 활용**: 불필요한 이미지 자동 삭제
2. **멀티 스테이지 빌드**: 이미지 크기 최소화
3. **레이어 캐싱**: 빌드 시간 및 스토리지 절약
4. **Untagged 이미지 정리**: 1일 이내 삭제

## 보안 권장사항

1. **IMMUTABLE 태그**: 프로덕션에서 필수
2. **이미지 스캔**: Push 시 자동 스캔 활성화
3. **KMS 암호화**: 민감한 이미지 암호화
4. **최소 권한**: 필요한 계정/역할만 접근 허용
5. **VPC Endpoints**: 프라이빗 서브넷에서 접근

## 관련 문서

- [Amazon ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [ECR Lifecycle Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
- [ECR Pull Through Cache](https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html)
- [ECR Image Scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html)
