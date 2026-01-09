# Addons Module

EKS Add-on과 IRSA(IAM Roles for Service Accounts)를 생성하는 모듈입니다.

## 개요

이 모듈은 EKS Fargate 클러스터에 필요한 핵심 Add-on과 컨트롤러를 위한 IRSA를 생성합니다:

- **VPC CNI**: Pod 네트워킹
- **CoreDNS**: 클러스터 DNS (Fargate 설정 포함)
- **kube-proxy**: 네트워크 프록시
- **Pod Identity Agent**: Pod Identity 지원
- **AWS Load Balancer Controller IRSA**: ALB/NLB 지원

> **참고**: 이 프로젝트는 Fargate 전용입니다. EC2 Node Group 관련 기능(EBS CSI Driver, Cluster Autoscaler)은 지원하지 않습니다.

## 아키텍처

```text
EKS Add-ons (Fargate)
├── Core Add-ons (필수)
│   ├── vpc-cni
│   │   └── Prefix Delegation 활성화
│   ├── coredns
│   │   └── computeType = "Fargate"
│   └── kube-proxy
│
├── Identity Add-ons
│   └── eks-pod-identity-agent
│
└── IRSA Roles
    └── AWS Load Balancer Controller
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

  # Fargate 필수 설정
  use_fargate = true

  # Add-on 버전 (null = 최신)
  vpc_cni_version    = null
  coredns_version    = null
  kube_proxy_version = null

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
| `pod_identity_version` | Pod Identity Agent 버전 | `string` | `null` | ❌ |
| `enable_pod_identity` | Pod Identity Agent 활성화 | `bool` | `true` | ❌ |
| `enable_aws_lb_controller` | AWS LB Controller IRSA 생성 | `bool` | `true` | ❌ |
| `use_fargate` | Fargate 사용 여부 | `bool` | `false` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `vpc_cni_addon_id` | VPC CNI Add-on ID |
| `coredns_addon_id` | CoreDNS Add-on ID |
| `kube_proxy_addon_id` | kube-proxy Add-on ID |
| `aws_lb_controller_role_arn` | AWS LB Controller IAM Role ARN |

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

### AWS Load Balancer Controller

- ALB/NLB 생성 및 관리
- IRSA Role 생성 및 Helm 배포 (일체형)
- 정책 파일: `policies/aws-load-balancer-controller-policy.json`
- Fargate 환경에서는 `target-type: ip` 필수

```hcl
# Helm 배포 설정
helm_release "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
}
```

#### 필수 IAM 권한

```json
{
  "Action": [
    "elasticloadbalancing:DescribeListenerAttributes",
    "elasticloadbalancing:DescribeLoadBalancers",
    "elasticloadbalancing:DescribeTargetGroups",
    ...
  ]
}
```

> **주의**: AWS LB Controller v2.7+ 버전에서는 `DescribeListenerAttributes` 권한이 필수입니다.

## Fargate 권장 설정

```hcl
use_fargate              = true
enable_pod_identity      = true
enable_aws_lb_controller = true
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
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)
