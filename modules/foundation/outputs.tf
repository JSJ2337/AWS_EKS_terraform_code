################################################################################
# Outputs
################################################################################

output "kms_key_arn" {
  description = "KMS key ARN for EKS encryption"
  value       = var.enable_kms ? aws_kms_key.eks[0].arn : null
}

output "kms_key_id" {
  description = "KMS key ID for EKS encryption"
  value       = var.enable_kms ? aws_kms_key.eks[0].key_id : null
}

output "eks_admin_role_arn" {
  description = "EKS admin IAM role ARN"
  value       = var.create_eks_admin_role ? aws_iam_role.eks_admin[0].arn : null
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}
