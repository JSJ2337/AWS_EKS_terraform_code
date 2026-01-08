# Addons Module

EKS Add-on과 IRSA(IAM Roles for Service Accounts)를 생성하는 모듈입니다.

## 개요

이 모듈은 EKS 클러스터에 필요한 핵심 Add-on과 추가 컨트롤러를 위한 IRSA를 생성합니다:

- **VPC CNI**: Pod 네트워킹
- **CoreDNS**: 클러스터 DNS
- **kube-proxy**: 네트워크 프록시
- **EBS CSI Driver**: EBS 볼륨 지원 (EC2 전용)
- **Pod Identity Agent**: Pod Identity 지원
- **AWS Load Balancer Controller IRSA**: ALB/NLB 지원
- **Cluster Autoscaler IRSA**: 노드 오토스케일링 (EC2 전용)

## 아키텍처

```text
EKS Add-ons
├── Core Add-ons (필수)
│   ├── vpc-cni
│   │   └── Prefix Delegation 활성화
│   ├── coredns
│   │   └── Fargate: computeType = "Fargate"
│   └── kube-proxy
│
├── Storage Add-ons (EC2 전용)
│   └── aws-ebs-csi-driver
│       └── IRSA Role
│
├── Identity Add-ons
│   └── eks-pod-identity-agent
│
└── IRSA Roles
    ├── AWS Load Balancer Controller
    └── Cluster Autoscaler (EC2 전용)
```

## 사용법

```hcl
module "addons" {
  source = "../../modules/addons"

  region      = "ap-northeast-2"
  project     = "my-project"
  environment = "prod"

  cluster_name      = module.eks_cluster.cluster_name
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_provider_id  = module.eks_cluster.oidc_provider_id

  # Fargate 사용 시
  use_fargate = true

  # Add-on 버전 (null = 최신)
  vpc_cni_version    = null
  coredns_version    = null
  kube_proxy_version = null

  # Fargate에서는 비활성화
  enable_ebs_csi           = false
  enable_cluster_autoscaler = false

  enable_pod_identity      = true
  enable_aws_lb_controller = true

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
| `cluster_name` | EKS 클러스터 이름 | `string` | - | ✅ |
| `oidc_provider_arn` | OIDC Provider ARN | `string` | - | ✅ |
| `oidc_provider_id` | OIDC Provider ID | `string` | - | ✅ |
| `vpc_cni_version` | VPC CNI 버전 | `string` | `null` | ❌ |
| `coredns_version` | CoreDNS 버전 | `string` | `null` | ❌ |
| `kube_proxy_version` | kube-proxy 버전 | `string` | `null` | ❌ |
| `ebs_csi_version` | EBS CSI Driver 버전 | `string` | `null` | ❌ |
| `pod_identity_version` | Pod Identity Agent 버전 | `string` | `null` | ❌ |
| `enable_ebs_csi` | EBS CSI Driver 활성화 | `bool` | `true` | ❌ |
| `enable_pod_identity` | Pod Identity Agent 활성화 | `bool` | `true` | ❌ |
| `enable_aws_lb_controller` | AWS LB Controller IRSA 생성 | `bool` | `true` | ❌ |
| `enable_cluster_autoscaler` | Cluster Autoscaler IRSA 생성 | `bool` | `true` | ❌ |
| `use_fargate` | Fargate 사용 여부 | `bool` | `false` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `vpc_cni_addon_id` | VPC CNI Add-on ID |
| `coredns_addon_id` | CoreDNS Add-on ID |
| `kube_proxy_addon_id` | kube-proxy Add-on ID |
| `ebs_csi_addon_id` | EBS CSI Driver Add-on ID |
| `ebs_csi_role_arn` | EBS CSI Driver IAM Role ARN |
| `aws_lb_controller_role_arn` | AWS LB Controller IAM Role ARN |
| `cluster_autoscaler_role_arn` | Cluster Autoscaler IAM Role ARN |

## Add-on 상세

### VPC CNI

```hcl
configuration_values = jsonencode({
  env = {
    ENABLE_PREFIX_DELEGATION = "true"
    WARM_PREFIX_TARGET       = "1"
  }
})
```

- Prefix Delegation으로 IP 주소 효율성 향상
- Pod당 IP 할당 최적화

### CoreDNS (Fargate)

```hcl
configuration_values = var.use_fargate ? jsonencode({
  computeType = "Fargate"
}) : null
```

- Fargate에서 CoreDNS를 실행하려면 `computeType = "Fargate"` 설정 필수
- 이 설정이 없으면 CoreDNS가 EC2 노드를 찾다가 Pending 상태 유지

### EBS CSI Driver

- EC2 Node Group에서만 사용 가능
- Fargate는 EBS를 지원하지 않음
- IRSA로 IAM 권한 부여

### AWS Load Balancer Controller

- ALB/NLB 생성 및 관리
- IRSA Role만 생성 (실제 설치는 Helm으로 별도 수행)
- 정책 파일: `policies/aws-load-balancer-controller-policy.json`

### Cluster Autoscaler

- EC2 Node Group 오토스케일링
- Fargate는 자동으로 스케일되므로 불필요
- IRSA Role만 생성

## Fargate 사용 시 설정

Fargate를 사용할 때 다음 설정을 권장합니다:

```hcl
use_fargate               = true
enable_ebs_csi            = false  # Fargate는 EBS 미지원
enable_cluster_autoscaler = false  # Fargate는 자동 스케일
enable_aws_lb_controller  = true   # ALB 필요
enable_pod_identity       = true   # 권장
```

## IRSA 구성

이 모듈은 Service Account와 IAM Role을 연결하는 IRSA를 구성합니다:

```hcl
assume_role_policy = jsonencode({
  Statement = [{
    Effect = "Allow"
    Principal = {
      Federated = var.oidc_provider_arn
    }
    Action = "sts:AssumeRoleWithWebIdentity"
    Condition = {
      StringEquals = {
        "${var.oidc_provider_id}:aud" = "sts.amazonaws.com"
        "${var.oidc_provider_id}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
      }
    }
  }]
})
```

## 의존성

- `30-eks-cluster`: OIDC Provider
- `40-fargate`: Fargate Profile (CoreDNS 실행용)

## 관련 문서

- [EKS Add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
- [VPC CNI](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html)
- [EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
