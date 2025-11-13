# Fix ExpiredToken Error

## Problem
Your AWS credentials are expired. You need fresh credentials.

## Quick Fix - Use Environment Variables

### Step 1: Get Fresh AWS Credentials

**Option A: AWS Console**
1. Go to: https://console.aws.amazon.com/iam/
2. Navigate to: Users → Your User → Security Credentials
3. Click "Create Access Key"
4. Copy the Access Key ID and Secret Access Key

**Option B: AWS CLI (if using SSO)**
```powershell
aws sso login --profile your-profile
```

### Step 2: Set Environment Variables in PowerShell

Run these commands in your PowerShell session:

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_NEW_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_NEW_SECRET_ACCESS_KEY"
$env:AWS_REGION = "us-east-1"
```

### Step 3: Test

```powershell
terraform plan
```

## Alternative: Create terraform.tfvars

If you prefer using a file:

1. **Copy the example:**
```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

2. **Edit terraform.tfvars** and uncomment/add credentials:
```hcl
aws_region            = "us-east-1"
aws_access_key_id     = "YOUR_NEW_ACCESS_KEY_ID"
aws_secret_access_key = "YOUR_NEW_SECRET_ACCESS_KEY"
```

3. **Run:**
```powershell
terraform plan
```

## Verify Credentials Work

Test your credentials before running Terraform:
```powershell
aws sts get-caller-identity
```

If this works, your credentials are valid. If it fails, get new credentials.

## Important Notes

- ✅ Environment variables work immediately (no file needed)
- ✅ terraform.tfvars is in .gitignore (won't be committed)
- ❌ Never commit credentials to Git
- ⚠️ Credentials expire - you'll need to refresh them periodically

