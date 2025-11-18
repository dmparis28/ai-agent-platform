# ECR Module Outputs

output "repository_urls" {
  description = "Map of agent names to ECR repository URLs"
  value = {
    triage           = aws_ecr_repository.triage.repository_url
    frontend         = aws_ecr_repository.frontend.repository_url
    backend          = aws_ecr_repository.backend.repository_url
    networking       = aws_ecr_repository.networking.repository_url
    debugging        = aws_ecr_repository.debugging.repository_url
    qa               = aws_ecr_repository.qa.repository_url
    sre              = aws_ecr_repository.sre.repository_url
    doc_writer       = aws_ecr_repository.doc_writer.repository_url
    pm               = aws_ecr_repository.pm.repository_url
    architecture     = aws_ecr_repository.architecture.repository_url
    security_auditor = aws_ecr_repository.security_auditor.repository_url
  }
}

output "repository_arns" {
  description = "Map of agent names to ECR repository ARNs"
  value = {
    triage           = aws_ecr_repository.triage.arn
    frontend         = aws_ecr_repository.frontend.arn
    backend          = aws_ecr_repository.backend.arn
    networking       = aws_ecr_repository.networking.arn
    debugging        = aws_ecr_repository.debugging.arn
    qa               = aws_ecr_repository.qa.arn
    sre              = aws_ecr_repository.sre.arn
    doc_writer       = aws_ecr_repository.doc_writer.arn
    pm               = aws_ecr_repository.pm.arn
    architecture     = aws_ecr_repository.architecture.arn
    security_auditor = aws_ecr_repository.security_auditor.arn
  }
}
