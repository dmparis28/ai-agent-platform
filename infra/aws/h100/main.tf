# infra/aws/h100/main.tf
# H100 GPU Instance for Shared Intelligence

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# H100 Instance (using p4d.24xlarge with A100s until H100 available)
resource "aws_instance" "h100" {
  ami           = data.aws_ami.ubuntu_gpu.id
  instance_type = "p4d.24xlarge"

  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.h100.id]
  iam_instance_profile        = aws_iam_instance_profile.h100.name
  associate_public_ip_address = false

  root_block_device {
    volume_size           = 500
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = false
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    s3_snapshot_bucket = var.snapshot_bucket
    aws_region         = var.aws_region
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name = "h100-shared-intelligence"
    Role = "shared-brain"
    Cost = "pay-per-use"
  })
}

# Security Group
resource "aws_security_group" "h100" {
  name        = "h100-gpu-sg"
  description = "H100 shared intelligence security group"
  vpc_id      = var.vpc_id

  # gRPC from Lambda agents
  ingress {
    description = "gRPC from Lambda agents"
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Neo4j from Lambda agents
  ingress {
    description = "Neo4j from Lambda agents"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Redis from Lambda agents
  ingress {
    description = "Redis from Lambda agents"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS outbound
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # S3 via VPC endpoint
  egress {
    description = "All traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = var.tags
}

# IAM Role
resource "aws_iam_role" "h100" {
  name = "h100-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# S3 Access Policy
resource "aws_iam_role_policy" "h100_s3" {
  name = "h100-s3-access"
  role = aws_iam_role.h100.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.snapshot_bucket}",
        "arn:aws:s3:::${var.snapshot_bucket}/*"
      ]
    }]
  })
}

# EC2 Control Policy (for self-shutdown)
resource "aws_iam_role_policy" "h100_ec2" {
  name = "h100-ec2-control"
  role = aws_iam_role.h100.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:StopInstances",
        "ec2:DescribeInstances"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "ec2:ResourceTag/Role" = "shared-brain"
        }
      }
    }]
  })
}

# SSM Access for management
resource "aws_iam_role_policy_attachment" "h100_ssm" {
  role       = aws_iam_role.h100.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "h100" {
  name = "h100-instance-profile"
  role = aws_iam_role.h100.name
}

# Ubuntu GPU-optimized AMI
data "aws_ami" "ubuntu_gpu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CloudWatch Alarm for idle detection
resource "aws_cloudwatch_metric_alarm" "h100_idle" {
  alarm_name          = "h100-idle-30min"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "6"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "Triggers when H100 idle for 30 minutes"
  alarm_actions       = [var.idle_shutdown_topic_arn]

  dimensions = {
    InstanceId = aws_instance.h100.id
  }
}

# Outputs
output "h100_instance_id" {
  description = "H100 instance ID"
  value       = aws_instance.h100.id
}

output "h100_private_ip" {
  description = "H100 private IP address"
  value       = aws_instance.h100.private_ip
}

output "h100_private_dns" {
  description = "H100 private DNS name"
  value       = aws_instance.h100.private_dns
}

output "h100_security_group_id" {
  description = "H100 security group ID"
  value       = aws_security_group.h100.id
}
