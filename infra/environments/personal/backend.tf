# Terraform Backend Configuration
# Stores state in S3 with DynamoDB locking for safety

terraform {
  backend "s3" {
    # S3 bucket for state storage (created by init-terraform.ps1)
    bucket = "ai-agent-platform-terraform-state"
    key    = "personal/terraform.tfstate"
    region = "us-east-1"
    
    # DynamoDB table for state locking (prevents concurrent modifications)
    dynamodb_table = "ai-agent-platform-terraform-locks"
    
    # Enable encryption at rest
    encrypt = true
  }
  
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "ai-agent-platform"
      ManagedBy   = "terraform"
      CostCenter  = "personal"
    }
  }
}

# Data source to get current AWS account info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}