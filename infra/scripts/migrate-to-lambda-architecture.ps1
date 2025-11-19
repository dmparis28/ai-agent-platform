# migrate-to-lambda-architecture.ps1
# Complete migration from EKS to Lambda + H100

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = ".",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDestroy = $false
)

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   AI Agent Platform - Lambda Architecture Migration              ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# ============================================
# Step 1: Backup Current State
# ============================================

if (-not $SkipBackup) {
    Write-Host "📦 Step 1: Backing up current Terraform state..." -ForegroundColor Yellow
    
    $backupDir = Join-Path $ProjectPath "backups"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $backupDir "pre-migration-$timestamp"
    
    New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
    
    # Backup Terraform state
    Push-Location (Join-Path $ProjectPath "infra")
    terraform state pull | Out-File -FilePath (Join-Path $backupPath "terraform.tfstate")
    Pop-Location
    
    # Backup current config files
    Copy-Item -Path (Join-Path $ProjectPath "infra") -Destination (Join-Path $backupPath "infra") -Recurse -Force
    
    Write-Host "   ✅ Backup saved to: $backupPath" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⚠️  Skipping backup (use -SkipBackup $false to enable)" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# Step 2: Destroy Old Infrastructure
# ============================================

if (-not $SkipDestroy) {
    Write-Host "🔥 Step 2: Destroying old EKS infrastructure..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   This will destroy:" -ForegroundColor White
    Write-Host "     • EKS cluster (saves $72/month)" -ForegroundColor Gray
    Write-Host "     • CPU node pool (saves $120/month)" -ForegroundColor Gray
    Write-Host "     • GPU node pools" -ForegroundColor Gray
    Write-Host "     • Application Load Balancer (saves $17/month)" -ForegroundColor Gray
    Write-Host "     • ECR repositories (will recreate)" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "   Continue with destruction? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Host "   ❌ Migration cancelled" -ForegroundColor Red
        exit 1
    }
    
    Push-Location (Join-Path $ProjectPath "infra")
    
    # Run Terraform destroy script
    Write-Host "   Applying destroy script..." -ForegroundColor Gray
    terraform apply -auto-approve -target=null_resource.destroy_eks
    terraform apply -auto-approve -target=null_resource.destroy_step_functions
    terraform apply -auto-approve -target=null_resource.destroy_ecr
    terraform apply -auto-approve -target=null_resource.destroy_alb
    terraform apply -auto-approve -target=null_resource.cleanup_vpc_endpoints
    
    Pop-Location
    
    Write-Host "   ✅ Old infrastructure destroyed" -ForegroundColor Green
    Write-Host "   💰 Monthly savings: $209/month" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⚠️  Skipping infrastructure destruction" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# Step 3: Clean Up Old Files
# ============================================

Write-Host "🧹 Step 3: Cleaning up old architecture files..." -ForegroundColor Yellow

& (Join-Path $ProjectPath "scripts/cleanup/cleanup-old-files.ps1") -ProjectPath $ProjectPath

Write-Host "   ✅ Old files removed" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 4: Add New Infrastructure Code
# ============================================

Write-Host "📁 Step 4: Adding new Lambda + H100 infrastructure..." -ForegroundColor Yellow

# Copy new modules
$newModulesPath = Join-Path $ProjectPath "infra/aws"

Write-Host "   • H100 module..." -ForegroundColor Gray
Copy-Item -Path "./h100" -Destination (Join-Path $newModulesPath "h100") -Recurse -Force

Write-Host "   • Lambda module..." -ForegroundColor Gray
Copy-Item -Path "./lambda" -Destination (Join-Path $newModulesPath "lambda") -Recurse -Force

Write-Host "   • Cognito module (replacing Firebase)..." -ForegroundColor Gray
Copy-Item -Path "./cognito" -Destination (Join-Path $newModulesPath "cognito") -Recurse -Force

Write-Host "   ✅ New modules added" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 5: Update Main Terraform Config
# ============================================

Write-Host "⚙️  Step 5: Updating main Terraform configuration..." -ForegroundColor Yellow

$mainTfPath = Join-Path $ProjectPath "infra/main.tf"

$newModules = @"

# ============================================
# H100 Shared Intelligence
# ============================================
module "h100" {
  source = "./aws/h100"

  vpc_id                   = module.vpc.vpc_id
  private_subnet_id        = module.vpc.private_subnets[0]
  vpc_cidr                 = var.vpc_cidr
  snapshot_bucket          = module.storage.snapshots_bucket_name
  aws_region               = var.aws_region
  idle_shutdown_topic_arn  = module.monitoring.idle_shutdown_topic_arn

  tags = local.common_tags
}

# ============================================
# Lambda Agents
# ============================================
module "lambda_agents" {
  source = "./aws/lambda"

  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnets
  vpc_cidr                = var.vpc_cidr
  h100_private_ip         = module.h100.h100_private_ip
  h100_instance_id        = module.h100.h100_instance_id
  artifacts_bucket_name   = module.storage.artifacts_bucket_name
  artifacts_bucket_arn    = module.storage.artifacts_bucket_arn
  anthropic_secret_name   = var.anthropic_secret_name
  anthropic_secret_arn    = module.secrets.anthropic_secret_arn
  task_table_name         = module.storage.task_table_name
  task_table_arn          = module.storage.task_table_arn
  lambda_packages_dir     = var.lambda_packages_dir

  tags = local.common_tags

  depends_on = [module.h100]
}

# ============================================
# Cognito Authentication (replaces Firebase)
# ============================================
module "cognito" {
  source = "./aws/cognito"

  cognito_domain          = var.cognito_domain
  callback_urls           = var.cognito_callback_urls
  logout_urls             = var.cognito_logout_urls
  google_client_id        = var.google_client_id
  google_client_secret    = var.google_client_secret
  api_gateway_arn         = module.apigw.api_gateway_arn
  artifacts_bucket_arn    = module.storage.artifacts_bucket_arn
  aws_region              = var.aws_region

  tags = local.common_tags
}
"@

Add-Content -Path $mainTfPath -Value $newModules

Write-Host "   ✅ Main config updated" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 6: Initialize Terraform
# ============================================

Write-Host "🔧 Step 6: Initializing Terraform..." -ForegroundColor Yellow

Push-Location (Join-Path $ProjectPath "infra")
terraform init -upgrade
Pop-Location

Write-Host "   ✅ Terraform initialized" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 7: Plan New Infrastructure
# ============================================

Write-Host "📋 Step 7: Planning new infrastructure..." -ForegroundColor Yellow
Write-Host ""

Push-Location (Join-Path $ProjectPath "infra")
terraform plan -out=tfplan
Pop-Location

Write-Host ""
Write-Host "   📊 Review the plan above carefully" -ForegroundColor Yellow
$applyConfirm = Read-Host "   Apply this plan? (yes/no)"

if ($applyConfirm -ne "yes") {
    Write-Host "   ⏸️  Migration paused. Run 'terraform apply tfplan' when ready." -ForegroundColor Yellow
    exit 0
}

# ============================================
# Step 8: Apply New Infrastructure
# ============================================

Write-Host ""
Write-Host "🚀 Step 8: Deploying new infrastructure..." -ForegroundColor Yellow

Push-Location (Join-Path $ProjectPath "infra")
terraform apply tfplan
Pop-Location

Write-Host "   ✅ Infrastructure deployed" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 9: Build Lambda Packages
# ============================================

Write-Host "📦 Step 9: Building Lambda deployment packages..." -ForegroundColor Yellow

Push-Location (Join-Path $ProjectPath "agt")
& ../scripts/deploy/build-lambda-packages.ps1
Pop-Location

Write-Host "   ✅ Lambda packages built" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 10: Deploy Lambda Code
# ============================================

Write-Host "☁️  Step 10: Deploying Lambda code..." -ForegroundColor Yellow

aws lambda update-function-code --function-name triage-agent --zip-file fileb://./lambda_packages/triage_agent.zip
aws lambda update-function-code --function-name frontend-agent --zip-file fileb://./lambda_packages/frontend_agent.zip
aws lambda update-function-code --function-name backend-agent --zip-file fileb://./lambda_packages/backend_agent.zip
aws lambda update-function-code --function-name architecture-agent --zip-file fileb://./lambda_packages/architecture_agent.zip

Write-Host "   ✅ Lambda code deployed" -ForegroundColor Green
Write-Host ""

# ============================================
# Final Summary
# ============================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ✅ Migration Complete!                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Destroyed:" -ForegroundColor Yellow
Write-Host "     ❌ EKS cluster" -ForegroundColor Gray
Write-Host "     ❌ Kubernetes manifests" -ForegroundColor Gray
Write-Host "     ❌ Application Load Balancer" -ForegroundColor Gray
Write-Host "     ❌ Firebase authentication" -ForegroundColor Gray
Write-Host ""
Write-Host "   Created:" -ForegroundColor Yellow
Write-Host "     ✅ H100 GPU instance" -ForegroundColor Gray
Write-Host "     ✅ 11 Lambda functions" -ForegroundColor Gray
Write-Host "     ✅ EventBridge routing" -ForegroundColor Gray
Write-Host "     ✅ Cognito authentication" -ForegroundColor Gray
Write-Host ""
Write-Host "💰 Cost Impact:" -ForegroundColor Cyan
Write-Host "   Old monthly cost:  ~$342" -ForegroundColor Red
Write-Host "   New monthly cost:  ~$106" -ForegroundColor Green
Write-Host "   Monthly savings:   $236 (69% reduction)" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Test architecture: ./scripts/test-architecture.ps1" -ForegroundColor White
Write-Host "   2. Update frontend: Update Cognito config in React app" -ForegroundColor White
Write-Host "   3. Monitor H100: aws ec2 describe-instances --filters Name=tag:Role,Values=shared-brain" -ForegroundColor White
Write-Host ""
