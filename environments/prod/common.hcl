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
  project = "eks-prod"

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
  single_nat_gateway = false

  # VPC Flow Logs 활성화
  enable_flow_logs = true

  # Pod 전용 서브넷 활성화
  enable_pod_subnets = true

  ############################################################################
  # EKS 노드 그룹 설정
  ############################################################################

  # System Node Group (CoreDNS, kube-proxy 등)
  system_node_group = {
    instance_types = ["m6i.large"]
    desired_size   = 2
    min_size       = 2
    max_size       = 4
  }

  # Application Node Group
  application_node_group = {
    instance_types = ["m6i.xlarge"]
    desired_size   = 2
    min_size       = 2
    max_size       = 10
  }

  # Spot Node Group (비용 최적화, 선택적)
  spot_node_group = {
    enabled        = false
    instance_types = ["m6i.xlarge", "m5.xlarge", "m5a.xlarge"]
    desired_size   = 2
    min_size       = 0
    max_size       = 10
  }

  ############################################################################
  # EKS Add-ons 설정
  ############################################################################

  addons = {
    enable_ebs_csi            = true
    enable_pod_identity       = true
    enable_aws_lb_controller  = true
    enable_cluster_autoscaler = true
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
  # 태그
  ############################################################################

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terragrunt"
  }
}
