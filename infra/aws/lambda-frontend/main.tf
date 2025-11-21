# Lambda Frontend Module - Next.js on Lambda + API Gateway
# Creates serverless Next.js hosting infrastructure

# ============================================
# Lambda Function for Next.js
# ============================================
resource "aws_lambda_function" "nextjs_frontend" {
  function_name = "${var.project_name}-nextjs-frontend"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda.handler"
  runtime       = "nodejs18.x"
  
  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
  
  memory_size = 1024
  timeout     = 30
  
  environment {
    variables = {
      NODE_ENV                            = "production"
      NEXT_PUBLIC_COGNITO_USER_POOL_ID    = var.cognito_user_pool_id
      NEXT_PUBLIC_COGNITO_CLIENT_ID       = var.cognito_client_id
      NEXT_PUBLIC_COGNITO_IDENTITY_POOL_ID = var.cognito_identity_pool_id
      NEXT_PUBLIC_API_ENDPOINT            = var.api_endpoint
    }
  }
  
  tags = var.tags
}

# Lambda function URL (alternative to API Gateway for simpler setup)
resource "aws_lambda_function_url" "nextjs" {
  function_name      = aws_lambda_function.nextjs_frontend.function_name
  authorization_type = "NONE"
  
  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 3600
  }
}

# ============================================
# IAM Role for Lambda
# ============================================
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-nextjs-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for accessing DynamoDB and S3
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.task_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.artifacts_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = var.event_bus_arn
      }
    ]
  })
}

# ============================================
# API Gateway HTTP API
# ============================================
resource "aws_apigatewayv2_api" "frontend" {
  name          = "${var.project_name}-frontend-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 3600
  }
  
  tags = var.tags
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.frontend.id
  name        = "prod"
  auto_deploy = true
  
  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
  
  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.frontend.id
  integration_type = "AWS_PROXY"
  
  integration_method = "POST"
  integration_uri    = aws_lambda_function.nextjs_frontend.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.frontend.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nextjs_frontend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.frontend.execution_arn}/*/*"
}

# ============================================
# CloudFront Distribution for Static Assets
# ============================================
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} Frontend CDN"
  default_root_object = ""
  price_class         = "PriceClass_100"
  
  origin {
    domain_name = replace(aws_apigatewayv2_api.frontend.api_endpoint, "https://", "")
    origin_id   = "api-gateway"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  origin {
    domain_name = var.static_assets_bucket_domain
    origin_id   = "s3-static"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Host"]
      
      cookies {
        forward = "all"
      }
    }
    
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }
  
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "s3-static"
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 86400
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "${var.project_name} Frontend OAI"
}

# ============================================
# S3 Bucket for Static Assets
# ============================================
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-frontend-static"
  
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_assets.arn}/*"
      }
    ]
  })
}

# ============================================
# CloudWatch Log Group
# ============================================
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.nextjs_frontend.function_name}"
  retention_in_days = 7
  
  tags = var.tags
}
