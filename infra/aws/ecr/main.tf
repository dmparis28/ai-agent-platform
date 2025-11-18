# ECR Module - Container Image Registry
# Creates repositories for each AI agent

# ============================================
# ECR Repositories for Agents
# ============================================

# Triage Agent
resource "aws_ecr_repository" "triage" {
  name                 = "${var.project_name}/triage-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "triage-agent"
    Agent = "triage"
  })
}

# Frontend Agent
resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}/frontend-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "frontend-agent"
    Agent = "frontend"
  })
}

# Backend Agent
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}/backend-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "backend-agent"
    Agent = "backend"
  })
}

# Networking Agent
resource "aws_ecr_repository" "networking" {
  name                 = "${var.project_name}/networking-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "networking-agent"
    Agent = "networking"
  })
}

# Debugging Agent
resource "aws_ecr_repository" "debugging" {
  name                 = "${var.project_name}/debugging-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "debugging-agent"
    Agent = "debugging"
  })
}

# QA Agent
resource "aws_ecr_repository" "qa" {
  name                 = "${var.project_name}/qa-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "qa-agent"
    Agent = "qa"
  })
}

# SRE Agent
resource "aws_ecr_repository" "sre" {
  name                 = "${var.project_name}/sre-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "sre-agent"
    Agent = "sre"
  })
}

# Doc Writer Agent
resource "aws_ecr_repository" "doc_writer" {
  name                 = "${var.project_name}/doc-writer-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "doc-writer-agent"
    Agent = "doc-writer"
  })
}

# Product Manager Agent
resource "aws_ecr_repository" "pm" {
  name                 = "${var.project_name}/pm-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "pm-agent"
    Agent = "product-manager"
  })
}

# Architecture Agent
resource "aws_ecr_repository" "architecture" {
  name                 = "${var.project_name}/architecture-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "architecture-agent"
    Agent = "architecture"
  })
}

# Cybersecurity Auditor Agent
resource "aws_ecr_repository" "security_auditor" {
  name                 = "${var.project_name}/security-auditor-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name  = "security-auditor-agent"
    Agent = "security-auditor"
  })
}

# ============================================
# Lifecycle Policies (Auto-cleanup old images)
# ============================================
locals {
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "triage" {
  repository = aws_ecr_repository.triage.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "networking" {
  repository = aws_ecr_repository.networking.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "debugging" {
  repository = aws_ecr_repository.debugging.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "qa" {
  repository = aws_ecr_repository.qa.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "sre" {
  repository = aws_ecr_repository.sre.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "doc_writer" {
  repository = aws_ecr_repository.doc_writer.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "pm" {
  repository = aws_ecr_repository.pm.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "architecture" {
  repository = aws_ecr_repository.architecture.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "security_auditor" {
  repository = aws_ecr_repository.security_auditor.name
  policy     = local.lifecycle_policy
}
