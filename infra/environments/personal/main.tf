# AI Agent Platform - Personal Environment Main Configuration
# This file orchestrates all infrastructure modules

# ============================================
# Local Variables
# ============================================
locals {
  cluster_name = var.cluster_name
  
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = "ai-agent-platform"
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
# Outputs for use by other modules
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

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}
