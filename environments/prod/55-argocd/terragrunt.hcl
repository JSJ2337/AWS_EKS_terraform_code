################################################################################
# ArgoCD Layer
# Terraform Helm Provider를 사용하여 ArgoCD 설치
################################################################################

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "${get_terragrunt_dir()}/../../../modules/argocd"
}

# EKS 클러스터 의존성
dependency "eks_cluster" {
  config_path = "../30-eks-cluster"

  mock_outputs = {
    cluster_name              = "mock-cluster"
    cluster_endpoint          = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "bW9jay1jZXJ0LWRhdGE="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# Node Group 의존성 (노드가 있어야 ArgoCD 배포 가능)
dependency "nodegroups" {
  config_path = "../40-nodegroups"

  mock_outputs = {
    system_node_group_name = "mock-system-ng"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# Helm/Kubernetes Provider 생성
generate "k8s_provider" {
  path      = "k8s_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_eks_cluster_auth" "cluster" {
  name = "${dependency.eks_cluster.outputs.cluster_name}"
}

provider "kubernetes" {
  host                   = "${dependency.eks_cluster.outputs.cluster_endpoint}"
  cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.cluster_certificate_authority_data}")
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = "${dependency.eks_cluster.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.cluster_certificate_authority_data}")
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
EOF
}

inputs = {
  # General
  release_name     = local.common.locals.argocd.release_name
  namespace        = local.common.locals.argocd.namespace
  create_namespace = true
  chart_version    = local.common.locals.argocd.chart_version

  # Replicas
  server_replicas      = local.common.locals.argocd.server_replicas
  controller_replicas  = local.common.locals.argocd.controller_replicas
  repo_server_replicas = local.common.locals.argocd.repo_server_replicas

  # Features
  applicationset_enabled = local.common.locals.argocd.applicationset_enabled
  notifications_enabled  = local.common.locals.argocd.notifications_enabled
  dex_enabled            = local.common.locals.argocd.dex_enabled

  # Server
  server_service_type = local.common.locals.argocd.server_service_type
  server_insecure     = local.common.locals.argocd.server_insecure

  # Ingress (optional)
  ingress_enabled = local.common.locals.argocd.ingress_enabled

  # Tags
  tags = local.common.locals.common_tags
}
