# AWS EKS Terraform Code

AWS EKS 인프라를 Terraform/Terragrunt로 관리하는 프로젝트입니다.

## 개요

이 프로젝트는 AWS에서 EKS(Elastic Kubernetes Service) 클러스터와 관련 인프라를 코드로 관리합니다.

## 사전 요구사항

- Terraform >= 1.6
- Terragrunt >= 0.50
- AWS CLI >= 2.0
- kubectl >= 1.28
- AWS 계정 및 적절한 IAM 권한

## 디렉토리 구조

```text
AWS_EKS_terraform_code/
├── bootstrap/                    # 초기 AWS 계정 설정
│   ├── 00-foundation/           # AWS 기본 설정
│   ├── 10-vpc/                  # 관리용 VPC
│   └── 20-state/                # S3/DynamoDB 상태 저장소
│
├── modules/                      # 재사용 가능한 Terraform 모듈
│   ├── eks-cluster/             # EKS 컨트롤 플레인
│   ├── eks-nodegroup/           # 워커 노드 그룹
│   ├── vpc-networking/          # VPC, 서브넷, NAT
│   └── ...
│
├── environments/                 # 환경별 구성
│   ├── LIVE/                    # 프로덕션
│   ├── STG/                     # 스테이징
│   └── DEV/                     # 개발
│
└── docs/                        # 문서
```

## 빠른 시작

### 1. AWS 자격 증명 설정

```bash
aws configure
# 또는
export AWS_PROFILE=your-profile
```

### 2. Bootstrap 배포 (최초 1회)

```bash
cd bootstrap/00-foundation
terragrunt init
terragrunt apply
```

### 3. 환경 배포

```bash
cd environments/LIVE/eks-prod
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

### 4. EKS 클러스터 접근

```bash
aws eks update-kubeconfig --name <cluster-name> --region ap-northeast-2
kubectl get nodes
```

## 주요 명령어

### Terragrunt

```bash
# 단일 레이어
terragrunt init
terragrunt plan
terragrunt apply
terragrunt destroy

# 전체 환경
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

### kubectl

```bash
kubectl get nodes
kubectl get pods -A
kubectl describe node <node-name>
```

## 환경 변수

| 변수명 | 설명 | 예시 |
| ------ | ---- | ---- |
| AWS_REGION | AWS 리전 | ap-northeast-2 |
| AWS_PROFILE | AWS CLI 프로필 | default |
| TF_VAR_environment | 환경 구분 | live, stg, dev |

## 관련 문서

- [아키텍처 설계](architecture.md)
- [트러블슈팅 가이드](troubleshooting.md)
- [작업 이력](work_history/)
