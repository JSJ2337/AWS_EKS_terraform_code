################################################################################
# Security Module
# Security Groups for EKS Fargate
################################################################################

################################################################################
# EKS Cluster Security Group
################################################################################

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-eks-cluster-sg-${var.environment}"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-eks-cluster-sg-${var.environment}"
  })
}

resource "aws_security_group_rule" "eks_cluster_ingress_pods" {
  description              = "Allow pods to communicate with cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_pods.id
}

resource "aws_security_group_rule" "eks_cluster_egress" {
  description       = "Allow cluster to communicate with pods"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
}

################################################################################
# EKS Pods Security Group (Fargate)
################################################################################

resource "aws_security_group" "eks_pods" {
  name        = "${var.project}-eks-pods-sg-${var.environment}"
  description = "Security group for EKS Fargate pods"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name                                        = "${var.project}-eks-pods-sg-${var.environment}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "eks_pods_ingress_self" {
  description              = "Allow pods to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_pods.id
  source_security_group_id = aws_security_group.eks_pods.id
}

resource "aws_security_group_rule" "eks_pods_ingress_cluster" {
  description              = "Allow cluster to communicate with pods"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_pods.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "eks_pods_ingress_cluster_https" {
  description              = "Allow cluster API to communicate with pods (webhooks)"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_pods.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "eks_pods_egress" {
  description       = "Allow pods outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_pods.id
  cidr_blocks       = ["0.0.0.0/0"]
}

################################################################################
# ALB Security Group
################################################################################

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-alb-sg-${var.environment}"
  })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  description       = "Allow HTTP traffic"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  description       = "Allow HTTPS traffic"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress" {
  description              = "Allow traffic to pods"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_pods.id
}

resource "aws_security_group_rule" "eks_pods_ingress_alb" {
  description              = "Allow ALB to communicate with pods"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_pods.id
  source_security_group_id = aws_security_group.alb.id
}

################################################################################
# RDS Security Group
################################################################################

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg-${var.environment}"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-rds-sg-${var.environment}"
  })
}

resource "aws_security_group_rule" "rds_ingress_pods" {
  description              = "Allow pods to access RDS"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.eks_pods.id
}

################################################################################
# ElastiCache Security Group
################################################################################

resource "aws_security_group" "elasticache" {
  name        = "${var.project}-elasticache-sg-${var.environment}"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-elasticache-sg-${var.environment}"
  })
}

resource "aws_security_group_rule" "elasticache_ingress_pods" {
  description              = "Allow pods to access ElastiCache"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elasticache.id
  source_security_group_id = aws_security_group.eks_pods.id
}
