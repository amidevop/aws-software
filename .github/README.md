# GitHub Actions CI/CD

This directory contains GitHub Actions workflows for automated Terraform deployments.

## Files

- **`workflows/terraform.yml`** - Main CI/CD workflow
  - Runs on push to main/master and pull requests
  - Supports manual workflow dispatch with action selection
  - Includes format check, validate, plan, and apply steps

- **`CICD_SETUP.md`** - Complete setup guide
  - Required secrets configuration
  - IAM permissions
  - OIDC setup instructions
  - Troubleshooting

- **`VARIABLES.md`** - Complete guide for passing Terraform variables
  - All available GitHub Secrets
  - Environment-specific tfvars files
  - Workflow dispatch inputs
  - Examples and best practices

- **`workflows/terraform-backend-config.tf.example`** - Example backend configuration

## Quick Start

1. **Set GitHub Secrets:**
   - Go to: Settings → Secrets and variables → Actions
   - Add required secrets (see `CICD_SETUP.md`)

2. **Choose Authentication Method:**
   - **OIDC (Recommended):** Set `AWS_ROLE_ARN` secret
   - **Access Keys:** Comment out OIDC lines in workflow, uncomment access key lines

3. **Configure Backend:**
   - Option A: Create `backend.tf` from `backend.tf.example`
   - Option B: Set `TF_STATE_BUCKET` and `TF_STATE_KEY` secrets (workflow will use these)

4. **Push to trigger workflow:**
   - Create a PR to see `terraform plan` results
   - Merge to main/master to auto-apply

## Workflow Features

✅ **Pull Requests:**
- Format check
- Terraform validate
- Terraform plan
- Comments on PR with plan output

✅ **Push to Main/Master:**
- All PR checks
- Auto-apply changes

✅ **Manual Dispatch:**
- Choose action: `plan`, `apply`, or `destroy`
- Choose environment: `dev`, `staging`, or `prod`

## Required Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `AWS_ROLE_ARN` | IAM Role for OIDC (recommended) | Yes (if using OIDC) |
| `AWS_ACCESS_KEY_ID` | AWS Access Key | Yes (if using access keys) |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | Yes (if using access keys) |
| `TF_STATE_BUCKET` | S3 bucket for state | Yes |
| `TF_STATE_KEY` | S3 key/path for state | Yes |

## Passing Terraform Variables

The pipeline supports three methods to pass variables:

1. **GitHub Secrets** - Set secrets in repository settings (see `VARIABLES.md`)
2. **Environment tfvars files** - Create `terraform.tfvars.dev`, `terraform.tfvars.prod`, etc.
3. **Workflow inputs** - Override values when manually triggering

See `VARIABLES.md` for complete documentation on all available variables.

## Documentation

- **`CICD_SETUP.md`** - Detailed setup instructions
- **`VARIABLES.md`** - Complete variable reference and examples

