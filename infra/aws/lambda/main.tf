# infra/aws/lambda/main.tf
# Lambda Functions for All AI Agents

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# IAM Role for Lambda Agents
# ============================================

resource "aws_iam_role" "agent_lambda" {
  name = "agent-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Basic execution
resource "aws_iam_role_policy_attachment" "agent_lambda_basic" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access
resource "aws_iam_role_policy_attachment" "agent_lambda_vpc" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# S3 access for artifacts
resource "aws_iam_role_policy" "agent_lambda_s3" {
  name = "agent-lambda-s3-access"
  role = aws_iam_role.agent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = ["${var.artifacts_bucket_arn}/*"]
    }]
  })
}

# Secrets Manager access
resource "aws_iam_role_policy" "agent_lambda_secrets" {
  name = "agent-lambda-secrets-access"
  role = aws_iam_role.agent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [var.anthropic_secret_arn]
    }]
  })
}

# DynamoDB access for task state
resource "aws_iam_role_policy" "agent_lambda_dynamodb" {
  name = "agent-lambda-dynamodb-access"
  role = aws_iam_role.agent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ]
      Resource = [var.task_table_arn]
    }]
  })
}

# EC2 permissions to start H100
resource "aws_iam_role_policy" "agent_lambda_ec2" {
  name = "agent-lambda-ec2-access"
  role = aws_iam_role.agent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:StartInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus"
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

# ============================================
# Security Group for Lambda Functions
# ============================================

resource "aws_security_group" "lambda_agents" {
  name        = "lambda-agents-sg"
  description = "Security group for Lambda agent functions"
  vpc_id      = var.vpc_id

  # Egress to H100 gRPC
  egress {
    description = "gRPC to H100"
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress to H100 Neo4j
  egress {
    description = "Neo4j to H100"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress to H100 Redis
  egress {
    description = "Redis to H100"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS for AWS services and Anthropic API
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ============================================
# Lambda Layer for Common Dependencies
# ============================================

resource "aws_lambda_layer_version" "agent_dependencies" {
  filename   = var.dependencies_layer_path
  layer_name = "agent-dependencies"

  compatible_runtimes = ["python3.11"]

  description = "Common dependencies for all agents: anthropic, boto3, grpcio, redis, neo4j"
}

# ============================================
# Lambda Functions - All 11 Agents
# ============================================

# Triage Agent
resource "aws_lambda_function" "triage" {
  filename      = "${var.lambda_packages_dir}/triage_agent.zip"
  function_name = "triage-agent"
  role          = aws_iam_role.agent_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_agents.id]
  }

  environment {
    variables = {
      H100_ENDPOINT     = var.h100_private_ip
      ARTIFACTS_BUCKET  = var.artifacts_bucket_name
      ANTHROPIC_SECRET  = var.anthropic_secret_name
      TASK_TABLE        = var.task_table_name
      AGENT_TYPE        = "triage"
    }
  }

  layers = [aws_lambda_layer_version.agent_dependencies.arn]

  tags = merge(var.tags, { Agent = "triage", Tier = "cpu" })
}

# Frontend Agent
resource "aws_lambda_function" "frontend" {
  filename      = "${var.lambda_packages_dir}/frontend_agent.zip"
  function_name = "frontend-agent"
  role          = aws_iam_role.agent_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 1024

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_agents.id]
  }

  environment {
    variables = {
      H100_ENDPOINT     = var.h100_private_ip
      H100_INSTANCE_ID  = var.h100_instance_id
      ARTIFACTS_BUCKET  = var.artifacts_bucket_name
      ANTHROPIC_SECRET  = var.anthropic_secret_name
      TASK_TABLE        = var.task_table_name
      CLAUDE_MODEL      = "claude-sonnet-4-20250514"
      AGENT_TYPE        = "frontend"
    }
  }

  layers = [aws_lambda_layer_version.agent_dependencies.arn]

  tags = merge(var.tags, { Agent = "frontend", Tier = "medium-gpu" })
}

# Backend Agent
resource "aws_lambda_function" "backend" {
  filename      = "${var.lambda_packages_dir}/backend_agent.zip"
  function_name = "backend-agent"
  role          = aws_iam_role.agent_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 1024

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_agents.id]
  }

  environment {
    variables = {
      H100_ENDPOINT     = var.h100_private_ip
      H100_INSTANCE_ID  = var.h100_instance_id
      ARTIFACTS_BUCKET  = var.artifacts_bucket_name
      ANTHROPIC_SECRET  = var.anthropic_secret_name
      TASK_TABLE        = var.task_table_name
      CLAUDE_MODEL      = "claude-sonnet-4-20250514"
      AGENT_TYPE        = "backend"
    }
  }

  layers = [aws_lambda_layer_version.agent_dependencies.arn]

  tags = merge(var.tags, { Agent = "backend", Tier = "medium-gpu" })
}

# Architecture Agent (High GPU)
resource "aws_lambda_function" "architecture" {
  filename      = "${var.lambda_packages_dir}/architecture_agent.zip"
  function_name = "architecture-agent"
  role          = aws_iam_role.agent_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 600
  memory_size   = 3008  # Max Lambda memory

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_agents.id]
  }

  environment {
    variables = {
      H100_ENDPOINT     = var.h100_private_ip
      H100_INSTANCE_ID  = var.h100_instance_id
      ARTIFACTS_BUCKET  = var.artifacts_bucket_name
      ANTHROPIC_SECRET  = var.anthropic_secret_name
      TASK_TABLE        = var.task_table_name
      CLAUDE_MODEL      = "claude-opus-4-20250514"
      AGENT_TYPE        = "architecture"
    }
  }

  layers = [aws_lambda_layer_version.agent_dependencies.arn]

  tags = merge(var.tags, { Agent = "architecture", Tier = "high-gpu" })
}

# ... Continue for remaining 7 agents (network, debug, qa, sre, doc, pm, sec-audit)
# Following same pattern

# ============================================
# EventBridge for Task Routing
# ============================================

resource "aws_cloudwatch_event_bus" "agent_tasks" {
  name = "agent-tasks"
  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "task_submitted" {
  name           = "agent-task-submitted"
  event_bus_name = aws_cloudwatch_event_bus.agent_tasks.name
  description    = "Routes submitted tasks to appropriate agent"

  event_pattern = jsonencode({
    source      = ["custom.aiagents"]
    detail-type = ["Task Submitted"]
  })

  tags = var.tags
}

# EventBridge target for Triage (always first)
resource "aws_cloudwatch_event_target" "triage" {
  rule           = aws_cloudwatch_event_rule.task_submitted.name
  event_bus_name = aws_cloudwatch_event_bus.agent_tasks.name
  target_id      = "triage-agent"
  arn            = aws_lambda_function.triage.arn
}

resource "aws_lambda_permission" "triage_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.triage.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.task_submitted.arn
}

# ============================================
# Outputs
# ============================================

output "agent_function_arns" {
  description = "ARNs of all agent Lambda functions"
  value = {
    triage       = aws_lambda_function.triage.arn
    frontend     = aws_lambda_function.frontend.arn
    backend      = aws_lambda_function.backend.arn
    architecture = aws_lambda_function.architecture.arn
  }
}

output "event_bus_arn" {
  description = "EventBridge event bus ARN"
  value       = aws_cloudwatch_event_bus.agent_tasks.arn
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = aws_security_group.lambda_agents.id
}
