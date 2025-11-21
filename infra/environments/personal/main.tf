locals {
  cluster_name = var.cluster_name
  project_name = "ai-agent-platform"
  
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = local.project_name
      ManagedBy   = "terraform"
    }
  )
}

# ============================================
# VPC Module
# ============================================

module "vpc" {
  source = "../../aws/vpc"

  vpc_name           = "${var.cluster_name}-vpc"
  vpc_cidr           = var.vpc_cidr
  aws_region         = var.aws_region
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  cluster_name       = var.cluster_name

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_s3_endpoint   = var.enable_s3_endpoint
  enable_ecr_endpoints = var.enable_ecr_api_endpoint && var.enable_ecr_dkr_endpoint

  tags = local.common_tags
}

# ============================================
# Storage Module
# ============================================

module "storage" {
  source = "../../aws/storage"

  project_name = local.project_name
  tags         = local.common_tags
}

# ============================================
# Secrets Module
# ============================================

module "secrets" {
  source = "../../aws/secrets"

  anthropic_secret_name = var.anthropic_secret_name
  tags                  = local.common_tags
}

# ============================================
# Monitoring & Alerts
# ============================================

resource "aws_sns_topic" "alerts" {
  name = "${local.project_name}-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================
# Cognito Authentication
# ============================================

module "cognito" {
  source = "../../aws/cognito"
  count  = var.enable_lambda_frontend ? 1 : 0

  cognito_domain       = var.cognito_domain
  callback_urls        = var.cognito_callback_urls
  logout_urls          = var.cognito_logout_urls
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  artifacts_bucket_arn = module.storage.artifacts_bucket_arn
  aws_region           = var.aws_region

  tags = local.common_tags

  depends_on = [module.storage]
}

# ============================================
# Lambda Frontend (Next.js)
# ============================================

module "lambda_frontend" {
  source = "../../aws/lambda-frontend"
  count  = var.enable_lambda_frontend ? 1 : 0
  
  project_name                 = local.project_name
  lambda_package_path          = "../../../fe/lambda.zip"
  cognito_user_pool_id         = module.cognito[0].user_pool_id
  cognito_client_id            = module.cognito[0].app_client_id
  cognito_identity_pool_id     = module.cognito[0].identity_pool_id
  api_endpoint                 = "https://placeholder.execute-api.us-east-1.amazonaws.com"
  task_table_arn               = module.storage.tasks_table_arn
  artifacts_bucket_arn         = module.storage.artifacts_bucket_arn
  static_assets_bucket_domain  = "${module.storage.artifacts_bucket_name}.s3.amazonaws.com"
  event_bus_arn                = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
  
  tags = local.common_tags
  
  depends_on = [module.cognito, module.storage]
}

# ============================================
# Data Sources
# ============================================

data "aws_caller_identity" "current" {}
