# Quick script to set AWS credentials as environment variables
# Run this script in PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Set AWS Credentials for Terraform" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Enter your AWS credentials:" -ForegroundColor Yellow
Write-Host ""

$accessKey = Read-Host "AWS Access Key ID" -AsSecureString
$secretKey = Read-Host "AWS Secret Access Key" -AsSecureString
$region = Read-Host "AWS Region (default: us-east-1)"

if ([string]::IsNullOrWhiteSpace($region)) {
    $region = "us-east-1"
}

# Convert secure strings to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($accessKey)
$plainAccessKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey)
$plainSecretKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Set environment variables
$env:AWS_ACCESS_KEY_ID = $plainAccessKey
$env:AWS_SECRET_ACCESS_KEY = $plainSecretKey
$env:AWS_REGION = $region

Write-Host ""
Write-Host "✅ Credentials set for current PowerShell session" -ForegroundColor Green
Write-Host ""
Write-Host "Testing credentials..." -ForegroundColor Yellow

# Test credentials
try {
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        $result = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Credentials are valid!" -ForegroundColor Green
            Write-Host $result -ForegroundColor Gray
        }
        else {
            Write-Host "❌ Credentials test failed" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
            Write-Host ""
            Write-Host "Please check:" -ForegroundColor Yellow
            Write-Host "1. Access Key ID is correct" -ForegroundColor White
            Write-Host "2. Secret Access Key is correct" -ForegroundColor White
            Write-Host "3. Credentials are not expired" -ForegroundColor White
        }
    }
    else {
        Write-Host "⚠️  AWS CLI not found. Skipping credential test." -ForegroundColor Yellow
        Write-Host "   You can test by running: terraform plan" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️  Could not test credentials automatically" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Run: terraform plan" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Note: These credentials are only set for this PowerShell session." -ForegroundColor Yellow
Write-Host "   To make them persistent, use AWS credentials file or terraform.tfvars" -ForegroundColor Yellow
Write-Host ""

