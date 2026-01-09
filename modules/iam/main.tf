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

  name = "${var.project}-eks-cluster-role-${var.environment}"

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
    Name = "${var.project}-eks-cluster-role-${var.environment}"
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

################################################################################
# Fargate Pod Execution Role
################################################################################

resource "aws_iam_role" "fargate_pod_execution" {
  count = var.create_fargate_pod_execution_role ? 1 : 0

  name = "${var.project}-fargate-pod-execution-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:fargateprofile/${var.cluster_name}/*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-fargate-pod-execution-${var.environment}"
    Role = "fargate-pod-execution"
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  count = var.create_fargate_pod_execution_role ? 1 : 0

  role       = aws_iam_role.fargate_pod_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "fargate_ecr" {
  count = var.create_fargate_pod_execution_role ? 1 : 0

  role       = aws_iam_role.fargate_pod_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

################################################################################
# GitHub Actions Role
# For GitHub Actions OIDC authentication
################################################################################

resource "aws_iam_role" "github_actions" {
  count = var.create_github_actions_role ? 1 : 0

  name = var.github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.github_repositories : "repo:${repo}:*"
            ]
          }
        }
      }
    ]
  })

  max_session_duration = var.github_actions_session_duration

  tags = merge(var.tags, {
    Name = var.github_actions_role_name
    Role = "github-actions"
  })
}

# AWS 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "github_actions_ec2" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_iam" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_eks_cluster" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "github_actions_vpc" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_dynamodb" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_eks_worker" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "github_actions_s3" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# VPC Lattice Full Access
resource "aws_iam_role_policy_attachment" "github_actions_vpc_lattice" {
  count = var.create_github_actions_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/VPCLatticeFullAccess"
}

# Custom Inline Policy
resource "aws_iam_role_policy" "github_actions_custom" {
  count = var.create_github_actions_role ? 1 : 0

  name = "${var.github_actions_role_name}-custom"
  role = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecurityGroupManagement"
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:Describe*",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Sid      = "EKSFullAccess"
        Effect   = "Allow"
        Action   = "eks:*"
        Resource = "*"
      },
      {
        Sid      = "IAMPassRoleEKS"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "eks.amazonaws.com"
          }
        }
      },
      {
        Sid      = "IAMCreateServiceLinkedRoleEKS"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "arn:aws:iam::*:role/aws-service-role/eks.amazonaws.com/*"
        Condition = {
          "ForAnyValue:StringEquals" = {
            "iam:AWSServiceName" = "eks"
          }
        }
      },
      {
        Sid      = "IAMPassRoleRDSMonitoring"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::*:role/*monitoring*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "monitoring.rds.amazonaws.com"
          }
        }
      },
      {
        Sid    = "KMSManagement"
        Effect = "Allow"
        Action = [
          "kms:EnableKeyRotation",
          "kms:PutKeyPolicy",
          "kms:GetKeyPolicy",
          "kms:ListResourceTags",
          "kms:ListGrants",
          "kms:UpdateAlias",
          "kms:TagResource",
          "kms:GetKeyRotationStatus",
          "kms:ScheduleKeyDeletion",
          "kms:ListAliases",
          "kms:RevokeGrant",
          "kms:CreateAlias",
          "kms:DescribeKey",
          "kms:CreateKey",
          "kms:DeleteAlias",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsManagement"
        Effect = "Allow"
        Action = [
          "logs:ListTagsLogGroup",
          "logs:TagLogGroup",
          "logs:DescribeLogGroups",
          "logs:DeleteLogGroup",
          "logs:UntagResource",
          "logs:TagResource",
          "logs:PutRetentionPolicy",
          "logs:CreateLogGroup",
          "logs:ListTagsForResource",
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DeleteResourcePolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSManagement"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBEngineVersions",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBParameterGroups",
          "rds:CreateDBSubnetGroup",
          "rds:ModifyDBParameterGroup",
          "rds:CreateDBInstance",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:ModifyDBClusterParameterGroup",
          "rds:DescribeDBParameters",
          "rds:DeleteDBCluster",
          "rds:DeleteDBInstance",
          "rds:AddTagsToResource",
          "rds:DescribeDBClusterParameters",
          "rds:CreateDBParameterGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:ListTagsForResource",
          "rds:CreateDBCluster",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:ModifyDBCluster",
          "rds:DeleteDBParameterGroup",
          "rds:CreateDBClusterParameterGroup",
          "rds:DeleteDBClusterParameterGroup",
          "rds:RemoveTagsFromResource",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeGlobalClusters"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManagerManagement"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:UntagResource",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:TagResource",
          "secretsmanager:UpdateSecret"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRFullAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:ListImages",
          "ecr:DeleteRepositoryPolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:ListTagsForResource",
          "ecr:PutImageTagMutability",
          "ecr:PutImageScanningConfiguration",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })
}
