# Cognito Module - Placeholder
# This module is not yet implemented

# When implemented, this will create:
# - Cognito User Pool
# - User Pool Client
# - Identity Pool
# - IAM roles for authenticated users
# - Google identity provider integration

# For now, create dummy outputs to prevent errors
output "user_pool_id" {
  description = "Cognito User Pool ID (not implemented)"
  value       = "us-east-1_NOTIMPL"
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN (not implemented)"
  value       = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_NOTIMPL"
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint (not implemented)"
  value       = "cognito-idp.us-east-1.amazonaws.com/us-east-1_NOTIMPL"
}

output "app_client_id" {
  description = "Cognito App Client ID (not implemented)"
  value       = "notimplemented123456789"
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID (not implemented)"
  value       = "us-east-1:00000000-0000-0000-0000-000000000000"
}

output "cognito_domain" {
  description = "Cognito hosted UI domain (not implemented)"
  value       = "not-implemented"
}

output "auth_url" {
  description = "Cognito authorization URL (not implemented)"
  value       = "https://not-implemented.auth.us-east-1.amazoncognito.com"
}
