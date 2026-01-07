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
# Fargate Profile - Application (default, app namespaces)
################################################################################

resource "aws_eks_fargate_profile" "application" {
  count = var.create_application_profile ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.cluster_name}-application"
  pod_execution_role_arn = var.pod_execution_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "default"
  }

  dynamic "selector" {
    for_each = var.application_namespaces
    content {
      namespace = selector.value
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
