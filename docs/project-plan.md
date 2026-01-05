# AWS EKS 프로덕션 환경 구축 작업 계획서

## 프로젝트 개요

### 목표

AWS EKS 기반 프로덕션 환경 인프라를 Terraform/Terragrunt로 구축합니다.

### 핵심 원칙

- **멀티 어카운트 기반**: AWS Organizations 확장 대비 설계
- **프로덕션 베스트 프랙티스**: 보안, 고가용성, 확장성 확보
- **유지보수 용이성**: 모듈화, 문서화, 자동화

### 사용 기술

| 기술 | 버전 | 용도 |
| ---- | ---- | ---- |
| Terraform | >= 1.14 | IaC 도구 |
| Terragrunt | >= 0.96 | Terraform wrapper, DRY 원칙 |
| AWS EKS | 1.29+ | Kubernetes 관리형 서비스 |
| AWS VPC | - | 네트워크 격리 |

---

## Phase 1: 기반 인프라 구축

### 1.1 멀티 어카운트 구조 설계 (AWS Landing Zone 베스트 프랙티스)

```text
AWS Organization (Root)
│
├── Management Account (루트 계정)
│   ├── AWS Organizations 관리
│   ├── AWS IAM Identity Center (SSO)
│   ├── Billing & Cost Management
│   └── Service Control Policies (SCPs)
│
├── Security OU
│   ├── Log Archive Account
│   │   ├── CloudTrail 중앙 로그 (Organization Trail)
│   │   ├── AWS Config 로그
│   │   ├── VPC Flow Logs
│   │   └── S3 Access Logs
│   │
│   └── Audit Account (Security Tooling)
│       ├── AWS Security Hub (위임 관리자)
│       ├── Amazon GuardDuty (위임 관리자)
│       ├── AWS Config Aggregator
│       ├── Amazon Detective
│       └── Cross-Account 보안 감사 역할
│
├── Infrastructure OU
│   ├── Network Account
│   │   ├── Transit Gateway
│   │   ├── AWS Network Firewall
│   │   ├── Route 53 Hosted Zones
│   │   ├── Direct Connect / VPN
│   │   └── 중앙 집중 Egress VPC
│   │
│   └── Shared Services Account
│       ├── ECR (컨테이너 레지스트리)
│       ├── Terraform State (S3 + DynamoDB)
│       ├── CI/CD 파이프라인 (Jenkins/CodePipeline)
│       ├── Artifact Repository
│       └── AMI/Golden Image 관리
│
├── Sandbox OU
│   └── Sandbox Account(s)
│       └── 개발자 실험/테스트 환경
│
└── Workloads OU
    ├── Production Account ← 현재 구축 대상
    │   ├── EKS Cluster
    │   ├── RDS/ElastiCache
    │   └── Application Workloads
    │
    ├── Staging Account
    │   └── Production 미러 환경
    │
    └── Development Account
        └── 개발 환경
```

**OU별 역할:**

| OU | 목적 | 주요 서비스 |
| -- | ---- | ----------- |
| Security OU | 보안 및 감사 중앙화 | CloudTrail, GuardDuty, Security Hub |
| Infrastructure OU | 공유 인프라 관리 | Transit Gateway, ECR, CI/CD |
| Sandbox OU | 실험/학습 환경 | 제한된 리소스, 자동 정리 |
| Workloads OU | 실제 워크로드 운영 | EKS, RDS, 애플리케이션 |

**계정 분리 원칙:**

- 환경별 분리: Production / Staging / Development
- 기능별 분리: Security / Network / Shared Services
- 장애 격리: 계정 단위로 blast radius 제한
- 비용 추적: 계정별 Cost Allocation

### 1.2 Terraform State 관리

**작업 항목:**

- [ ] S3 버킷 생성 (버전 관리, 암호화 활성화)
- [ ] DynamoDB 테이블 생성 (State Locking)
- [ ] Cross-Account 접근 정책 설정

**디렉토리:**

```text
bootstrap/
├── 00-state-backend/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terragrunt.hcl
```

### 1.3 IAM 기반 구성

**작업 항목:**

- [ ] Terraform 실행용 IAM Role 생성
- [ ] Cross-Account Assume Role 정책
- [ ] EKS 관리자 IAM Role/Group

---

## Phase 2: 네트워크 인프라

### 2.1 VPC 설계

**프로덕션 VPC CIDR 설계:**

| 구분 | CIDR | 용도 |
| ---- | ---- | ---- |
| VPC | 10.0.0.0/16 | 프로덕션 VPC |
| Public Subnet A | 10.0.0.0/24 | NAT GW, ALB, Bastion |
| Public Subnet C | 10.0.1.0/24 | NAT GW, ALB (HA) |
| Private Subnet A | 10.0.10.0/24 | EKS 워커 노드 |
| Private Subnet C | 10.0.11.0/24 | EKS 워커 노드 (HA) |
| Database Subnet A | 10.0.20.0/24 | RDS, ElastiCache |
| Database Subnet C | 10.0.21.0/24 | RDS, ElastiCache (HA) |
| Pod Subnet A | 10.0.100.0/22 | EKS Pod (CNI Custom) |
| Pod Subnet C | 10.0.104.0/22 | EKS Pod (CNI Custom) |

**작업 항목:**

- [ ] VPC 생성
- [ ] 퍼블릭/프라이빗/데이터베이스 서브넷 생성
- [ ] Internet Gateway 생성
- [ ] NAT Gateway 생성 (AZ별 HA)
- [ ] Route Table 구성
- [ ] VPC Endpoints 구성 (S3, ECR, STS, Logs)

**디렉토리:**

```text
environments/LIVE/eks-prod/
├── 10-networking/
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── nat-gateway.tf
│   ├── route-tables.tf
│   ├── vpc-endpoints.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terragrunt.hcl
```

### 2.2 보안 그룹 설계

**작업 항목:**

- [ ] EKS 클러스터 Security Group
- [ ] 워커 노드 Security Group
- [ ] ALB Security Group
- [ ] RDS Security Group
- [ ] ElastiCache Security Group
- [ ] Bastion Security Group

---

## Phase 3: EKS 클러스터 구축

### 3.1 EKS 컨트롤 플레인

**설정:**

- Kubernetes 버전: 1.29 (최신 안정 버전)
- 엔드포인트: Private + Public (CIDR 제한)
- 로깅: API Server, Audit, Authenticator, Controller Manager, Scheduler

**작업 항목:**

- [ ] EKS Cluster IAM Role 생성
- [ ] EKS 클러스터 생성
- [ ] OIDC Provider 구성
- [ ] aws-auth ConfigMap 설정
- [ ] 클러스터 로깅 활성화

**디렉토리:**

```text
environments/LIVE/eks-prod/
├── 30-eks-cluster/
│   ├── cluster.tf
│   ├── iam.tf
│   ├── oidc.tf
│   ├── logging.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terragrunt.hcl
```

### 3.2 노드 그룹 구성

**노드 그룹 설계:**

| 노드 그룹 | 인스턴스 타입 | Min/Max | 용도 |
| --------- | ------------- | ------- | ---- |
| system | m6i.large | 2/4 | 시스템 워크로드 |
| application | m6i.xlarge | 2/10 | 애플리케이션 |
| spot | m6i.xlarge | 0/20 | 비용 최적화 (Spot) |

**작업 항목:**

- [ ] Node Group IAM Role 생성
- [ ] Launch Template 구성
- [ ] Managed Node Group 생성
- [ ] Cluster Autoscaler 설정

**디렉토리:**

```text
environments/LIVE/eks-prod/
├── 40-nodegroups/
│   ├── node-group-system.tf
│   ├── node-group-application.tf
│   ├── node-group-spot.tf
│   ├── launch-template.tf
│   ├── iam.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terragrunt.hcl
```

### 3.3 EKS 애드온

**필수 애드온:**

| 애드온 | 버전 | 설명 |
| ------ | ---- | ---- |
| vpc-cni | 최신 | VPC 네트워킹 |
| coredns | 최신 | DNS 서비스 |
| kube-proxy | 최신 | 네트워크 프록시 |
| aws-ebs-csi-driver | 최신 | EBS 볼륨 |
| aws-efs-csi-driver | 최신 | EFS 볼륨 |

**추가 컴포넌트 (Helm/Manifest):**

| 컴포넌트 | 용도 |
| -------- | ---- |
| AWS Load Balancer Controller | ALB/NLB Ingress |
| Cluster Autoscaler | 노드 오토스케일링 |
| Metrics Server | 리소스 메트릭 |
| External DNS | Route53 연동 |
| Cert Manager | 인증서 관리 |

**작업 항목:**

- [ ] EKS 관리형 애드온 설치
- [ ] IRSA 설정 (각 컴포넌트별)
- [ ] AWS Load Balancer Controller 설치
- [ ] Cluster Autoscaler 설치
- [ ] Metrics Server 설치

**디렉토리:**

```text
environments/LIVE/eks-prod/
├── 50-addons/
│   ├── managed-addons.tf
│   ├── irsa.tf
│   ├── aws-lb-controller.tf
│   ├── cluster-autoscaler.tf
│   ├── metrics-server.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terragrunt.hcl
```

---

## Phase 4: 데이터 계층

### 4.1 RDS (Amazon Aurora MySQL)

**설정:**

- 엔진: Aurora MySQL 8.0
- 인스턴스: db.r6g.large (최소 2대)
- Multi-AZ: 활성화
- 암호화: KMS 사용
- 백업: 7일 보관

**작업 항목:**

- [ ] DB 서브넷 그룹 생성
- [ ] 파라미터 그룹 생성
- [ ] Aurora 클러스터 생성
- [ ] Secrets Manager 연동

### 4.2 ElastiCache (Redis)

**설정:**

- 엔진: Redis 7.x
- 노드 타입: cache.r6g.large
- 클러스터 모드: 활성화
- Multi-AZ: 활성화
- 암호화: 전송 중 + 저장 시

**작업 항목:**

- [ ] ElastiCache 서브넷 그룹 생성
- [ ] 파라미터 그룹 생성
- [ ] Redis 클러스터 생성

---

## Phase 5: 보안 강화

### 5.1 IAM 및 RBAC

**작업 항목:**

- [ ] EKS 관리자 IAM Role
- [ ] 개발자 IAM Role (읽기 전용)
- [ ] CI/CD 파이프라인 IAM Role
- [ ] Kubernetes RBAC 정책

### 5.2 네트워크 보안

**작업 항목:**

- [ ] Network Policy (Calico/Cilium)
- [ ] Security Group 최소화
- [ ] VPC Flow Logs 활성화

### 5.3 시크릿 관리

**작업 항목:**

- [ ] AWS Secrets Manager 설정
- [ ] External Secrets Operator 설치
- [ ] KMS 키 생성 및 관리

---

## Phase 6: 모니터링 및 로깅

### 6.1 모니터링

**작업 항목:**

- [ ] CloudWatch Container Insights 활성화
- [ ] Prometheus + Grafana 설치 (선택)
- [ ] 알람 설정 (SNS/Slack)

### 6.2 로깅

**작업 항목:**

- [ ] EKS 컨트롤 플레인 로깅
- [ ] Fluent Bit DaemonSet 설치
- [ ] CloudWatch Logs 또는 S3 저장

---

## Phase 7: CI/CD 파이프라인

### 7.1 Jenkins 파이프라인

**작업 항목:**

- [ ] Jenkinsfile 작성 (Terragrunt 배포)
- [ ] 환경별 파이프라인 분리
- [ ] Plan/Apply 승인 프로세스

---

## 디렉토리 구조 (최종)

```text
AWS_EKS_terraform_code/
├── bootstrap/
│   ├── 00-state-backend/
│   ├── 10-iam-baseline/
│   ├── root.hcl
│   └── common.hcl
│
├── modules/
│   ├── vpc/
│   ├── security-group/
│   ├── eks-cluster/
│   ├── eks-nodegroup/
│   ├── eks-addons/
│   ├── rds-aurora/
│   ├── elasticache-redis/
│   ├── iam-role/
│   ├── kms/
│   └── naming/
│
├── environments/
│   └── LIVE/
│       └── eks-prod/
│           ├── 00-foundation/
│           ├── 10-networking/
│           ├── 20-security/
│           ├── 30-eks-cluster/
│           ├── 40-nodegroups/
│           ├── 50-addons/
│           ├── 60-database/
│           ├── 70-cache/
│           ├── 80-storage/
│           ├── 90-monitoring/
│           ├── common.naming.tfvars
│           ├── root.hcl
│           └── Jenkinsfile
│
├── docs/
│   ├── README.md
│   ├── architecture.md
│   ├── project-plan.md
│   ├── troubleshooting.md
│   └── work_history/
│
├── scripts/
│   ├── init-backend.sh
│   └── deploy.sh
│
├── CLAUDE.md
└── README.md
```

---

## 작업 우선순위

### 즉시 착수 (Week 1-2)

1. State Backend 구축 (bootstrap/00-state-backend)
2. VPC 네트워크 구축 (10-networking)
3. 보안 그룹 구성 (20-security)

### 단기 (Week 3-4)

1. EKS 클러스터 생성 (30-eks-cluster)
2. 노드 그룹 구성 (40-nodegroups)
3. 필수 애드온 설치 (50-addons)

### 중기 (Week 5-6)

1. 데이터베이스 구축 (60-database)
2. 캐시 구축 (70-cache)
3. 모니터링 설정 (90-monitoring)

### 장기

1. CI/CD 파이프라인 완성
2. 멀티 어카운트 확장 (Organizations)
3. Staging/Dev 환경 복제

---

## 체크리스트

### 보안 체크리스트

- [ ] IAM 최소 권한 원칙 적용
- [ ] 모든 데이터 암호화 (저장 시, 전송 중)
- [ ] Private 서브넷에 워커 노드 배치
- [ ] Security Group 인바운드 최소화
- [ ] VPC Endpoints로 AWS 서비스 접근
- [ ] Secrets Manager로 시크릿 관리

### 고가용성 체크리스트

- [ ] Multi-AZ 배포 (최소 2개 AZ)
- [ ] NAT Gateway AZ별 배치
- [ ] EKS 노드 그룹 다중 AZ
- [ ] RDS Multi-AZ 활성화
- [ ] ElastiCache 클러스터 모드

### 운영 체크리스트

- [ ] 모든 리소스 태깅 표준화
- [ ] CloudWatch 알람 설정
- [ ] 백업 정책 수립
- [ ] 비용 모니터링 설정
- [ ] 문서화 완료

---

## 참고 자료

- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
