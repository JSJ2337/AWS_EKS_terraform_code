# Security Module

EKS Fargate 인프라를 위한 Security Group을 생성하는 보안 모듈입니다.

## 개요

이 모듈은 EKS Fargate 환경에 필요한 모든 Security Group을 생성합니다:

- **EKS Cluster SG**: 컨트롤 플레인 보안 그룹
- **EKS Pods SG**: Fargate Pod 보안 그룹
- **ALB SG**: Application Load Balancer 보안 그룹
- **RDS SG**: Aurora MySQL 보안 그룹
- **ElastiCache SG**: Redis 보안 그룹

## 아키텍처

```text
Security Groups
├── EKS Cluster SG
│   ├── Ingress: Pods → 443 (API Server)
│   └── Egress: All traffic
│
├── EKS Pods SG (Fargate)
│   ├── Ingress: Self (Pod-to-Pod)
│   ├── Ingress: Cluster → 1025-65535
│   ├── Ingress: Cluster → 443 (Webhooks)
│   ├── Ingress: ALB → 0-65535
│   └── Egress: All traffic
│
├── ALB SG
│   ├── Ingress: 0.0.0.0/0 → 80 (HTTP)
│   ├── Ingress: 0.0.0.0/0 → 443 (HTTPS)
│   └── Egress: Pods SG
│
├── RDS SG
│   └── Ingress: Pods SG → 3306 (MySQL)
│
└── ElastiCache SG
    └── Ingress: Pods SG → 6379 (Redis)
```

## 사용법

```hcl
module "security" {
  source = "../../modules/security"

  region       = "ap-northeast-2"
  project      = "my-project"
  environment  = "prod"
  vpc_id       = module.networking.vpc_id
  cluster_name = "my-eks-cluster"

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
| `vpc_id` | VPC ID | `string` | - | ✅ |
| `cluster_name` | EKS 클러스터 이름 | `string` | - | ✅ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `eks_cluster_security_group_id` | EKS 클러스터 보안 그룹 ID |
| `eks_pods_security_group_id` | EKS Pods 보안 그룹 ID |
| `alb_security_group_id` | ALB 보안 그룹 ID |
| `rds_security_group_id` | RDS 보안 그룹 ID |
| `elasticache_security_group_id` | ElastiCache 보안 그룹 ID |

## 보안 규칙 상세

### EKS Cluster Security Group

| 방향 | 포트 | 프로토콜 | 소스/대상 | 설명 |
|------|------|----------|-----------|------|
| Ingress | 443 | TCP | Pods SG | Pod에서 API Server 접근 |
| Egress | All | All | 0.0.0.0/0 | 모든 아웃바운드 허용 |

### EKS Pods Security Group

| 방향 | 포트 | 프로토콜 | 소스/대상 | 설명 |
|------|------|----------|-----------|------|
| Ingress | All | All | Self | Pod 간 통신 |
| Ingress | 1025-65535 | TCP | Cluster SG | 클러스터에서 Pod 통신 |
| Ingress | 443 | TCP | Cluster SG | Webhook 통신 |
| Ingress | 0-65535 | TCP | ALB SG | ALB에서 Pod 접근 |
| Egress | All | All | 0.0.0.0/0 | 모든 아웃바운드 허용 |

### ALB Security Group

| 방향 | 포트 | 프로토콜 | 소스/대상 | 설명 |
|------|------|----------|-----------|------|
| Ingress | 80 | TCP | 0.0.0.0/0 | HTTP 트래픽 |
| Ingress | 443 | TCP | 0.0.0.0/0 | HTTPS 트래픽 |
| Egress | All | All | Pods SG | Pod로 트래픽 전달 |

### RDS Security Group

| 방향 | 포트 | 프로토콜 | 소스/대상 | 설명 |
|------|------|----------|-----------|------|
| Ingress | 3306 | TCP | Pods SG | Pod에서 MySQL 접근 |

### ElastiCache Security Group

| 방향 | 포트 | 프로토콜 | 소스/대상 | 설명 |
|------|------|----------|-----------|------|
| Ingress | 6379 | TCP | Pods SG | Pod에서 Redis 접근 |

## Fargate 특이사항

Fargate를 사용할 때는 EC2 Node Security Group이 필요 없습니다. 대신 Pods Security Group이 Fargate Pod의 ENI에 직접 적용됩니다.

## 의존성

- `10-networking`: VPC ID

## 보안 권장사항

- Egress 규칙을 필요한 대상으로만 제한하는 것을 권장합니다
- ALB Ingress CIDR을 필요한 IP 범위로 제한하세요
- 프로덕션 환경에서는 WAF 연동을 고려하세요

## 관련 문서

- [EKS Security Groups](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)
- [Fargate Pod Networking](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)
- [AWS Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)