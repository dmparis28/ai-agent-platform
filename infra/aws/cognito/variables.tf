variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "cognito_domain" {
  description = "Cognito domain prefix (must be globally unique)"
  type        = string
}

variable "callback_urls" {
  description = "List of callback URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of logout URLs"
  type        = list(string)
  default     = ["http://localhost:3000/"]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
