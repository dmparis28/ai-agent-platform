# H100 Module Variables

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for H100"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "snapshot_bucket" {
  description = "S3 bucket for H100 snapshots"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "h100_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "p4d.24xlarge"
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 1800
}

variable "idle_shutdown_topic_arn" {
  description = "SNS topic ARN for idle shutdown notifications"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
