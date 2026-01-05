# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

AWS EKS 인프라를 Terraform/Terragrunt로 관리하는 프로젝트입니다. 동일 워크스페이스의 GCP_terraform_code 프로젝트 패턴을 따릅니다.

## 작업 계획서 기반 프로젝트 리딩

**중요: 모든 작업은 `docs/project-plan.md` 작업 계획서를 기준으로 진행합니다.**

### 프로젝트 핵심 원칙

- **멀티 어카운트 기반**: AWS Organizations 확장 대비 설계
- **프로덕션 베스트 프랙티스**: 보안, 고가용성, 확장성 확보
- **유지보수 용이성**: 모듈화, 문서화, 자동화

### 작업 진행 방식

1. **작업 시작 전**: `docs/project-plan.md` 읽고 현재 Phase 확인
2. **작업 중**: 계획서의 체크리스트 항목 순서대로 진행
3. **작업 완료 후**: 계획서 체크리스트 업데이트, work_history 기록

### Phase별 우선순위

| Phase | 내용 | 상태 |
| ----- | ---- | ---- |
| Phase 1 | 기반 인프라 (State, IAM) | 대기 |
| Phase 2 | 네트워크 (VPC, Subnet) | 대기 |
| Phase 3 | EKS 클러스터 | 대기 |
| Phase 4 | 데이터 계층 (RDS, Redis) | 대기 |
| Phase 5 | 보안 강화 | 대기 |
| Phase 6 | 모니터링/로깅 | 대기 |
| Phase 7 | CI/CD | 대기 |

### 작업 요청 시

사용자가 특정 작업을 요청하면:

1. `docs/project-plan.md`에서 해당 작업의 Phase와 세부 항목 확인
2. 의존성 있는 선행 작업 완료 여부 확인
3. 계획서의 설계 기준에 맞게 구현
4. 완료 후 계획서 체크리스트 업데이트

## 권장 디렉토리 구조

```
AWS_EKS_terraform_code/
├── bootstrap/                    # 초기 AWS 계정 설정 (최초 배포)
│   ├── 00-foundation/           # AWS 계정, 기본 IAM
│   ├── 10-vpc/                  # 관리용 VPC
│   ├── 20-state/                # S3 backend, DynamoDB state lock
│   ├── root.hcl
│   ├── common.hcl
│   └── Jenkinsfile
│
├── modules/                      # 재사용 가능한 Terraform 모듈
│   ├── eks-cluster/             # EKS 컨트롤 플레인
│   ├── eks-nodegroup/           # 워커 노드 그룹
│   ├── vpc-networking/          # VPC, 서브넷, NAT
│   ├── rds-database/            # RDS 인스턴스
│   ├── elasticache/             # ElastiCache
│   ├── iam-roles/               # IAM 역할 및 정책
│   ├── security-groups/         # 보안 그룹
│   └── observability/           # CloudWatch, X-Ray
│
├── environments/                 # 환경별 구성
│   ├── LIVE/                    # 프로덕션
│   ├── STG/                     # 스테이징
│   └── DEV/                     # 개발
│
└── docs/                        # 문서
    ├── architecture.md
    ├── README.md
    └── work_history/            # 일일 작업 이력
```

## 주요 명령어

### Terragrunt 명령어

```bash
# 단일 레이어 실행
cd environments/LIVE/eks-prod/10-networking
terragrunt init
terragrunt plan
terragrunt apply

# 전체 환경 실행 (의존성 순서대로)
cd environments/LIVE/eks-prod
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply

# 특정 레이어만 destroy
terragrunt destroy

# 출력값 확인
terragrunt output
terragrunt output -json
```

### Terraform 명령어

```bash
# 모듈 개발 시
cd modules/eks-cluster
terraform init
terraform validate
terraform fmt -recursive
```

### AWS CLI

```bash
# EKS 클러스터 접근
aws eks update-kubeconfig --name <cluster-name> --region <region>

# 클러스터 상태 확인
aws eks describe-cluster --name <cluster-name>

# 노드 그룹 확인
aws eks list-nodegroups --cluster-name <cluster-name>
```

### kubectl (EKS 연동 후)

```bash
kubectl get nodes
kubectl get pods -A
kubectl describe node <node-name>
```

## 아키텍처 패턴

### 레이어 기반 배포 순서

| Phase | 레이어 | 의존성 | 목적 |
|-------|--------|--------|------|
| 1 | 00-foundation | - | AWS 기본 설정 |
| 2 | 10-networking | 00-foundation | VPC, 서브넷, NAT |
| 3 | 20-security | 10-networking | IAM, 보안 그룹 |
| 4 | 30-eks-cluster | 20-security | EKS 컨트롤 플레인 |
| 5 | 40-nodegroups | 30-eks-cluster | 워커 노드 |
| 6 | 50-addons | 40-nodegroups | EKS 애드온 |
| 7 | 60-database | 20-security | RDS |
| 8 | 70-cache | 20-security | ElastiCache |
| 9 | 80-storage | 30-eks-cluster | EBS, EFS, S3 |
| 10 | 90-monitoring | 50-addons | CloudWatch, Prometheus |

### Terragrunt 설정 계층

```
root.hcl (백엔드 생성, 프로바이더 버전)
    ↓
common.hcl (공통 변수: region, account_id, project)
    ↓
environments/{ENV}/{PROJECT}/root.hcl (환경별 설정)
    ↓
environments/{ENV}/{PROJECT}/{LAYER}/terragrunt.hcl (레이어별)
```

### State 백엔드 구성

```hcl
# S3 + DynamoDB
remote_state {
  backend = "s3"
  config = {
    bucket         = "${project}-terraform-state"
    key            = "${env}/${layer}/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "${project}-terraform-lock"
  }
}
```

## EKS 필수 설정

### 서브넷 태그 (EKS 요구사항)

```hcl
# 퍼블릭 서브넷
tags = {
  "kubernetes.io/role/elb"                    = "1"
  "kubernetes.io/cluster/${cluster_name}"     = "shared"
}

# 프라이빗 서브넷
tags = {
  "kubernetes.io/role/internal-elb"           = "1"
  "kubernetes.io/cluster/${cluster_name}"     = "shared"
}
```

### IRSA (IAM Roles for Service Accounts)

```hcl
# OIDC Provider 생성 필수
# Service Account와 IAM Role 매핑
```

### 필수 EKS 애드온

- vpc-cni: VPC 네트워킹
- coredns: DNS 서비스
- kube-proxy: 네트워크 프록시
- aws-ebs-csi-driver: EBS 볼륨

## 도구 버전

- Terraform: >= 1.6
- Terragrunt: >= 0.50
- AWS Provider: >= 5.0
- kubectl: >= 1.28
- AWS CLI: >= 2.0

## 코드 컨벤션

### 네이밍

- 리소스: snake_case (예: `eks_cluster`, `node_group`)
- 파일: kebab-case (예: `eks-cluster`, `vpc-networking`)
- 환경변수: UPPER_SNAKE_CASE (예: `AWS_REGION`)

### 변수 파일

- `common.naming.tfvars`: 프로젝트 공통 변수
- `terraform.tfvars`: 레이어별 변수

### 보안 필수 사항

- 하드코딩된 credentials 금지
- IAM 최소 권한 원칙
- 프라이빗 서브넷에 워커 노드 배치
- Security Group 최소화
- Secrets Manager 또는 Parameter Store 사용

## 문서화 규칙 (필수)

코드 변경 시 반드시 관련 문서를 함께 업데이트해야 합니다.

### 문서 구조

```text
docs/
├── README.md                # 프로젝트 개요, 사용법
├── architecture.md          # 인프라 아키텍처 설명
├── troubleshooting.md       # 트러블슈팅 가이드
└── work_history/            # 일일 작업 이력
    ├── 2025-01-05.md
    ├── 2025-01-06.md
    └── ...
```

### 코드 변경 시 문서 업데이트 규칙

#### 1. work_history 업데이트 (항상 필수)

모든 코드 변경 시 `docs/work_history/YYYY-MM-DD.md` 파일에 기록:

```markdown
# 작업 이력 - YYYY-MM-DD

## HH:MM - 작업 제목

### 변경 사항

- 변경된 파일: `파일경로`
- 변경 내용: 구체적인 설명
- 이유: 왜 이 변경이 필요했는지

### 영향도

- 영향받는 컴포넌트/서비스
- 주의사항

---
```

#### 2. 상황별 문서 업데이트 대상

| 변경 유형              | 업데이트 대상 문서                 |
| ---------------------- | ---------------------------------- |
| 모든 변경              | `docs/work_history/YYYY-MM-DD.md`  |
| 새 기능/모듈 추가      | `docs/README.md`                   |
| 인프라 구조 변경       | `docs/architecture.md`             |
| 네트워크 토폴로지 변경 | `docs/architecture.md`             |
| 환경변수/설정 변경     | `docs/README.md`                   |
| 이슈 해결              | `docs/troubleshooting.md`          |
| 배포 방법 변경         | `docs/README.md`                   |

#### 3. 문서 작성 규칙 (markdownlint 준수)

- 제목 위아래 빈 줄 추가
- 코드 블록에 언어 지정 (`hcl`, `bash`)
- 파일 끝에 빈 줄 하나 추가
- 제목 순차적 레벨 사용 (H1 → H2 → H3)
- 목록은 `-` 사용

### 작업 완료 체크리스트

코드 변경 후 반드시 확인:

- [ ] `docs/work_history/YYYY-MM-DD.md` 업데이트 완료
- [ ] 관련 기능 문서 업데이트 완료
- [ ] 코드와 문서 내용 일치 확인
- [ ] 예제 코드/명령어 동작 확인
- [ ] markdownlint 규칙 준수 확인

**중요: 코드만 수정하고 문서를 업데이트하지 않으면 작업 미완료입니다.**
