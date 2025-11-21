# Lambda Frontend Module Outputs

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.nextjs_frontend.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.nextjs_frontend.function_name
}

output "lambda_function_url" {
  description = "Lambda function URL (direct access)"
  value       = aws_lambda_function_url.nextjs.function_url
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.frontend.api_endpoint
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.frontend.id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "static_assets_bucket" {
  description = "S3 bucket name for static assets"
  value       = aws_s3_bucket.static_assets.bucket
}

output "frontend_url" {
  description = "Frontend URL (CloudFront)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}
