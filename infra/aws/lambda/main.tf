# Lambda Module - Placeholder
# This module is not yet implemented

# When implemented, this will create:
# - 11 Lambda functions (one per agent)
# - IAM roles and policies
# - Security groups
# - EventBridge rules for routing
# - Lambda layers for dependencies

# For now, create dummy outputs to prevent errors
output "agent_function_arns" {
  description = "ARNs of all Lambda agent functions (not implemented)"
  value = {
    triage       = "arn:aws:lambda:us-east-1:123456789012:function:not-implemented"
    frontend     = "arn:aws:lambda:us-east-1:123456789012:function:not-implemented"
    backend      = "arn:aws:lambda:us-east-1:123456789012:function:not-implemented"
    architecture = "arn:aws:lambda:us-east-1:123456789012:function:not-implemented"
  }
}

output "event_bus_arn" {
  description = "EventBridge event bus ARN (not implemented)"
  value       = "arn:aws:events:us-east-1:123456789012:event-bus/not-implemented"
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions (not implemented)"
  value       = "sg-notimplemented"
}
