# EKS Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS"
  type        = list(string)
}

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

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
