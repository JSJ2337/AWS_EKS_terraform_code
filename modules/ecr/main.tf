################################################################################
# Amazon ECR Module
# Best Practices: https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-best-practices.html
################################################################################

################################################################################
# ECR Repositories
################################################################################

resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = "${var.project}-${each.key}"
  image_tag_mutability = each.value.image_tag_mutability

  # 이미지 스캔 설정 (취약점 자동 스캔)
  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  # KMS 암호화 설정
  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  # Force delete (테스트 환경용, 프로덕션에서는 false 권장)
  force_delete = var.force_delete

  tags = merge(var.tags, {
    Name = "${var.project}-${each.key}"
  })
}

################################################################################
# ECR Lifecycle Policies
# 오래된/미사용 이미지 자동 정리
################################################################################

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.repositories

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = concat(
      # 규칙 1: untagged 이미지 정리 (기본 1일)
      [{
        rulePriority = 1
        description  = "Remove untagged images after ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = {
          type = "expire"
        }
      }],
      # 규칙 2: 태그된 이미지 최대 개수 유지
      [{
        rulePriority = 2
        description  = "Keep only ${var.max_image_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release", "prod", "staging"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }],
      # 규칙 3: dev/test 이미지 빠른 정리
      var.cleanup_dev_images ? [{
        rulePriority = 3
        description  = "Remove dev/test images after ${var.dev_image_retention_days} days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "test", "feature", "pr"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = var.dev_image_retention_days
        }
        action = {
          type = "expire"
        }
      }] : []
    )
  })
}

################################################################################
# ECR Repository Policy (Cross-account access if needed)
################################################################################

resource "aws_ecr_repository_policy" "this" {
  for_each = var.create_repository_policy ? var.repositories : {}

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.pull_access_principal_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowPush"
        Effect = "Allow"
        Principal = {
          AWS = var.push_access_principal_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

################################################################################
# ECR Pull Through Cache (Public 이미지 캐싱)
# Docker Hub, ECR Public 등에서 pull 시 자동 캐싱
################################################################################

resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  count = var.enable_pull_through_cache ? 1 : 0

  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  count = var.enable_pull_through_cache && var.docker_hub_secret_arn != null ? 1 : 0

  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = var.docker_hub_secret_arn
}

################################################################################
# ECR Registry Scanning Configuration
# Enhanced Scanning (Inspector integration)
################################################################################

resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.enable_enhanced_scanning ? 1 : 0

  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
