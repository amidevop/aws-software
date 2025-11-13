# AWS Credentials Setup for Terraform

This guide explains how to configure AWS credentials for Terraform on Windows.

## Method 1: Environment Variables (Recommended for Testing)

Set these environment variables in PowerShell:

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_REGION = "us-east-1"  # Optional, can also set in terraform.tfvars
```

**To make them persistent for the current session:**
```powershell
[System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID", "YOUR_ACCESS_KEY_ID", "User")
[System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", "YOUR_SECRET_ACCESS_KEY", "User")
```

Then restart your PowerShell session.

## Method 2: AWS Credentials File (Recommended for Production)

1. Create the AWS credentials directory:
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.aws"
```

2. Create credentials file:
```powershell
@"
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
"@ | Out-File -FilePath "$env:USERPROFILE\.aws\credentials" -Encoding utf8
```

3. Create config file (optional, for default region):
```powershell
@"
[default]
region = us-east-1
output = json
"@ | Out-File -FilePath "$env:USERPROFILE\.aws\config" -Encoding utf8
```

## Method 3: AWS CLI Profile

If you have AWS CLI installed:

```powershell
aws configure
```

This will prompt you for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name
- Default output format

## Method 4: Using AWS SSO (For Organizations)

If your organization uses AWS SSO:

```powershell
aws sso login --profile your-profile-name
```

Then set the profile in Terraform by adding to `main.tf`:
```hcl
provider "aws" {
  region  = var.aws_region
  profile = "your-profile-name"  # Add this line
}
```

## Method 5: Temporary Credentials (IAM Role/Session Token)

If you have temporary credentials with a session token:

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_SESSION_TOKEN = "YOUR_SESSION_TOKEN"
$env:AWS_REGION = "us-east-1"
```

## Verify Credentials

Test your credentials:

```powershell
aws sts get-caller-identity
```

Or with Terraform:

```powershell
terraform plan
```

## Security Best Practices

1. ✅ **Never commit credentials** to Git
2. ✅ **Use IAM roles** when running on EC2
3. ✅ **Use AWS SSO** for organizational access
4. ✅ **Rotate credentials** regularly
5. ✅ **Use least privilege** IAM policies
6. ✅ **Use environment variables** for CI/CD pipelines (GitHub Secrets)

## Troubleshooting

### Error: "ExpiredToken"
- Your credentials have expired
- Refresh your session token or get new credentials

### Error: "InvalidClientTokenId"
- Your access key ID is incorrect
- Verify the credentials

### Error: "SignatureDoesNotMatch"
- Your secret access key is incorrect
- Verify the credentials

### Error: "AccessDenied"
- Your IAM user/role doesn't have required permissions
- Check IAM policies

## Required IAM Permissions

Your AWS credentials need these permissions:
- EC2 (for VPC, subnets, instances)
- VPC (for networking)
- S3 (for storage)
- RDS (for database)
- ELB (for load balancer)
- IAM (for roles/policies)
- SSM (if using SSM for instance access)

See `.github/CICD_SETUP.md` for detailed IAM policy example.

