terraform {
  backend "s3" {
    bucket         = "ai-agent-platform-terraform-state"
    key            = "personal/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ai-agent-platform-terraform-locks"
    encrypt        = true
  }
}
