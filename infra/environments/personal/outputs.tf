# ============================================
# Outputs
# ============================================

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs for all agents"
  value       = module.ecr.repository_urls
}

# Storage Outputs
output "artifacts_bucket" {
  description = "S3 bucket for agent artifacts"
  value       = module.storage.artifacts_bucket_name
}

output "frontend_bucket" {
  description = "S3 bucket for frontend"
  value       = module.storage.frontend_bucket_name
}

output "frontend_url" {
  description = "Frontend S3 website URL"
  value       = "http://${module.storage.frontend_bucket_website_endpoint}"
}

output "tasks_table" {
  description = "DynamoDB tasks table name"
  value       = module.storage.tasks_table_name
}

output "costs_table" {
  description = "DynamoDB costs table name"
  value       = module.storage.costs_table_name
}

# Secrets Outputs
output "anthropic_secret_arn" {
  description = "Anthropic API key secret ARN"
  value       = module.secrets.anthropic_secret_arn
}
