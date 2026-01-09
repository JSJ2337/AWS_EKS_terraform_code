################################################################################
# Common Variables
# 모든 레이어에서 공유하는 변수 정의
# 사용자가 이 파일만 수정하면 전체 환경에 반영됨
################################################################################

locals {
  ############################################################################
  # 기본 설정 (필수 수정)
  ############################################################################

  # AWS 리전
  region = "ap-northeast-2"

  # 프로젝트명 (리소스 네이밍에 사용)
  project = "jsj-eks"

  # 환경명
  environment = "prod"

  # EKS 클러스터명
  cluster_name = "${local.project}-cluster"

  # EKS 버전
  cluster_version = "1.31"

  ############################################################################
  # 네트워크 설정
  ############################################################################

  # VPC CIDR
  vpc_cidr = "10.0.0.0/16"

  # 가용 영역
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

  # 서브넷 CIDR
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]
  pod_subnet_cidrs      = ["10.0.100.0/22", "10.0.104.0/22"]

  # 단일 NAT Gateway 사용 여부 (비용 절감 시 true)
  single_nat_gateway = true

  # VPC Flow Logs 활성화
  enable_flow_logs = true

  # Pod 전용 서브넷 활성화
  enable_pod_subnets = true

  # VPC Endpoints 활성화 (ECR, S3, CloudWatch Logs, STS - NAT Gateway 비용 절감)
  enable_vpc_endpoints = true

  ############################################################################
  # EKS Fargate 설정
  ############################################################################

  fargate = {
    # System Profile (kube-system, argocd)
    system_profile = {
      enabled = true
    }

    # Application Profile (default, custom namespaces)
    application_profile = {
      enabled    = true
      namespaces = ["app", "staging"]
    }

    # Monitoring Profile (prometheus, grafana, loki)
    monitoring_profile = {
      enabled = false
    }
  }

  ############################################################################
  # EKS Add-ons 설정
  ############################################################################

  addons = {
    # EBS CSI: Fargate에서는 EBS 미지원 (EFS만 사용 가능)
    enable_ebs_csi = false

    # Pod Identity: Fargate 지원
    enable_pod_identity = true

    # AWS LB Controller: Fargate 필요
    enable_aws_lb_controller = true
  }

  ############################################################################
  # 보안 설정
  ############################################################################

  # EKS API 엔드포인트 설정
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]  # 필요시 IP 제한

  # 클러스터 로깅
  enabled_cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days = 30

  ############################################################################
  # Aurora MySQL 설정
  ############################################################################

  aurora = {
    # 클러스터 기본 설정
    cluster_identifier = "${local.project}-aurora-mysql"
    engine_version     = "8.0.mysql_aurora.3.08.0"
    database_name      = "petclinic"
    master_username    = "admin"

    # 인스턴스 설정 - 최소 사양 (db.t3.medium이 Aurora 최소)
    instance_class = "db.t3.medium"

    # Writer 1개 + Reader 1개 구성
    instances = {
      writer = {
        promotion_tier = 0
      }
      reader = {
        promotion_tier = 1
      }
    }

    # 백업 설정
    backup_retention_period      = 7
    preferred_backup_window      = "03:00-04:00"
    preferred_maintenance_window = "sun:04:00-sun:05:00"

    # 테스트 환경 설정 (프로덕션에서는 false로 변경)
    skip_final_snapshot = true
    deletion_protection = false
    apply_immediately   = true

    # 모니터링 설정
    monitoring_interval                   = 60
    performance_insights_enabled          = false  # db.t3 인스턴스에서 미지원
    performance_insights_retention_period = 7

    # CloudWatch 로그
    enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  }

  ############################################################################
  # ECR 설정
  ############################################################################

  ecr = {
    # ECR 리포지토리 목록
    repositories = {
      "app" = {
        image_tag_mutability = "IMMUTABLE"  # 프로덕션 권장
        scan_on_push         = true
      }
      "api" = {
        image_tag_mutability = "IMMUTABLE"
        scan_on_push         = true
      }
    }

    # KMS 암호화 사용 여부 (foundation의 KMS 키 사용)
    use_kms_encryption = true

    # 테스트 환경용 (프로덕션에서는 false 권장)
    force_delete = true

    # 라이프사이클 정책
    lifecycle = {
      untagged_retention_days = 1   # untagged 이미지 1일 후 삭제
      max_image_count         = 30  # 최대 30개 이미지 유지
      cleanup_dev_images      = true
      dev_retention_days      = 14  # dev/test 이미지 14일 후 삭제
    }

    # Pull Through Cache (Docker Hub, ECR Public 캐싱)
    enable_pull_through_cache = false

    # Enhanced Scanning (AWS Inspector 연동)
    enable_enhanced_scanning = false
  }

  ############################################################################
  # ArgoCD 설정
  ############################################################################

  argocd = {
    # 기본 설정
    release_name  = "argocd"
    namespace     = "argocd"
    chart_version = "7.7.10"  # 2024년 12월 기준 최신

    # 컴포넌트 Replicas (테스트 환경: 1, 프로덕션: 2+)
    server_replicas      = 1
    controller_replicas  = 1
    repo_server_replicas = 1

    # 기능 활성화
    applicationset_enabled = true   # App of Apps 패턴 사용
    notifications_enabled  = false  # 알림 (Slack 등)
    dex_enabled            = false  # SSO

    # Server 설정 - ALB Ingress 사용 시 ClusterIP로 변경
    server_service_type = "ClusterIP"
    server_insecure     = true  # TLS termination at ALB

    # Ingress (ALB 사용)
    ingress_enabled    = true
    ingress_class_name = "alb"
    ingress_hosts      = [""]  # Host 조건 없이 ALB URL로 직접 접속 허용
    ingress_annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}]"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
    }
  }

  ############################################################################
  # 태그
  ############################################################################

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terragrunt"
  }
}
