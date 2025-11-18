# Storage Module Outputs

output "artifacts_bucket_name" {
  description = "S3 bucket name for agent artifacts"
  value       = aws_s3_bucket.artifacts.id
}

output "artifacts_bucket_arn" {
  description = "S3 bucket ARN for agent artifacts"
  value       = aws_s3_bucket.artifacts.arn
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "S3 bucket ARN for frontend"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_website_endpoint" {
  description = "S3 bucket website endpoint"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "tasks_table_name" {
  description = "DynamoDB table name for tasks"
  value       = aws_dynamodb_table.tasks.name
}

output "tasks_table_arn" {
  description = "DynamoDB table ARN for tasks"
  value       = aws_dynamodb_table.tasks.arn
}

output "costs_table_name" {
  description = "DynamoDB table name for cost tracking"
  value       = aws_dynamodb_table.costs.name
}

output "costs_table_arn" {
  description = "DynamoDB table ARN for cost tracking"
  value       = aws_dynamodb_table.costs.arn
}
