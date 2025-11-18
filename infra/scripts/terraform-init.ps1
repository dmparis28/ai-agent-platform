# AI Agent Platform - Terraform Init Script
# Run this from the project root directory

Write-Host "🚀 Initializing Terraform for Personal Environment" -ForegroundColor Cyan
Write-Host ""

# Change to the personal environment directory
$targetDir = "infra/environments/personal"
if (-not (Test-Path $targetDir)) {
    Write-Host "❌ Directory not found: $targetDir" -ForegroundColor Red
    Write-Host "   Make sure you're running this from the project root" -ForegroundColor Yellow
    exit 1
}

Set-Location $targetDir
Write-Host "📁 Working directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Check if backend.tf exists
if (-not (Test-Path "backend.tf")) {
    Write-Host "⚠️  backend.tf not found in current directory" -ForegroundColor Yellow
    Write-Host "   This is normal if you haven't run init-terraform.ps1 yet" -ForegroundColor Yellow
    Write-Host ""
}

# Run terraform init with auto-approve flags
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Running: terraform init -upgrade" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Run terraform init with proper flags to avoid prompts
terraform init -upgrade -reconfigure

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  ✅ Terraform Initialized Successfully!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 What was initialized:" -ForegroundColor Cyan
    Write-Host "   • Terraform providers (AWS, Kubernetes, Helm)" -ForegroundColor White
    Write-Host "   • VPC module dependencies" -ForegroundColor White
    Write-Host "   • Backend configuration (if exists)" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Review terraform.tfvars and update alert_email" -ForegroundColor White
    Write-Host "   2. Run: terraform validate" -ForegroundColor White
    Write-Host "   3. Run: terraform plan" -ForegroundColor White
    Write-Host "   4. Run: terraform apply (when ready to deploy)" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "  • Make sure AWS CLI is configured: aws configure" -ForegroundColor White
    Write-Host "  • Check AWS credentials: aws sts get-caller-identity" -ForegroundColor White
    Write-Host "  • Verify Terraform is installed: terraform version" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Return to original directory
Set-Location ../../..
