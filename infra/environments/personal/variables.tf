# Variable Declarations for Personal Environment

# ============================================
# Basic Configuration
# ============================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "personal"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# ============================================
# Node Group Variables
# ============================================

variable "cpu_node_group" {
  description = "CPU node group configuration"
  type = object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
    capacity_type = string
  })
}

variable "medium_gpu_node_group" {
  description = "Medium GPU node group configuration"
  type = object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
    capacity_type = string
  })
}

variable "high_gpu_node_group" {
  description = "High GPU node group configuration"
  type = object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
    capacity_type = string
  })
}

# ============================================
# Networking Variables
# ============================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost optimization)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "One NAT Gateway per AZ"
  type        = bool
  default     = false
}

# VPC Endpoints
variable "enable_s3_endpoint" {
  description = "Enable S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_api_endpoint" {
  description = "Enable ECR API VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_dkr_endpoint" {
  description = "Enable ECR DKR VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_sts_endpoint" {
  description = "Enable STS VPC endpoint"
  type        = bool
  default     = false
}

# ============================================
# Budget and Cost Control
# ============================================

variable "daily_budget_limit" {
  description = "Daily spending limit in USD"
  type        = number
}

variable "monthly_budget_limit" {
  description = "Monthly spending limit in USD"
  type        = number
}

variable "kill_switch_hourly_threshold" {
  description = "Hourly rate threshold for kill switch in USD"
  type        = number
}

variable "enable_nightly_cleanup" {
  description = "Enable nightly cleanup of zombie resources"
  type        = bool
  default     = true
}

variable "cleanup_schedule" {
  description = "Cron schedule for nightly cleanup"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

# ============================================
# Secrets
# ============================================

variable "anthropic_secret_name" {
  description = "Name of Anthropic API key secret in Secrets Manager"
  type        = string
}

variable "firebase_secret_name" {
  description = "Name of Firebase config secret in Secrets Manager"
  type        = string
}

# ============================================
# Monitoring
# ============================================

variable "alert_email" {
  description = "Email address for budget and monitoring alerts"
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ============================================
# Autoscaling
# ============================================

variable "enable_cluster_autoscaler" {
  description = "Enable Kubernetes cluster autoscaler"
  type        = bool
  default     = true
}

variable "scale_down_delay_after_add" {
  description = "Time to wait after scale up before considering scale down"
  type        = string
  default     = "30s"
}

variable "scale_down_unneeded_time" {
  description = "Time a node must be idle before scaling down"
  type        = string
  default     = "30s"
}

variable "scale_down_utilization_threshold" {
  description = "Node utilization threshold for scale down"
  type        = number
  default     = 0.5
}

# ============================================
# Tags
# ============================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}