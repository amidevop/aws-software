# GitHub Actions CI/CD Setup Guide

This guide explains how to configure GitHub Actions for automated Terraform deployments.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository with Actions enabled
3. Terraform state backend (S3 bucket recommended)

## Required GitHub Secrets

Configure these secrets in your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

> **📖 See [VARIABLES.md](VARIABLES.md) for complete list of all Terraform variables that can be passed through the pipeline.**

### AWS Credentials (Choose one method)

#### Method 1: IAM Role (Recommended - OIDC)
- `AWS_ROLE_ARN` - IAM Role ARN with Terraform permissions
  - Example: `arn:aws:iam::123456789012:role/github-actions-terraform-role`

#### Method 2: Access Keys (Less Secure)
- `AWS_ACCESS_KEY_ID` - AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY` - AWS Secret Access Key

### Terraform State Backend
- `TF_STATE_BUCKET` - S3 bucket name for Terraform state
  - Example: `my-terraform-state-bucket`
- `TF_STATE_KEY` - S3 key/path for state file
  - Example: `landing-zone/terraform.tfstate`

### Optional Secrets (if using these features)
- `RDS_PASSWORD` - Database password (if not using AWS Secrets Manager)
- `ALB_CERTIFICATE_ARN` - ACM certificate ARN for HTTPS
- `GITHUB_TOKEN` - Auto-generated, used for PR comments

## AWS IAM Permissions Required

The IAM role/user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "s3:*",
        "rds:*",
        "elasticloadbalancing:*",
        "iam:CreateRole",
        "iam:CreatePolicy",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "ssm:CreateDocument",
        "ssm:UpdateInstanceInformation",
        "acm:DescribeCertificate",
        "acm:ListCertificates"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket/*",
        "arn:aws:s3:::your-terraform-state-bucket"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

## Setting Up OIDC (Recommended)

1. **Create IAM OIDC Identity Provider in AWS:**
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

2. **Create IAM Role with Trust Policy:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
           }
         }
       }
     ]
   }
   ```

3. **Set the role ARN in GitHub Secrets as `AWS_ROLE_ARN`**

## Workflow Behavior

### Pull Requests
- ✅ Terraform format check
- ✅ Terraform init
- ✅ Terraform validate
- ✅ Terraform plan
- 📝 Comments PR with plan output

### Push to Main/Master
- ✅ All PR checks
- ✅ Terraform apply (auto-approve)

### Manual Workflow Dispatch
- Choose action: `plan`, `apply`, or `destroy`
- Choose environment: `dev`, `staging`, or `prod`

## Terraform Backend Configuration

1. **Create S3 bucket for state:**
   ```bash
   aws s3 mb s3://your-terraform-state-bucket --region us-east-1
   aws s3api put-bucket-versioning \
     --bucket your-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   ```

2. **Create DynamoDB table for state locking (optional):**
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

3. **Configure backend in `terraform.tf` or `backend.hcl`:**
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket"
       key            = "landing-zone/terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "terraform-state-lock"
     }
   }
   ```

## Environment-Specific Configurations

To support multiple environments, you can:

1. **Use different state keys:**
   - Dev: `landing-zone/dev/terraform.tfstate`
   - Staging: `landing-zone/staging/terraform.tfstate`
   - Prod: `landing-zone/prod/terraform.tfstate`

2. **Use different tfvars files:**
   - `terraform.tfvars.dev`
   - `terraform.tfvars.staging`
   - `terraform.tfvars.prod`

3. **Modify workflow to use environment-specific configs:**
   ```yaml
   - name: Terraform Plan
     run: terraform plan -var-file="terraform.tfvars.${{ github.event.inputs.environment }}"
   ```

## Troubleshooting

### Common Issues

1. **"Access Denied" errors:**
   - Check IAM permissions
   - Verify AWS credentials/role ARN
   - Ensure S3 bucket policy allows access

2. **"State file locked" errors:**
   - Check DynamoDB table exists
   - Verify table name matches backend config
   - Manually unlock if needed: `terraform force-unlock LOCK_ID`

3. **"Backend configuration not found":**
   - Ensure backend is configured in `terraform.tf` or `backend.hcl`
   - Check `TF_STATE_BUCKET` and `TF_STATE_KEY` secrets are set

4. **Plan/Apply fails:**
   - Check Terraform logs in Actions output
   - Verify all required variables are set
   - Ensure AWS region is correct

## Security Best Practices

1. ✅ Use OIDC instead of access keys
2. ✅ Enable S3 bucket versioning for state files
3. ✅ Enable S3 bucket encryption
4. ✅ Use DynamoDB for state locking
5. ✅ Restrict IAM permissions to minimum required
6. ✅ Use separate AWS accounts for dev/staging/prod
7. ✅ Never commit secrets or `.tfvars` files with sensitive data
8. ✅ Use AWS Secrets Manager for sensitive variables

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

