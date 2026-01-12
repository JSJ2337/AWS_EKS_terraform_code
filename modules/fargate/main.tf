################################################################################
# EKS Fargate Module
# Best Practices: https://docs.aws.amazon.com/eks/latest/userguide/fargate.html
################################################################################

################################################################################
# Fargate Profile - System (kube-system, argocd)
# CoreDNS를 Fargate에서 실행하려면 kube-system 네임스페이스 selector 필요
################################################################################

resource "aws_eks_fargate_profile" "system" {
  count = var.create_system_profile ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.cluster_name}-system"
  pod_execution_role_arn = var.pod_execution_role_arn
  subnet_ids             = var.subnet_ids

  # kube-system 네임스페이스의 모든 Pod (CoreDNS 포함)
  selector {
    namespace = "kube-system"
  }

  # ArgoCD 네임스페이스
  selector {
    namespace = "argocd"
  }

  # Fargate profile 생성/삭제는 시간이 걸릴 수 있음
  timeouts {
    create = "30m"
    delete = "30m"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-fargate-system"
  })
}

################################################################################
# Fargate Profile - Application (와일드카드 패턴 지원)
# AWS Best Practice: 와일드카드를 사용하여 네임스페이스 그룹화
# https://aws.amazon.com/about-aws/whats-new/2022/08/wildcard-support-amazon-eks-fargate-profile-selectors/
################################################################################

resource "aws_eks_fargate_profile" "application" {
  count = var.create_application_profile ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.cluster_name}-application"
  pod_execution_role_arn = var.pod_execution_role_arn
  subnet_ids             = var.subnet_ids

  # 와일드카드 패턴: app-* (app-demo, app-petclinic, app-fullstack, app-test 등)
  selector {
    namespace = var.application_namespace_pattern
  }

  # default 네임스페이스 (선택적)
  dynamic "selector" {
    for_each = var.include_default_namespace ? [1] : []
    content {
      namespace = "default"
    }
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-fargate-application"
  })
}

################################################################################
# Fargate Profile - Monitoring (prometheus, grafana, loki)
################################################################################

resource "aws_eks_fargate_profile" "monitoring" {
  count = var.create_monitoring_profile ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.cluster_name}-monitoring"
  pod_execution_role_arn = var.pod_execution_role_arn
  subnet_ids             = var.subnet_ids

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

  timeouts {
    create = "30m"
    delete = "30m"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-fargate-monitoring"
  })
}
