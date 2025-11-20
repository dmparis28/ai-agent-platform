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
# Monitoring & Alerts (Required by H100)
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
# Lambda + H100 Architecture
# ============================================

module "h100" {
  source = "../../aws/h100"
  count  = var.enable_h100 ? 1 : 0

  vpc_id                  = module.vpc.vpc_id
  private_subnet_id       = module.vpc.private_subnets[0]
  vpc_cidr                = var.vpc_cidr
  snapshot_bucket         = module.storage.artifacts_bucket_name
  aws_region              = var.aws_region
  h100_instance_type      = var.h100_instance_type
  idle_timeout            = var.h100_idle_timeout
  idle_shutdown_topic_arn = aws_sns_topic.alerts.arn

  tags = local.common_tags

  depends_on = [module.vpc, module.storage, aws_sns_topic.alerts]
}

module "lambda_agents" {
  source = "../../aws/lambda"
  count  = var.enable_lambda ? 1 : 0

  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnets
  vpc_cidr                = var.vpc_cidr
  h100_private_ip         = var.enable_h100 ? module.h100[0].h100_private_ip : ""
  h100_instance_id        = var.enable_h100 ? module.h100[0].h100_instance_id : ""
  artifacts_bucket_name   = module.storage.artifacts_bucket_name
  artifacts_bucket_arn    = module.storage.artifacts_bucket_arn
  anthropic_secret_name   = var.anthropic_secret_name
  anthropic_secret_arn    = module.secrets.anthropic_secret_arn
  task_table_name         = module.storage.tasks_table_name
  task_table_arn          = module.storage.tasks_table_arn
  lambda_packages_dir     = var.lambda_packages_dir
  dependencies_layer_path = var.dependencies_layer_path

  tags = local.common_tags

  depends_on = [module.vpc, module.storage, module.secrets]
}

module "cognito" {
  source = "../../aws/cognito"
  count  = var.enable_lambda ? 1 : 0

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
