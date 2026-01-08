# Networking Module

VPC, 서브넷, NAT Gateway, VPC Endpoints를 생성하는 네트워킹 모듈입니다.

## 개요

이 모듈은 EKS 클러스터를 위한 완전한 네트워크 인프라를 구성합니다:

- **VPC**: DNS 지원이 활성화된 VPC
- **서브넷**: Public, Private, Database, Pod 서브넷
- **NAT Gateway**: Private 서브넷의 아웃바운드 인터넷 접근
- **VPC Endpoints**: ECR, S3, CloudWatch Logs, STS 엔드포인트

## 아키텍처

```text
VPC (10.0.0.0/16)
├── Public Subnets (10.0.0.0/24, 10.0.1.0/24)
│   ├── Internet Gateway
│   ├── NAT Gateway
│   └── kubernetes.io/role/elb = 1
│
├── Private Subnets (10.0.10.0/24, 10.0.11.0/24)
│   ├── EKS Nodes/Fargate Pods
│   ├── NAT Gateway 라우팅
│   └── kubernetes.io/role/internal-elb = 1
│
├── Database Subnets (10.0.20.0/24, 10.0.21.0/24)
│   └── 인터넷 접근 불가
│
├── Pod Subnets (10.0.100.0/22, 10.0.104.0/22)
│   └── VPC CNI Custom Networking용
│
└── VPC Endpoints
    ├── S3 (Gateway)
    ├── ECR API (Interface)
    ├── ECR DKR (Interface)
    ├── CloudWatch Logs (Interface)
    └── STS (Interface)
```

## 사용법

```hcl
module "networking" {
  source = "../../modules/networking"

  region       = "ap-northeast-2"
  project      = "my-project"
  environment  = "prod"
  cluster_name = "my-eks-cluster"

  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

  single_nat_gateway    = true  # 비용 절감
  enable_vpc_endpoints  = true  # NAT 비용 절감
  enable_flow_logs      = true

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
| `vpc_cidr` | VPC CIDR 블록 | `string` | `10.0.0.0/16` | ❌ |
| `availability_zones` | 가용 영역 목록 | `list(string)` | `["ap-northeast-2a", "ap-northeast-2c"]` | ❌ |
| `public_subnet_cidrs` | Public 서브넷 CIDR | `list(string)` | `["10.0.0.0/24", "10.0.1.0/24"]` | ❌ |
| `private_subnet_cidrs` | Private 서브넷 CIDR | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | ❌ |
| `database_subnet_cidrs` | Database 서브넷 CIDR | `list(string)` | `["10.0.20.0/24", "10.0.21.0/24"]` | ❌ |
| `pod_subnet_cidrs` | Pod 서브넷 CIDR | `list(string)` | `["10.0.100.0/22", "10.0.104.0/22"]` | ❌ |
| `enable_pod_subnets` | Pod 서브넷 생성 여부 | `bool` | `true` | ❌ |
| `cluster_name` | EKS 클러스터 이름 (태깅용) | `string` | - | ✅ |
| `single_nat_gateway` | 단일 NAT Gateway 사용 여부 | `bool` | `false` | ❌ |
| `enable_flow_logs` | VPC Flow Logs 활성화 | `bool` | `true` | ❌ |
| `enable_vpc_endpoints` | VPC Endpoints 생성 여부 | `bool` | `true` | ❌ |
| `flow_logs_log_group_arn` | Flow Logs용 CloudWatch Log Group ARN | `string` | `null` | ❌ |
| `flow_logs_role_arn` | Flow Logs용 IAM Role ARN | `string` | `null` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR 블록 |
| `public_subnet_ids` | Public 서브넷 ID 목록 |
| `private_subnet_ids` | Private 서브넷 ID 목록 |
| `private_subnet_cidrs` | Private 서브넷 CIDR 목록 |
| `database_subnet_ids` | Database 서브넷 ID 목록 |
| `pod_subnet_ids` | Pod 서브넷 ID 목록 |
| `nat_gateway_ids` | NAT Gateway ID 목록 |
| `internet_gateway_id` | Internet Gateway ID |
| `availability_zones` | 사용된 가용 영역 목록 |
| `vpc_endpoint_s3_id` | S3 VPC Endpoint ID |
| `vpc_endpoint_ecr_api_id` | ECR API VPC Endpoint ID |
| `vpc_endpoint_ecr_dkr_id` | ECR DKR VPC Endpoint ID |
| `vpc_endpoint_logs_id` | CloudWatch Logs VPC Endpoint ID |
| `vpc_endpoint_sts_id` | STS VPC Endpoint ID |

## EKS 필수 태그

이 모듈은 EKS가 요구하는 서브넷 태그를 자동으로 적용합니다:

### Public 서브넷

```hcl
tags = {
  "kubernetes.io/role/elb"                    = "1"
  "kubernetes.io/cluster/${cluster_name}"     = "shared"
}
```

### Private 서브넷

```hcl
tags = {
  "kubernetes.io/role/internal-elb"           = "1"
  "kubernetes.io/cluster/${cluster_name}"     = "shared"
}
```

## VPC Endpoints 비용 절감

VPC Endpoints를 활성화하면 다음 트래픽이 NAT Gateway를 거치지 않아 비용이 절감됩니다:

- **S3**: Gateway Endpoint (무료)
- **ECR**: 컨테이너 이미지 Pull 트래픽
- **CloudWatch Logs**: 로그 전송 트래픽
- **STS**: IRSA 토큰 요청

## 의존성

- `00-foundation`: KMS 키 (Flow Logs 암호화용)
- `04-iam`: VPC Flow Logs IAM Role

## 관련 문서

- [Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [EKS VPC Requirements](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)