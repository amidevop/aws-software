# Quick Start - Fix ExpiredToken Error

## The Problem
You're getting `ExpiredToken` error because:
1. AWS credentials are expired, OR
2. `terraform.tfvars` file doesn't exist with your credentials

## Solution

### Step 1: Create terraform.tfvars

Copy the example and uncomment credentials:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars` and uncomment these lines:
```hcl
aws_access_key_id     = "YOUR_ACCESS_KEY_ID"
aws_secret_access_key = "YOUR_SECRET_ACCESS_KEY"
```

### Step 2: Get Fresh AWS Credentials

Your credentials might be expired. Get new ones:

1. **If using AWS Console:**
   - Go to IAM → Users → Your User → Security Credentials
   - Create new Access Key

2. **If using AWS SSO:**
   ```powershell
   aws sso login --profile your-profile
   ```

3. **If using temporary credentials:**
   - Get new session token
   - Update `aws_session_token` in terraform.tfvars

### Step 3: Update terraform.tfvars

Edit `terraform.tfvars`:
```hcl
aws_region            = "us-east-1"
aws_access_key_id     = "YOUR_NEW_ACCESS_KEY_ID"
aws_secret_access_key = "YOUR_NEW_SECRET_ACCESS_KEY"
# aws_session_token   = ""  # Only if using temporary credentials
```

### Step 4: Test

```powershell
terraform plan
```

## Alternative: Use Environment Variables

Instead of terraform.tfvars, set environment variables:

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_REGION = "us-east-1"
```

Then run `terraform plan` (no need for terraform.tfvars)

## Verify Credentials Work

Test your credentials:
```powershell
aws sts get-caller-identity
```

If this fails, your credentials are invalid/expired.

## Security Reminder

- ✅ `terraform.tfvars` is in `.gitignore` - won't be committed
- ❌ Never commit credentials to Git
- ✅ Use environment variables for CI/CD

