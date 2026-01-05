################################################################################
# Outputs
################################################################################

output "vpc_cni_addon_id" {
  description = "VPC CNI add-on ID"
  value       = aws_eks_addon.vpc_cni.id
}

output "coredns_addon_id" {
  description = "CoreDNS add-on ID"
  value       = aws_eks_addon.coredns.id
}

output "kube_proxy_addon_id" {
  description = "kube-proxy add-on ID"
  value       = aws_eks_addon.kube_proxy.id
}

output "ebs_csi_addon_id" {
  description = "EBS CSI driver add-on ID"
  value       = var.enable_ebs_csi ? aws_eks_addon.ebs_csi[0].id : null
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = var.enable_ebs_csi ? aws_iam_role.ebs_csi[0].arn : null
}

output "aws_lb_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = var.enable_aws_lb_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler IAM role ARN"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}
