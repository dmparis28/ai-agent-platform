# cleanup-old-files.ps1
# Removes old architecture files from project

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = ".",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "🧹 Cleaning Up Old Architecture Files" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
    Write-Host ""
}

# Folders to delete
$foldersToDelete = @(
    "k8s",                          # All Kubernetes manifests
    "orch/workflows",               # Step Functions workflows
    "infra/aws/eks",               # EKS cluster config
    "infra/aws/step-fn",           # Step Functions
    "sec/firebase",                # Firebase auth (switching to Cognito)
    "agt/*/Dockerfile"             # Agent Dockerfiles (now Lambda)
)

# Files to delete
$filesToDelete = @(
    "docker-compose.yaml",
    "scripts/local/docker-compose.yaml",
    "**/node-groups.tf",
    "**/cluster.tf",
    "**/irsa.tf",
    "**/*step-function*.json",
    "**/*firebase*.json",
    "**/*firebase*.ts"
)

Write-Host "Folders to be removed:" -ForegroundColor Yellow
foreach ($folder in $foldersToDelete) {
    $fullPath = Join-Path $ProjectPath $folder
    if (Test-Path $fullPath) {
        Write-Host "  ❌ $folder" -ForegroundColor Red
        
        if (-not $DryRun) {
            Remove-Item -Path $fullPath -Recurse -Force
            Write-Host "     Deleted" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⏭️  $folder (not found)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Files to be removed:" -ForegroundColor Yellow
foreach ($filePattern in $filesToDelete) {
    $files = Get-ChildItem -Path $ProjectPath -Filter $filePattern -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $relativePath = $file.FullName.Replace($ProjectPath, "").TrimStart('\', '/')
        Write-Host "  ❌ $relativePath" -ForegroundColor Red
        
        if (-not $DryRun) {
            Remove-Item -Path $file.FullName -Force
            Write-Host "     Deleted" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Creating backup of deleted items list..." -ForegroundColor Cyan
$deletedItemsList = @()
foreach ($folder in $foldersToDelete) {
    $deletedItemsList += "FOLDER: $folder"
}
foreach ($file in $filesToDelete) {
    $deletedItemsList += "FILE PATTERN: $file"
}

$backupFile = "deleted-items-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$deletedItemsList | Out-File -FilePath (Join-Path $ProjectPath $backupFile)
Write-Host "  ✅ Backup saved to: $backupFile" -ForegroundColor Green

Write-Host ""
if ($DryRun) {
    Write-Host "✅ Dry run complete. Run without -DryRun to actually delete files." -ForegroundColor Yellow
} else {
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Removed:" -ForegroundColor Cyan
    Write-Host "  • Kubernetes manifests (k8s/)" -ForegroundColor White
    Write-Host "  • EKS Terraform modules" -ForegroundColor White
    Write-Host "  • Step Functions workflows" -ForegroundColor White
    Write-Host "  • Firebase authentication code" -ForegroundColor White
    Write-Host "  • Docker-related files" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: terraform apply -f infra/destroy-old-resources.tf" -ForegroundColor White
    Write-Host "  2. Verify AWS resources deleted" -ForegroundColor White
    Write-Host "  3. Add new Lambda and H100 modules" -ForegroundColor White
}

Write-Host ""
