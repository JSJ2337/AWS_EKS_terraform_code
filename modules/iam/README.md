# IAM Module

EKS 인프라를 위한 IAM 역할을 중앙 관리하는 모듈입니다.

## 개요

이 모듈은 EKS 클러스터 운영에 필요한 모든 IAM 역할을 생성합니다:

- **EKS Admin Role**: 클러스터 관리자용
- **EKS Cluster Role**: EKS 컨트롤 플레인용
- **VPC Flow Logs Role**: VPC 트래픽 로깅용
- **RDS Monitoring Role**: Enhanced Monitoring용
- **Fargate Pod Execution Role**: Fargate Pod 실행용

## 아키텍처

```text
IAM Roles (Centralized)
├── EKS Admin Role
│   ├── MFA 필수 (선택적)
│   └── AdministratorAccess 정책
│
├── EKS Cluster Role
│   ├── AmazonEKSClusterPolicy
│   └── AmazonEKSVPCResourceController
│
├── VPC Flow Logs Role
│   └── CloudWatch Logs 쓰기 권한
│
├── RDS Monitoring Role
│   └── AmazonRDSEnhancedMonitoringRole
│
└── Fargate Pod Execution Role
    ├── AmazonEKSFargatePodExecutionRolePolicy
    ├── AmazonEC2ContainerRegistryReadOnly
    └── SourceArn 조건 (보안 강화)
```

## 사용법

```hcl
module "iam" {
  source = "../../modules/iam"

  project      = "my-project"
  environment  = "prod"
  cluster_name = "my-eks-cluster"

  create_eks_admin_role            = true
  create_eks_cluster_role          = true
  create_flow_logs_role            = true
  create_rds_monitoring_role       = true
  create_fargate_pod_execution_role = true

  eks_admin_require_mfa = true

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
| `cluster_name` | EKS 클러스터 이름 | `string` | - | ✅ |
| `create_eks_admin_role` | EKS Admin Role 생성 여부 | `bool` | `true` | ❌ |
| `eks_admin_require_mfa` | EKS Admin Role MFA 필수 여부 | `bool` | `true` | ❌ |
| `create_eks_cluster_role` | EKS Cluster Role 생성 여부 | `bool` | `true` | ❌ |
| `create_flow_logs_role` | Flow Logs Role 생성 여부 | `bool` | `true` | ❌ |
| `create_rds_monitoring_role` | RDS Monitoring Role 생성 여부 | `bool` | `true` | ❌ |
| `create_fargate_pod_execution_role` | Fargate Pod Execution Role 생성 여부 | `bool` | `true` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `eks_admin_role_arn` | EKS Admin Role ARN |
| `eks_admin_role_name` | EKS Admin Role 이름 |
| `eks_cluster_role_arn` | EKS Cluster Role ARN |
| `eks_cluster_role_name` | EKS Cluster Role 이름 |
| `flow_logs_role_arn` | Flow Logs Role ARN |
| `flow_logs_role_name` | Flow Logs Role 이름 |
| `rds_monitoring_role_arn` | RDS Monitoring Role ARN |
| `rds_monitoring_role_name` | RDS Monitoring Role 이름 |
| `fargate_pod_execution_role_arn` | Fargate Pod Execution Role ARN |
| `fargate_pod_execution_role_name` | Fargate Pod Execution Role 이름 |

## 역할 상세

### EKS Admin Role

클러스터 관리자가 assume하여 사용하는 역할입니다.

```hcl
assume_role_policy = {
  Principal = {
    AWS = "arn:aws:iam::${account_id}:root"
  }
  Condition = {
    Bool = {
      "aws:MultiFactorAuthPresent" = "true"  # MFA 필수
    }
  }
}
```

- **연결 정책**: `AdministratorAccess`
- **MFA**: 선택적 필수 (권장)

### EKS Cluster Role

EKS 컨트롤 플레인이 사용하는 역할입니다.

```hcl
assume_role_policy = {
  Principal = {
    Service = "eks.amazonaws.com"
  }
}
```

- **연결 정책**:
  - `AmazonEKSClusterPolicy`
  - `AmazonEKSVPCResourceController`

### Fargate Pod Execution Role

Fargate Pod가 AWS 리소스에 접근할 때 사용하는 역할입니다.

```hcl
assume_role_policy = {
  Principal = {
    Service = "eks-fargate-pods.amazonaws.com"
  }
  Condition = {
    ArnLike = {
      "aws:SourceArn" = "arn:aws:eks:${region}:${account_id}:fargateprofile/${cluster_name}/*"
    }
  }
}
```

- **연결 정책**:
  - `AmazonEKSFargatePodExecutionRolePolicy`
  - `AmazonEC2ContainerRegistryReadOnly`
- **보안**: `SourceArn` 조건으로 Confused Deputy 공격 방지

### VPC Flow Logs Role

VPC 트래픽 로그를 CloudWatch에 전송하는 역할입니다.

```hcl
assume_role_policy = {
  Principal = {
    Service = "vpc-flow-logs.amazonaws.com"
  }
}
```

- **권한**: CloudWatch Logs 생성/쓰기

### RDS Enhanced Monitoring Role

RDS Enhanced Monitoring을 위한 역할입니다.

```hcl
assume_role_policy = {
  Principal = {
    Service = "monitoring.rds.amazonaws.com"
  }
}
```

- **연결 정책**: `AmazonRDSEnhancedMonitoringRole`

## IAM 중앙화 장점

1. **단일 관리 지점**: 모든 IAM 역할을 한 곳에서 관리
2. **일관성**: 네이밍, 태깅, 정책 적용의 일관성 보장
3. **감사 용이성**: IAM 역할 변경 이력 추적 용이
4. **의존성 명확화**: 다른 모듈에서 역할 ARN만 참조

## 의존성

이 모듈은 다른 모듈에 의존하지 않습니다. 대신 다른 모듈들이 이 모듈의 출력값을 사용합니다:

- `10-networking`: `flow_logs_role_arn`
- `30-eks-cluster`: `eks_cluster_role_arn`
- `40-fargate`: `fargate_pod_execution_role_arn`
- `60-database`: `rds_monitoring_role_arn`

## 보안 권장사항

1. **최소 권한 원칙**: 필요한 권한만 부여
2. **MFA 필수**: 관리자 역할에 MFA 적용
3. **조건 사용**: SourceArn, SourceAccount 조건으로 범위 제한
4. **정기 감사**: IAM 역할 및 정책 정기 검토

## 관련 문서

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [EKS IAM Roles](https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html)
- [Confused Deputy Problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html)
