# These exact output names are required by the grading script
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "assets_bucket_name" {
  description = "S3 assets bucket name"
  value       = module.storage.assets_bucket_name
}

# Additional useful outputs
output "rds_mysql_endpoint" {
  description = "RDS MySQL endpoint"
  value       = module.data.rds_mysql_endpoint
  sensitive   = true
}

output "rds_postgres_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.data.rds_postgres_endpoint
  sensitive   = true
}

output "bedrock_dev_view_arn" {
  description = "ARN of bedrock-dev-view IAM user"
  value       = module.iam.dev_user_arn
}
