# VPC Module

## Overview

This module creates the network foundation for the AI Agent Platform, including VPC, subnets, NAT gateway, and VPC endpoints.

## Features

- **VPC** with configurable CIDR block
- **Public and Private Subnets** across multiple availability zones
- **Single NAT Gateway** for cost optimization (can be configured for multi-AZ)
- **S3 Gateway Endpoint** (FREE) for S3 access without NAT
- **ECR Interface Endpoints** for private container image pulls
- **EKS-ready subnet tagging** for automatic load balancer integration

## Cost Breakdown

| Resource | Monthly Cost | Notes |
|----------|--------------|-------|
| NAT Gateway | $32.40 | Single NAT Gateway in us-east-1a |
| NAT Data Processing | ~$2-5 | Based on data transfer (~50GB/month) |
| S3 Endpoint | FREE | Gateway endpoint has no charge |
| ECR API Endpoint | $7.20 | Interface endpoint |
| ECR DKR Endpoint | $7.20 | Interface endpoint |
| **Total** | **~$49-52/month** | |

## Usage

```hcl
module "vpc" {
  source = "../../aws/vpc"

  vpc_name           = "ai-agent-platform-vpc"
  vpc_cidr           = "10.0.0.0/16"
  aws_region         = "us-east-1"
  availability_zones = ["us-east-1a", "us-east-1b"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  cluster_name       = "ai-agent-platform"

  # Cost optimization
  single_nat_gateway     = true
  enable_ecr_endpoints   = true
  enable_s3_endpoint     = true

  tags = {
    Environment = "personal"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_name | Name of the VPC | string | - | yes |
| vpc_cidr | CIDR block for VPC | string | - | yes |
| aws_region | AWS region | string | - | yes |
| availability_zones | List of AZs | list(string) | - | yes |
| private_subnets | Private subnet CIDRs | list(string) | - | yes |
| public_subnets | Public subnet CIDRs | list(string) | - | yes |
| cluster_name | EKS cluster name | string | - | yes |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| single_nat_gateway | Use single NAT | bool | true | no |
| one_nat_gateway_per_az | One NAT per AZ | bool | false | no |
| enable_s3_endpoint | Enable S3 endpoint | bool | true | no |
| enable_ecr_endpoints | Enable ECR endpoints | bool | true | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| private_subnets | Private subnet IDs |
| public_subnets | Public subnet IDs |
| nat_gateway_ids | NAT Gateway IDs |
| vpc_endpoint_ecr_api_id | ECR API endpoint ID |
| vpc_endpoint_ecr_dkr_id | ECR DKR endpoint ID |

## Architecture

```
┌─────────────────────────────────────────────┐
│                    VPC                       │
│              10.0.0.0/16                     │
│                                              │
│  ┌──────────────┐      ┌──────────────┐    │
│  │  us-east-1a  │      │  us-east-1b  │    │
│  │              │      │              │    │
│  │  Public      │      │  Public      │    │
│  │  10.0.101/24 │      │  10.0.102/24 │    │
│  │      │       │      │              │    │
│  │   NAT GW     │      │              │    │
│  │      │       │      │              │    │
│  │  Private     │      │  Private     │    │
│  │  10.0.1/24   │      │  10.0.2/24   │    │
│  │      │       │      │      │       │    │
│  │   EKS Nodes  │      │   EKS Nodes  │    │
│  └──────────────┘      └──────────────┘    │
│                                              │
│  VPC Endpoints:                              │
│  - S3 (Gateway) - FREE                       │
│  - ECR API (Interface) - $7.20/mo            │
│  - ECR DKR (Interface) - $7.20/mo            │
└─────────────────────────────────────────────┘
```

## Cost Optimization Notes

### Single NAT Gateway
- **Cost Savings**: $64.80/month (saves 2 additional NAT Gateways)
- **Trade-off**: No high availability for internet-bound traffic
- **Acceptable for**: Personal/development environments
- **Not recommended for**: Production with SLA requirements

### VPC Endpoints
- **S3 Gateway Endpoint**: FREE and saves NAT data transfer costs
- **ECR Endpoints**: $14.40/month but saves NAT data transfer for Docker pulls
- **Break-even**: If you pull >300GB of images/month through NAT, endpoints are cheaper

### Scaling to Production
When you need HA:
```hcl
single_nat_gateway     = false
one_nat_gateway_per_az = true
```
This adds 2 more NAT Gateways (+$64.80/month) but provides full redundancy.

## Security

- Private subnets have no direct internet access
- All internet traffic routes through NAT Gateway
- VPC endpoints use private IPs only
- Security groups restrict endpoint access to VPC CIDR only
- Flow logs can be enabled (add `enable_flow_log = true`)

## Troubleshooting

### NAT Gateway not working
```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways --region us-east-1

# Verify route tables
aws ec2 describe-route-tables --region us-east-1
```

### VPC Endpoint connectivity issues
```bash
# Test from within VPC (on an EC2 instance)
nslookup api.ecr.us-east-1.amazonaws.com

# Should resolve to private IP (10.0.x.x range)
```

## Maintenance

### Adding more subnets
1. Update `private_subnets` or `public_subnets` list
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to add subnets

### Migrating to multi-NAT Gateway
1. Change `single_nat_gateway = false`
2. Change `one_nat_gateway_per_az = true`
3. Run `terraform plan` (will show 2 new NAT Gateways)
4. Run `terraform apply`
5. Cost increases by $64.80/month

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS VPC Endpoints Pricing](https://aws.amazon.com/privatelink/pricing/)
- [EKS VPC Requirements](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)