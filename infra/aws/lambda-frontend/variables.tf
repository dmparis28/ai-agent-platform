# Lambda Frontend Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "lambda_package_path" {
  description = "Path to Lambda deployment package (lambda.zip)"
  type        = string
  default     = "../../../fe/dist/lambda.zip"
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID"
  type        = string
}

variable "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  type        = string
}

variable "api_endpoint" {
  description = "API Gateway endpoint for backend"
  type        = string
}

variable "task_table_arn" {
  description = "DynamoDB tasks table ARN"
  type        = string
}

variable "artifacts_bucket_arn" {
  description = "S3 artifacts bucket ARN"
  type        = string
}

variable "static_assets_bucket_domain" {
  description = "S3 static assets bucket domain name"
  type        = string
}

variable "event_bus_arn" {
  description = "EventBridge event bus ARN"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
