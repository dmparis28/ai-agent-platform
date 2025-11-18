# ECR Module Variables

variable "project_name" {
  description = "Project name for ECR repository naming"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
