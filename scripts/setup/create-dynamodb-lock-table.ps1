# AI Agent Platform - Create DynamoDB Lock Table for Terraform
# This table prevents concurrent Terraform operations

Write-Host "🔒 Creating DynamoDB Lock Table for Terraform" -ForegroundColor Cyan
Write-Host ""

$region = "us-east-1"
$tableName = "ai-agent-platform-terraform-locks"

# Check if table already exists
Write-Host "Checking if table exists..." -ForegroundColor Yellow
try {
    $tableInfo = aws dynamodb describe-table --table-name $tableName --region $region 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Table already exists: $tableName" -ForegroundColor Green
        Write-Host ""
        
        # Show table details
        $table = $tableInfo | ConvertFrom-Json
        Write-Host "Table Details:" -ForegroundColor Cyan
        Write-Host "  Name: $($table.Table.TableName)" -ForegroundColor White
        Write-Host "  Status: $($table.Table.TableStatus)" -ForegroundColor White
        Write-Host "  Billing Mode: $($table.Table.BillingModeSummary.BillingMode)" -ForegroundColor White
        Write-Host ""
        exit 0
    }
} catch {
    Write-Host "Table does not exist. Creating..." -ForegroundColor Yellow
}

# Create the table
Write-Host "Creating DynamoDB table: $tableName" -ForegroundColor Yellow
Write-Host ""

try {
    aws dynamodb create-table `
        --table-name $tableName `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $region `
        --tags Key=Environment,Value=personal Key=Project,Value=ai-agent-platform Key=ManagedBy,Value=script

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Table created successfully" -ForegroundColor Green
        Write-Host ""
        
        # Wait for table to be active
        Write-Host "Waiting for table to be active..." -ForegroundColor Yellow
        aws dynamodb wait table-exists --table-name $tableName --region $region
        
        Write-Host "✅ Table is active and ready" -ForegroundColor Green
        Write-Host ""
        
        # Display table info
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "  Table Created Successfully!" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Table Name: $tableName" -ForegroundColor Green
        Write-Host "Region: $region" -ForegroundColor Green
        Write-Host "Billing: Pay-per-request" -ForegroundColor Green
        Write-Host ""
        Write-Host "💰 Cost Impact:" -ForegroundColor Yellow
        Write-Host "  ~$0.50/month (minimal locking operations)" -ForegroundColor White
        Write-Host ""
        Write-Host "🎯 Next Step:" -ForegroundColor Cyan
        Write-Host "  Run: .\scripts\setup\init-terraform.ps1" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "❌ Failed to create table" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error creating table: $_" -ForegroundColor Red
    exit 1
}