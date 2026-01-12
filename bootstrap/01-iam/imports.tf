################################################################################
# Import Blocks for Existing Resources
# 기존 리소스를 Terraform 관리로 가져오기 위한 import 블록
#
# 사용법:
# 1. terraform init
# 2. terraform plan (import 대상 확인)
# 3. terraform apply (import 실행)
################################################################################

# GitHub Actions Role
import {
  to = module.iam.aws_iam_role.github_actions[0]
  id = "jsj_github_action_EKS"
}

# GitHub Actions - EC2 Full Access
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_ec2[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# GitHub Actions - IAM Full Access
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_iam[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/IAMFullAccess"
}

# GitHub Actions - EKS Cluster Policy
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_eks_cluster[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# GitHub Actions - VPC Full Access
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_vpc[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# GitHub Actions - DynamoDB Full Access
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_dynamodb[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# GitHub Actions - EKS Worker Node Policy
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_eks_worker[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# GitHub Actions - S3 Full Access
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_s3[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# GitHub Actions - VPC Lattice Full Access
import {
  to = module.iam.aws_iam_role_policy_attachment.github_actions_vpc_lattice[0]
  id = "jsj_github_action_EKS/arn:aws:iam::aws:policy/VPCLatticeFullAccess"
}

# GitHub Actions - Custom Inline Policy
import {
  to = module.iam.aws_iam_role_policy.github_actions_custom[0]
  id = "jsj_github_action_EKS:jsj_github_action_EKS-custom"
}

################################################################################
# EKS Admin Role (존재하는 경우만 주석 해제)
################################################################################

# import {
#   to = module.iam.aws_iam_role.eks_admin[0]
#   id = "jsj-eks-eks-admin-prod"
# }

################################################################################
# EKS Cluster Role (존재하는 경우만 주석 해제)
################################################################################

# import {
#   to = module.iam.aws_iam_role.eks_cluster[0]
#   id = "jsj-eks-eks-cluster-role-prod"
# }

################################################################################
# VPC Flow Logs Role (존재하는 경우만 주석 해제)
################################################################################

# import {
#   to = module.iam.aws_iam_role.flow_logs[0]
#   id = "jsj-eks-vpc-flow-logs-prod"
# }

################################################################################
# RDS Monitoring Role (존재하는 경우만 주석 해제)
################################################################################

# import {
#   to = module.iam.aws_iam_role.rds_monitoring[0]
#   id = "jsj-eks-rds-monitoring-prod"
# }

################################################################################
# Fargate Pod Execution Role (존재하는 경우만 주석 해제)
################################################################################

# import {
#   to = module.iam.aws_iam_role.fargate_pod_execution[0]
#   id = "jsj-eks-fargate-pod-execution-prod"
# }
