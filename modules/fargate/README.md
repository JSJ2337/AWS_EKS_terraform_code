# Fargate Module

EKS Fargate Profile을 생성하는 모듈입니다.

## 개요

이 모듈은 EKS 클러스터에서 서버리스 컴퓨팅을 위한 Fargate Profile을 생성합니다:

- **System Profile**: kube-system, argocd 네임스페이스용
- **Application Profile**: default 및 커스텀 애플리케이션 네임스페이스용
- **Monitoring Profile**: prometheus, grafana, loki 등 모니터링 네임스페이스용

## 아키텍처

```text
Fargate Profiles
├── System Profile
│   ├── kube-system (CoreDNS, kube-proxy 등)
│   └── argocd (GitOps)
│
├── Application Profile
│   ├── default
│   └── [custom namespaces]
│
└── Monitoring Profile (선택적)
    ├── monitoring
    ├── prometheus
    ├── grafana
    └── loki
```

## 사용법

```hcl
module "fargate" {
  source = "../../modules/fargate"

  cluster_name           = module.eks_cluster.cluster_name
  pod_execution_role_arn = module.iam.fargate_pod_execution_role_arn
  subnet_ids             = module.networking.private_subnet_ids

  create_system_profile      = true
  create_application_profile = true
  create_monitoring_profile  = false

  application_namespaces = ["app", "staging"]

  tags = {
    Environment = "prod"
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `cluster_name` | EKS 클러스터 이름 | `string` | - | ✅ |
| `pod_execution_role_arn` | Fargate Pod Execution Role ARN | `string` | - | ✅ |
| `subnet_ids` | Fargate Pod를 배치할 Private 서브넷 ID | `list(string)` | - | ✅ |
| `create_system_profile` | System Profile 생성 여부 | `bool` | `true` | ❌ |
| `create_application_profile` | Application Profile 생성 여부 | `bool` | `true` | ❌ |
| `create_monitoring_profile` | Monitoring Profile 생성 여부 | `bool` | `false` | ❌ |
| `application_namespaces` | Application Profile에 추가할 네임스페이스 | `list(string)` | `[]` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `system_fargate_profile_id` | System Fargate Profile ID |
| `system_fargate_profile_arn` | System Fargate Profile ARN |
| `application_fargate_profile_id` | Application Fargate Profile ID |
| `application_fargate_profile_arn` | Application Fargate Profile ARN |
| `monitoring_fargate_profile_id` | Monitoring Fargate Profile ID |
| `monitoring_fargate_profile_arn` | Monitoring Fargate Profile ARN |

## Fargate Profile 상세

### System Profile

CoreDNS와 시스템 컴포넌트를 실행하기 위한 프로필입니다.

```hcl
selector {
  namespace = "kube-system"
}

selector {
  namespace = "argocd"
}
```

### Application Profile

애플리케이션 워크로드를 실행하기 위한 프로필입니다.

```hcl
selector {
  namespace = "default"
}

dynamic "selector" {
  for_each = var.application_namespaces
  content {
    namespace = selector.value
  }
}
```

### Monitoring Profile

모니터링 스택을 실행하기 위한 프로필입니다.

```hcl
selector {
  namespace = "monitoring"
}
selector {
  namespace = "prometheus"
}
selector {
  namespace = "grafana"
}
selector {
  namespace = "loki"
}
```

## Fargate 제약사항

Fargate를 사용할 때 다음 제약사항을 고려하세요:

| 항목 | 제약사항 |
|------|---------|
| DaemonSet | 지원하지 않음 |
| HostNetwork | 지원하지 않음 |
| HostPort | 지원하지 않음 |
| Privileged | 지원하지 않음 |
| GPU | 지원하지 않음 |
| EBS | 지원하지 않음 (EFS만 지원) |
| LoadBalancer | ALB/NLB만 지원 |

## Timeout 설정

Fargate Profile 생성/삭제는 시간이 걸릴 수 있어 30분 timeout을 설정합니다:

```hcl
timeouts {
  create = "30m"
  delete = "30m"
}
```

## 의존성

- `30-eks-cluster`: EKS 클러스터
- `04-iam`: Fargate Pod Execution Role

## CoreDNS Fargate 설정

Fargate에서 CoreDNS를 실행하려면 addons 모듈에서 추가 설정이 필요합니다:

```hcl
# addons 모듈에서
configuration_values = jsonencode({
  computeType = "Fargate"
})
```

## 모범 사례

1. **네임스페이스 분리**: 워크로드 유형별로 Fargate Profile 분리
2. **서브넷 선택**: 항상 Private 서브넷 사용
3. **Selector 최소화**: 필요한 네임스페이스만 선택
4. **리소스 요청**: Pod에 적절한 리소스 요청 설정

## 관련 문서

- [EKS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)
- [Fargate Profile](https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html)
- [Fargate Pod Configuration](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html)
