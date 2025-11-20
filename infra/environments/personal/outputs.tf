# ============================================
# VPC Outputs
# ============================================

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

# ============================================
# Storage Outputs
# ============================================

output "artifacts_bucket" {
  description = "S3 bucket for agent artifacts"
  value       = module.storage.artifacts_bucket_name
}

output "frontend_bucket" {
  description = "S3 bucket for frontend"
  value       = module.storage.frontend_bucket_name
}

output "tasks_table" {
  description = "DynamoDB tasks table name"
  value       = module.storage.tasks_table_name
}

output "costs_table" {
  description = "DynamoDB costs table name"
  value       = module.storage.costs_table_name
}

# ============================================
# Secrets Outputs
# ============================================

output "anthropic_secret_arn" {
  description = "Anthropic API key secret ARN"
  value       = module.secrets.anthropic_secret_arn
  sensitive   = true
}

# ============================================
# H100 Outputs
# ============================================

output "h100_instance_id" {
  description = "H100 GPU instance ID"
  value       = var.enable_h100 ? module.h100[0].h100_instance_id : null
}

output "h100_private_ip" {
  description = "H100 private IP address"
  value       = var.enable_h100 ? module.h100[0].h100_private_ip : null
}

# ============================================
# Lambda Outputs
# ============================================

output "lambda_function_arns" {
  description = "ARNs of all Lambda agent functions"
  value       = var.enable_lambda ? module.lambda_agents[0].agent_function_arns : {}
}

output "event_bus_arn" {
  description = "EventBridge event bus ARN"
  value       = var.enable_lambda ? module.lambda_agents[0].event_bus_arn : null
}

# ============================================
# Cognito Outputs
# ============================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = var.enable_lambda ? module.cognito[0].user_pool_id : null
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID"
  value       = var.enable_lambda ? module.cognito[0].app_client_id : null
}

output "cognito_auth_url" {
  description = "Cognito authorization URL"
  value       = var.enable_lambda ? module.cognito[0].auth_url : null
}

# ============================================
# Monitoring Outputs
# ============================================

output "alerts_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}
