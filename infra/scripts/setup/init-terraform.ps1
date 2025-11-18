# AI Agent Platform - Terraform Initialization
# Creates S3 bucket and DynamoDB table for Terraform state management

Write-Host "🔧 AI Agent Platform - Terraform Backend Setup" -ForegroundColor Cyan
Write-Host ""

$region = "us-east-1"
$bucketName = "ai-agent-platform-terraform-state"
$dynamoTableName = "ai-agent-platform-terraform-locks"

# Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    $accountId = $awsIdentity.Account
    Write-Host "✅ AWS Account: $accountId" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not configured" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================
# Create S3 Bucket for Terraform State
# ============================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Step 1: S3 Bucket for Terraform State" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Check if bucket exists
$bucketExists = aws s3api head-bucket --bucket $bucketName --region $region 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ S3 bucket already exists: $bucketName" -ForegroundColor Green
} else {
    Write-Host "Creating S3 bucket: $bucketName" -ForegroundColor Yellow
    
    # Create bucket
    aws s3api create-bucket `
        --bucket $bucketName `
        --region $region `
        --create-bucket-configuration LocationConstraint=$region 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        # If region is us-east-1, don't specify LocationConstraint
        aws s3api create-bucket `
            --bucket $bucketName `
            --region $region
    }
    
    Write-Host "✅ Created S3 bucket" -ForegroundColor Green
    
    # Enable versioning
    Write-Host "Enabling versioning..." -ForegroundColor Yellow
    aws s3api put-bucket-versioning `
        --bucket $bucketName `
        --versioning-configuration Status=Enabled `
        --region $region
    Write-Host "✅ Enabled versioning" -ForegroundColor Green
    
    # Enable encryption
    Write-Host "Enabling encryption..." -ForegroundColor Yellow
    aws s3api put-bucket-encryption `
        --bucket $bucketName `
        --server-side-encryption-configuration '{\"Rules\": [{\"ApplyServerSideEncryptionByDefault\": {\"SSEAlgorithm\": \"AES256\"}}]}' `
        --region $region
    Write-Host "✅ Enabled encryption" -ForegroundColor Green
    
    # Block public access
    Write-Host "Blocking public access..." -ForegroundColor Yellow
    aws s3api put-public-access-block `
        --bucket $bucketName `
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" `
        --region $region
    Write-Host "✅ Blocked public access" -ForegroundColor Green
    
    # Add lifecycle policy (optional - saves costs)
    Write-Host "Adding lifecycle policy..." -ForegroundColor Yellow
    $lifecyclePolicy = @"
{
  "Rules": [
    {
      "Id": "DeleteOldVersions",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
"@
    $lifecyclePolicy | aws s3api put-bucket-lifecycle-configuration `
        --bucket $bucketName `
        --lifecycle-configuration file:///dev/stdin `
        --region $region
    Write-Host "✅ Added lifecycle policy" -ForegroundColor Green
}

# ============================================
# Create DynamoDB Table for State Locking
# ============================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Step 2: DynamoDB Table for State Locking" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Check if table exists
try {
    aws dynamodb describe-table --table-name $dynamoTableName --region $region 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ DynamoDB table already exists: $dynamoTableName" -ForegroundColor Green
    }
} catch {
    Write-Host "Creating DynamoDB table: $dynamoTableName" -ForegroundColor Yellow
    
    aws dynamodb create-table `
        --table-name $dynamoTableName `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $region | Out-Null
    
    Write-Host "✅ Created DynamoDB table" -ForegroundColor Green
    
    # Wait for table to be active
    Write-Host "Waiting for table to be active..." -ForegroundColor Yellow
    aws dynamodb wait table-exists --table-name $dynamoTableName --region $region
    Write-Host "✅ Table is active" -ForegroundColor Green
}

# ============================================
# Initialize Terraform
# ============================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Step 3: Initialize Terraform" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Navigate to infrastructure directory
$currentDir = Get-Location
Set-Location "$currentDir/infra/environments/personal"

Write-Host "Running terraform init..." -ForegroundColor Yellow
terraform init -upgrade

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Terraform initialized successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    Set-Location $currentDir
    exit 1
}

Set-Location $currentDir

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  ✨ Terraform Backend Ready!" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "Backend Configuration:" -ForegroundColor Green
Write-Host "  📦 S3 Bucket: $bucketName" -ForegroundColor White
Write-Host "     - Region: $region" -ForegroundColor White
Write-Host "     - Versioning: Enabled" -ForegroundColor White
Write-Host "     - Encryption: Enabled" -ForegroundColor White
Write-Host "     - Public Access: Blocked" -ForegroundColor White
Write-Host ""
Write-Host "  🔒 DynamoDB Table: $dynamoTableName" -ForegroundColor White
Write-Host "     - Region: $region" -ForegroundColor White
Write-Host "     - Billing: Pay-per-request" -ForegroundColor White
Write-Host ""

Write-Host "💰 Cost Impact:" -ForegroundColor Yellow
Write-Host "  S3 Storage: ~$0.02/GB/month (expect <$0.10/month)" -ForegroundColor White
Write-Host "  DynamoDB: Pay-per-request (expect <$0.50/month)" -ForegroundColor White
Write-Host "  Total Backend Cost: <$1/month" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review terraform.tfvars and update alert email" -ForegroundColor White
Write-Host "  2. Run: terraform plan (from infra/environments/personal/)" -ForegroundColor White
Write-Host "  3. Run: terraform apply (to deploy infrastructure)" -ForegroundColor White
Write-Host ""

Write-Host "📝 Note:" -ForegroundColor Yellow
Write-Host "  Your Terraform state is now stored securely in AWS" -ForegroundColor White
Write-Host "  Never commit .terraform/ or *.tfstate files to git" -ForegroundColor White
Write-Host ""