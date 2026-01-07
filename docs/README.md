# AWS EKS Terraform Code

AWS EKS 인프라를 Terraform/Terragrunt로 관리하는 프로젝트입니다.

## 개요

이 프로젝트는 AWS에서 EKS(Elastic Kubernetes Service) 클러스터와 관련 인프라를 코드로 관리합니다.

## 현재 배포 상태

| 리소스 | 이름/설정 | 상태 |
| ------ | --------- | ---- |
| VPC | jsj-eks-vpc (10.0.0.0/16) | Active |
| Subnets | 8개 (public/private/database/pod) | Active |
| EKS Cluster | jsj-eks-cluster (v1.31) | Active |
| Node Groups | system (t3.small), app (t3.small) | Active |
| Aurora MySQL | jsj-eks-aurora-mysql (Writer + Reader) | Available |
| S3 State | jsj-eks-terraform-state | Active |
| DynamoDB Lock | jsj-eks-terraform-lock | Active |

## 사전 요구사항

- Terraform >= 1.14
- Terragrunt >= 0.96
- AWS CLI >= 2.22
- kubectl >= 1.31
- AWS 계정 및 적절한 IAM 권한

## 디렉토리 구조

```text
AWS_EKS_terraform_code/
├── .github/workflows/            # GitHub Actions CI/CD
│   ├── terragrunt-apply.yml     # 인프라 배포
│   └── terragrunt-destroy.yml   # 인프라 삭제
│
├── modules/                      # Terraform 모듈
│   ├── networking/              # VPC, 서브넷, NAT, IGW
│   ├── security/                # Security Groups, IAM
│   ├── cloudwatch/              # CloudWatch Log Groups (EKS, ECS, EC2, Lambda, VPC)
│   ├── eks-cluster/             # EKS 컨트롤 플레인
│   ├── eks-nodegroup/           # 워커 노드 그룹
│   ├── eks-addons/              # EKS 애드온 (vpc-cni, coredns 등)
│   ├── argocd/                  # ArgoCD (Helm Provider)
│   ├── aurora-mysql/            # Aurora MySQL 클러스터
│   └── foundation/              # KMS
│
├── environments/                 # 환경별 구성
│   └── prod/                    # 프로덕션 환경
│       ├── 00-foundation/       # KMS, 기본 설정
│       ├── 05-cloudwatch/       # CloudWatch Log Groups
│       ├── 10-networking/       # VPC, 서브넷
│       ├── 20-security/         # Security Groups
│       ├── 30-eks-cluster/      # EKS 클러스터
│       ├── 40-nodegroups/       # 워커 노드
│       ├── 50-addons/           # EKS 애드온
│       ├── 55-argocd/           # ArgoCD (GitOps)
│       ├── 60-database/         # Aurora MySQL
│       ├── root.hcl             # Terragrunt 루트 설정
│       └── common.hcl           # 공통 변수
│
├── k8s-manifests/               # Kubernetes 매니페스트
│   ├── demo-app/                # 데모 애플리케이션
│   └── petclinic/               # 3-tier 아키텍처 테스트
│
└── docs/                        # 문서
    ├── README.md
    ├── architecture.md
    ├── troubleshooting.md
    └── work_history/            # 일일 작업 이력
```

## 빠른 시작

### 1. GitHub Actions로 배포 (권장)

1. GitHub Actions → Terragrunt Apply 선택
2. layer 선택 (all: 전체 배포)
3. environment 선택 (prod)
4. Run workflow 클릭

### 2. 로컬에서 배포

```bash
# AWS 자격 증명 설정
aws configure
# 또는
export AWS_PROFILE=your-profile

# 레이어별 배포
cd environments/prod/10-networking
terragrunt run init
terragrunt run -- plan
terragrunt run -- apply -auto-approve
```

### 3. EKS 클러스터 접근

```bash
# kubeconfig 설정
aws eks update-kubeconfig --name jsj-eks-cluster --region ap-northeast-2

# 클러스터 확인
kubectl get nodes
kubectl get pods -A
```

## 주요 명령어

### Terragrunt (v0.96 신규 문법)

```bash
# 단일 레이어
terragrunt run init
terragrunt run -- plan
terragrunt run -- apply -auto-approve
terragrunt run -- destroy -auto-approve

# 전체 환경
terragrunt run --all init
terragrunt run --all -- plan
terragrunt run --all -- apply -auto-approve
```

### kubectl

```bash
kubectl get nodes
kubectl get pods -A
kubectl describe node <node-name>
```

## GitHub Actions 워크플로우

### Apply (배포)

- 레이어 선택: all, 00-foundation ~ 60-database
- 환경 선택: prod

### Destroy (삭제)

- 레이어 선택: all (역순 삭제), 60-database ~ 00-foundation
- 삭제 확인: `delete` 입력 필수
- 삭제 순서: 60-database → 55-argocd → 50-addons → 40-nodegroups → 30-eks-cluster → 20-security → 10-networking → 05-cloudwatch → 00-foundation

## 환경 변수

| 변수명 | 설명 | 예시 |
| ------ | ---- | ---- |
| AWS_REGION | AWS 리전 | ap-northeast-2 |
| AWS_PROFILE | AWS CLI 프로필 | default |
| TF_VAR_environment | 환경 구분 | prod |

## 관련 문서

- [아키텍처 설계](architecture.md)
- [트러블슈팅 가이드](troubleshooting.md)
- [작업 이력](work_history/)
