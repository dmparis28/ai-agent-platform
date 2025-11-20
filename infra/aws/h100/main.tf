# H100 Module - Placeholder
# This module is not yet implemented

# When implemented, this will create:
# - EC2 instance with GPU (p4d.24xlarge)
# - Security groups for gRPC, Neo4j, Redis
# - IAM role and instance profile
# - CloudWatch alarm for idle detection
# - User data script for initialization

# For now, create dummy outputs to prevent errors
output "h100_instance_id" {
  description = "H100 instance ID (not implemented)"
  value       = "not-implemented"
}

output "h100_private_ip" {
  description = "H100 private IP (not implemented)"
  value       = "10.0.1.100"
}

output "h100_private_dns" {
  description = "H100 private DNS (not implemented)"
  value       = "h100.internal"
}

output "h100_security_group_id" {
  description = "H100 security group ID (not implemented)"
  value       = "sg-notimplemented"
}
