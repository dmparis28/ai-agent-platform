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
# Cognito Outputs
# ============================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = var.enable_lambda_frontend ? module.cognito[0].user_pool_id : null
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID"
  value       = var.enable_lambda_frontend ? module.cognito[0].app_client_id : null
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = var.enable_lambda_frontend ? module.cognito[0].identity_pool_id : null
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = var.enable_lambda_frontend ? module.cognito[0].cognito_domain : null
}

# ============================================
# Lambda Frontend Outputs
# ============================================

output "lambda_frontend_url" {
  description = "Lambda function URL (direct access)"
  value       = var.enable_lambda_frontend ? module.lambda_frontend[0].lambda_function_url : null
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = var.enable_lambda_frontend ? module.lambda_frontend[0].lambda_function_name : null
}

output "api_gateway_url" {
  description = "API Gateway endpoint (use this for production)"
  value       = var.enable_lambda_frontend ? module.lambda_frontend[0].api_gateway_endpoint : null
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = var.enable_lambda_frontend ? module.lambda_frontend[0].api_gateway_id : null
}

output "frontend_url" {
  description = "Frontend URL (API Gateway - use this one!)"
  value       = var.enable_lambda_frontend ? module.lambda_frontend[0].frontend_url : null
}

# ============================================
# Monitoring Outputs
# ============================================

output "alerts_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}
