################################################################################
# IAM Module
# Centralized IAM roles and policies for EKS infrastructure
################################################################################

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# EKS Admin Role
# For administrators to manage EKS cluster
################################################################################

resource "aws_iam_role" "eks_admin" {
  count = var.create_eks_admin_role ? 1 : 0

  name = "${var.project}-eks-admin-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = var.eks_admin_require_mfa ? {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        } : null
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-eks-admin-${var.environment}"
    Role = "eks-admin"
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin" {
  count = var.create_eks_admin_role ? 1 : 0

  role       = aws_iam_role.eks_admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

################################################################################
# EKS Cluster Role
# For EKS control plane
################################################################################

resource "aws_iam_role" "eks_cluster" {
  count = var.create_eks_cluster_role ? 1 : 0

  name = "${var.project}-eks-cluster-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-eks-cluster-${var.environment}"
    Role = "eks-cluster"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = var.create_eks_cluster_role ? 1 : 0

  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count = var.create_eks_cluster_role ? 1 : 0

  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

################################################################################
# EKS Node Role
# For EKS worker nodes
################################################################################

resource "aws_iam_role" "eks_nodes" {
  count = var.create_eks_node_role ? 1 : 0

  name = "${var.project}-eks-nodes-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-eks-nodes-${var.environment}"
    Role = "eks-nodes"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count = var.create_eks_node_role ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count = var.create_eks_node_role ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  count = var.create_eks_node_role ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  count = var.create_eks_node_role && var.enable_ssm_for_nodes ? 1 : 0

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
# VPC Flow Logs Role
################################################################################

resource "aws_iam_role" "flow_logs" {
  count = var.create_flow_logs_role ? 1 : 0

  name = "${var.project}-vpc-flow-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-vpc-flow-logs-${var.environment}"
    Role = "vpc-flow-logs"
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.create_flow_logs_role ? 1 : 0

  name = "${var.project}-vpc-flow-logs-${var.environment}"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

################################################################################
# RDS Enhanced Monitoring Role
################################################################################

resource "aws_iam_role" "rds_monitoring" {
  count = var.create_rds_monitoring_role ? 1 : 0

  name = "${var.project}-rds-monitoring-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-rds-monitoring-${var.environment}"
    Role = "rds-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.create_rds_monitoring_role ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
