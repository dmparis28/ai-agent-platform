# AI Agent Platform - Personal Environment Main Configuration
# This file orchestrates all infrastructure modules

# ============================================
# Local Variables
# ============================================
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

  # NAT Gateway configuration (cost optimized)
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # VPC Endpoints
  enable_s3_endpoint   = var.enable_s3_endpoint
  enable_ecr_endpoints = var.enable_ecr_api_endpoint && var.enable_ecr_dkr_endpoint

  tags = local.common_tags
}

# ============================================
# EKS Cluster Module
# ============================================
module "eks" {
  source = "../../aws/eks"

  cluster_name          = var.cluster_name
  cluster_version       = var.cluster_version
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets

  # Node groups
  cpu_node_group        = var.cpu_node_group
  medium_gpu_node_group = var.medium_gpu_node_group
  high_gpu_node_group   = var.high_gpu_node_group

  tags = local.common_tags

  depends_on = [module.vpc]
}

# ============================================
# ECR Module (Container Registry)
# ============================================
module "ecr" {
  source = "../../aws/ecr"

  project_name = local.project_name
  tags         = local.common_tags
}

# ============================================
# Storage Module (S3 + DynamoDB)
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

