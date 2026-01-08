# CloudWatch Module

AWS 서비스를 위한 CloudWatch Log Group을 생성하는 모듈입니다.

## 개요

이 모듈은 다양한 AWS 서비스의 로그를 수집하기 위한 CloudWatch Log Group을 생성합니다:

- **EKS Log Group**: EKS 클러스터 로그
- **ECS Log Group**: ECS 클러스터 로그
- **EC2 Log Group**: CloudWatch Agent 로그
- **Lambda Log Group**: Lambda 함수 로그
- **VPC Flow Log Group**: VPC 트래픽 로그
- **Application Log Groups**: 커스텀 애플리케이션 로그

## 아키텍처

```text
CloudWatch Log Groups
├── AWS Services
│   ├── /aws/eks/{cluster-name}/cluster
│   ├── /aws/ecs/{project}-{env}
│   ├── /aws/ec2/{project}-{env}
│   └── /aws/vpc/{project}-{env}/flow-logs
│
├── Lambda Functions
│   └── /aws/lambda/{function-name}
│
└── Applications (Custom)
    └── /{project}/{env}/{app-name}
```

## 사용법

```hcl
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project      = "my-project"
  environment  = "prod"
  cluster_name = "my-eks-cluster"

  # EKS 로그
  create_eks_log_group   = true
  eks_log_retention_days = 7

  # VPC Flow Logs
  create_vpc_flow_log_group   = true
  vpc_flow_log_retention_days = 14

  # Lambda 함수들
  lambda_functions = ["my-function-1", "my-function-2"]
  lambda_log_retention_days = 14

  # 커스텀 애플리케이션 로그
  application_log_groups = {
    "api" = {
      retention_days = 30
    }
    "worker" = {
      retention_days = 14
    }
  }

  # KMS 암호화
  kms_key_arn = module.foundation.kms_key_arn

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
| `cluster_name` | EKS 클러스터 이름 | `string` | `""` | ❌ |
| `create_eks_log_group` | EKS 로그 그룹 생성 여부 | `bool` | `false` | ❌ |
| `eks_log_retention_days` | EKS 로그 보관 기간 (일) | `number` | `7` | ❌ |
| `create_ecs_log_group` | ECS 로그 그룹 생성 여부 | `bool` | `false` | ❌ |
| `ecs_log_retention_days` | ECS 로그 보관 기간 (일) | `number` | `7` | ❌ |
| `create_ec2_log_group` | EC2 로그 그룹 생성 여부 | `bool` | `false` | ❌ |
| `ec2_log_retention_days` | EC2 로그 보관 기간 (일) | `number` | `7` | ❌ |
| `lambda_functions` | Lambda 함수 이름 목록 | `set(string)` | `[]` | ❌ |
| `lambda_log_retention_days` | Lambda 로그 보관 기간 (일) | `number` | `14` | ❌ |
| `create_vpc_flow_log_group` | VPC Flow 로그 그룹 생성 여부 | `bool` | `false` | ❌ |
| `vpc_flow_log_retention_days` | VPC Flow 로그 보관 기간 (일) | `number` | `14` | ❌ |
| `application_log_groups` | 커스텀 로그 그룹 맵 | `map(object)` | `{}` | ❌ |
| `kms_key_arn` | KMS 암호화 키 ARN | `string` | `null` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `eks_log_group_name` | EKS 로그 그룹 이름 |
| `eks_log_group_arn` | EKS 로그 그룹 ARN |
| `ecs_log_group_name` | ECS 로그 그룹 이름 |
| `ecs_log_group_arn` | ECS 로그 그룹 ARN |
| `ec2_log_group_name` | EC2 로그 그룹 이름 |
| `ec2_log_group_arn` | EC2 로그 그룹 ARN |
| `lambda_log_group_names` | Lambda 로그 그룹 이름 맵 |
| `lambda_log_group_arns` | Lambda 로그 그룹 ARN 맵 |
| `vpc_flow_log_group_name` | VPC Flow 로그 그룹 이름 |
| `vpc_flow_log_group_arn` | VPC Flow 로그 그룹 ARN |
| `application_log_group_names` | 애플리케이션 로그 그룹 이름 맵 |
| `application_log_group_arns` | 애플리케이션 로그 그룹 ARN 맵 |

## Log Group 상세

### EKS Cluster Log Group

```text
이름: /aws/eks/{cluster-name}/cluster
용도: EKS 컨트롤 플레인 로그
  - API Server
  - Audit
  - Authenticator
  - Controller Manager
  - Scheduler
```

### VPC Flow Log Group

```text
이름: /aws/vpc/{project}-{env}/flow-logs
용도: VPC 네트워크 트래픽 로그
  - 소스/대상 IP
  - 포트
  - 프로토콜
  - 허용/거부 상태
```

### Application Log Groups

```text
이름: /{project}/{env}/{app-name}
용도: 커스텀 애플리케이션 로그
  - API 서버 로그
  - 워커 로그
  - 배치 작업 로그
```

## 로그 보관 기간 권장값

| 로그 타입 | 개발 환경 | 프로덕션 환경 | 비고 |
|-----------|-----------|---------------|------|
| EKS 클러스터 | 3일 | 7-30일 | 감사 요구사항에 따라 |
| VPC Flow Logs | 7일 | 14-30일 | 보안 분석용 |
| Lambda | 7일 | 14일 | 디버깅용 |
| 애플리케이션 | 7일 | 30-90일 | 비즈니스 요구사항에 따라 |

## KMS 암호화

모든 로그 그룹은 선택적으로 KMS 암호화를 적용할 수 있습니다:

```hcl
resource "aws_cloudwatch_log_group" "example" {
  name       = "/example/log-group"
  kms_key_id = var.kms_key_arn  # KMS 암호화 활성화
}
```

## 의존성

- `00-foundation`: KMS 키

## 비용 최적화

1. **보관 기간 최적화**: 필요한 기간만 보관
2. **로그 필터링**: 필요한 로그만 수집
3. **로그 레벨 조정**: 프로덕션에서는 INFO 이상만
4. **S3 아카이브**: 장기 보관은 S3로 내보내기

## 모니터링 연동

CloudWatch Log Group은 다음과 연동할 수 있습니다:

- **CloudWatch Alarms**: 특정 패턴 발생 시 알람
- **CloudWatch Insights**: 로그 분석
- **Kinesis Data Firehose**: 실시간 스트리밍
- **Lambda**: 로그 기반 자동화
- **OpenSearch**: 고급 분석

## 관련 문서

- [CloudWatch Logs User Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [EKS Control Plane Logs](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)
