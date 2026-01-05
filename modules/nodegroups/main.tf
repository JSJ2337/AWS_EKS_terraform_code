################################################################################
# EKS Node Groups Module
################################################################################

################################################################################
# System Node Group
################################################################################

resource "aws_eks_node_group" "system" {
  count = var.create_system_node_group ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = var.system_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.system_desired_size
    min_size     = var.system_min_size
    max_size     = var.system_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "node-type" = "system"
  }

  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "PREFER_NO_SCHEDULE"
  }

  tags = {
    Name = "${var.cluster_name}-system-node-group"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

################################################################################
# Application Node Group
################################################################################

resource "aws_eks_node_group" "application" {
  count = var.create_application_node_group ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-application"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = var.application_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.application_desired_size
    min_size     = var.application_min_size
    max_size     = var.application_max_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  labels = {
    "node-type" = "application"
  }

  tags = {
    Name = "${var.cluster_name}-application-node-group"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

################################################################################
# Spot Node Group (Cost Optimization)
################################################################################

resource "aws_eks_node_group" "spot" {
  count = var.create_spot_node_group ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-spot"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"

  scaling_config {
    desired_size = var.spot_desired_size
    min_size     = var.spot_min_size
    max_size     = var.spot_max_size
  }

  update_config {
    max_unavailable_percentage = 50
  }

  labels = {
    "node-type"     = "spot"
    "capacity-type" = "spot"
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name = "${var.cluster_name}-spot-node-group"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
