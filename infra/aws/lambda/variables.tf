# infra/aws/lambda/variables.tf

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "h100_private_ip" {
  description = "H100 instance private IP"
  type        = string
}

variable "h100_instance_id" {
  description = "H100 instance ID"
  type        = string
}

variable "artifacts_bucket_name" {
  description = "S3 bucket name for artifacts"
  type        = string
}

variable "artifacts_bucket_arn" {
  description = "S3 bucket ARN for artifacts"
  type        = string
}

variable "anthropic_secret_name" {
  description = "Secrets Manager secret name for Anthropic API key"
  type        = string
}

variable "anthropic_secret_arn" {
  description = "Secrets Manager secret ARN for Anthropic API key"
  type        = string
}

variable "task_table_name" {
  description = "DynamoDB table name for task state"
  type        = string
}

variable "task_table_arn" {
  description = "DynamoDB table ARN for task state"
  type        = string
}

variable "lambda_packages_dir" {
  description = "Directory containing Lambda deployment packages"
  type        = string
  default     = "./lambda_packages"
}

variable "dependencies_layer_path" {
  description = "Path to Lambda layer zip with dependencies"
  type        = string
  default     = "./lambda_packages/dependencies_layer.zip"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
