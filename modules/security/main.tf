################################################################################
# Security Module
# Security Groups, IAM Roles for EKS
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

resource "aws_security_group_rule" "eks_cluster_ingress_nodes" {
  description              = "Allow nodes to communicate with cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "eks_cluster_egress" {
  description       = "Allow cluster to communicate with nodes"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
}

################################################################################
# EKS Node Security Group
################################################################################

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project}-eks-nodes-sg-${var.environment}"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name                                        = "${var.project}-eks-nodes-sg-${var.environment}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "eks_nodes_ingress_self" {
  description              = "Allow nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "eks_nodes_ingress_cluster" {
  description              = "Allow cluster to communicate with nodes"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "eks_nodes_ingress_cluster_https" {
  description              = "Allow cluster API to communicate with nodes (webhooks)"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "eks_nodes_egress" {
  description       = "Allow nodes outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
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
  description              = "Allow traffic to nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "eks_nodes_ingress_alb" {
  description              = "Allow ALB to communicate with nodes"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
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

resource "aws_security_group_rule" "rds_ingress_nodes" {
  description              = "Allow nodes to access RDS"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.eks_nodes.id
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

resource "aws_security_group_rule" "elasticache_ingress_nodes" {
  description              = "Allow nodes to access ElastiCache"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elasticache.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

################################################################################
# EKS Cluster IAM Role (optional - prefer using IAM module)
################################################################################

resource "aws_iam_role" "eks_cluster" {
  count = var.create_iam_roles ? 1 : 0

  name = "${var.project}-eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = var.create_iam_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count = var.create_iam_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster[0].name
}

################################################################################
# EKS Node Group IAM Role (optional - prefer using IAM module)
################################################################################

resource "aws_iam_role" "eks_nodes" {
  count = var.create_iam_roles ? 1 : 0

  name = "${var.project}-eks-nodes-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count = var.create_iam_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count = var.create_iam_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  count = var.create_iam_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes[0].name
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  count = var.create_iam_roles ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_nodes[0].name
}

################################################################################
# EKS Node Instance Profile
################################################################################

locals {
  # Use external role name if provided, otherwise use internally created role
  eks_node_role_name = var.create_iam_roles ? aws_iam_role.eks_nodes[0].name : var.eks_node_role_name
}

resource "aws_iam_instance_profile" "eks_nodes" {
  name = "${var.project}-eks-nodes-profile-${var.environment}"
  role = local.eks_node_role_name
}
