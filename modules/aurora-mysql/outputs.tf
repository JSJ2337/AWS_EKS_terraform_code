################################################################################
# Aurora MySQL Outputs
################################################################################

output "cluster_id" {
  description = "Aurora cluster ID"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.this.master_username
}

output "security_group_id" {
  description = "Aurora security group ID"
  value       = aws_security_group.aurora.id
}

output "subnet_group_name" {
  description = "Aurora subnet group name"
  value       = aws_db_subnet_group.aurora.name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN containing credentials"
  value       = aws_secretsmanager_secret.aurora.arn
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.aurora.name
}

output "instance_endpoints" {
  description = "Map of instance endpoints"
  value = {
    for k, v in aws_rds_cluster_instance.this : k => v.endpoint
  }
}

output "instance_identifiers" {
  description = "Map of instance identifiers"
  value = {
    for k, v in aws_rds_cluster_instance.this : k => v.identifier
  }
}
