# Terraform Variables for CI/CD Pipeline

This document explains how to pass Terraform variables through the GitHub Actions pipeline.

## Two Methods to Pass Variables

### Method 1: GitHub Secrets (Recommended for Sensitive/Static Values)

Set variables as GitHub Secrets in: **Settings → Secrets and variables → Actions → New repository secret**

### Method 2: Environment-Specific tfvars Files

Create `terraform.tfvars.ENV` files (e.g., `terraform.tfvars.dev`, `terraform.tfvars.prod`) and enable `use_tfvars_file` in workflow dispatch.

### Method 3: Workflow Dispatch Inputs (For Manual Runs)

When manually triggering the workflow, you can override common variables via workflow inputs.

---

## Required GitHub Secrets

These secrets are **required** for the pipeline to work:

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ROLE_ARN` | IAM Role ARN for OIDC (recommended) | `arn:aws:iam::123456789012:role/github-actions` |
| OR `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | AWS credentials (alternative) | - |
| `TF_STATE_BUCKET` | S3 bucket for Terraform state | `my-terraform-state-bucket` |
| `TF_STATE_KEY` | S3 key/path for state file | `landing-zone/terraform.tfstate` |

---

## Optional GitHub Secrets (Terraform Variables)

Set these secrets to override default Terraform variable values:

### Core Configuration

| Secret | Terraform Variable | Default | Description |
|--------|-------------------|---------|-------------|
| `AWS_REGION` | `aws_region` | `us-east-1` | AWS region to deploy |
| `NAME_PREFIX` | `name_prefix` | `landing` | Resource name prefix |
| `TAGS` | `tags` | `{}` | JSON object: `{"Project":"MyProject","Env":"prod"}` |

### Networking

| Secret | Terraform Variable | Default | Description |
|--------|-------------------|---------|-------------|
| `VPC_CIDR_BLOCK` | `vpc_cidr_block` | `10.0.0.0/16` | VPC CIDR block |
| `PUBLIC_SUBNET_COUNT` | `public_subnet_count` | `2` | Number of public subnets |
| `PRIVATE_SUBNET_COUNT` | `private_subnet_count` | `2` | Number of private subnets |
| `ENABLE_NAT_GATEWAY` | `enable_nat_gateway` | `true` | Enable NAT gateway |
| `SINGLE_NAT_GATEWAY` | `single_nat_gateway` | `true` | Use single NAT (vs per-AZ) |

### Compute (EC2)

| Secret | Terraform Variable | Default | Description |
|--------|-------------------|---------|-------------|
| `COMPUTE_OS` | `compute_os` | `both` | `linux`, `windows`, `both`, or `none` |
| `LINUX_INSTANCE_COUNT` | `linux_instance_count` | `0` | Number of Linux instances |
| `WINDOWS_INSTANCE_COUNT` | `windows_instance_count` | `0` | Number of Windows instances |
| `EC2_USE_PUBLIC_SUBNETS` | `ec2_use_public_subnets` | `true` | Place instances in public subnets |
| `COMPUTE_ENABLE_SSM` | `compute_enable_ssm` | `false` | Enable SSM for instance access |

### Load Balancer (ALB)

| Secret | Terraform Variable | Default | Description |
|--------|-------------------|---------|-------------|
| `ENABLE_ALB` | `enable_alb` | `false` | Enable Application Load Balancer |
| `ALB_LISTENER_PORT` | `alb_listener_port` | `80` | ALB listener port |
| `ALB_ENABLE_HTTPS` | `alb_enable_https` | `false` | Enable HTTPS listener |
| `ALB_CERTIFICATE_ARN` | `alb_certificate_arn` | `""` | ACM certificate ARN (required if HTTPS enabled) |
| `APP_PORT` | `app_port` | `80` | Application port (target group) |
| `ENFORCE_ALB_ONLY_INGRESS` | `enforce_alb_only_ingress` | `false` | Only allow ALB → instance traffic |

### Storage (S3)

| Secret | Terraform Variable | Default | Description |
|--------|-------------------|---------|-------------|
| `CREATE_S3_BUCKET` | `create_s3_bucket` | `true` | Create S3 bucket |

### Database (RDS)

| Secret | Terraform Variable | Default | Description |
|--------|-------------------|---------|-------------|
| `CREATE_RDS` | `create_rds` | `true` | Create RDS instance |
| `RDS_ENGINE` | `rds_engine` | `mysql` | Database engine (`mysql`, `postgres`, etc.) |
| `RDS_ENGINE_VERSION` | `rds_engine_version` | `8.0` | Engine version |
| `RDS_INSTANCE_CLASS` | `rds_instance_class` | `db.t3.micro` | Instance class |
| `RDS_ALLOCATED_STORAGE` | `rds_allocated_storage` | `20` | Storage in GB |
| `RDS_USERNAME` | `rds_username` | `admin` | Database username |
| `RDS_PASSWORD` | `rds_password` | - | **REQUIRED** if creating RDS |
| `RDS_DB_NAME` | `rds_db_name` | `appdb` | Database name |
| `RDS_MULTI_AZ` | `rds_multi_az` | `false` | Multi-AZ deployment |
| `RDS_PUBLICLY_ACCESSIBLE` | `rds_publicly_accessible` | `false` | Publicly accessible |
| `RDS_BACKUP_RETENTION_PERIOD` | `rds_backup_retention_period` | `7` | Backup retention (days) |
| `RDS_DELETION_PROTECTION` | `rds_deletion_protection` | `false` | Prevent deletion |

---

## Using Environment-Specific tfvars Files

### Step 1: Create tfvars Files

Create files like:
- `terraform.tfvars.dev`
- `terraform.tfvars.staging`
- `terraform.tfvars.prod`

Example `terraform.tfvars.dev`:
```hcl
aws_region   = "us-east-1"
name_prefix  = "lz-dev"
vpc_cidr_block = "10.1.0.0/16"

linux_instance_count   = 2
windows_instance_count = 1
compute_os = "both"

enable_alb = true
create_rds = true
rds_password = "DevPassword123!"
```

### Step 2: Use in Workflow

When manually triggering the workflow:
1. Select **Environment**: `dev`, `staging`, or `prod`
2. Enable **Use tfvars file**: `true`
3. The workflow will use `terraform.tfvars.{ENVIRONMENT}`

**Note:** Sensitive values (like `rds_password`) should still use GitHub Secrets even with tfvars files, or use AWS Secrets Manager.

---

## Workflow Dispatch Inputs

When manually triggering the workflow, you can override these variables:

| Input | Type | Description |
|-------|------|-------------|
| `terraform_action` | choice | `plan`, `apply`, or `destroy` |
| `environment` | choice | `dev`, `staging`, or `prod` |
| `use_tfvars_file` | boolean | Use tfvars file instead of secrets |
| `name_prefix` | string | Override name prefix |
| `linux_instance_count` | string | Override Linux instance count |
| `windows_instance_count` | string | Override Windows instance count |
| `compute_os` | choice | Override OS selection |
| `enable_alb` | boolean | Override ALB enablement |
| `create_rds` | boolean | Override RDS creation |
| `create_s3_bucket` | boolean | Override S3 creation |

**Priority:** Workflow inputs > GitHub Secrets > Defaults

---

## Examples

### Example 1: Using GitHub Secrets

Set these secrets:
```
AWS_REGION=us-east-1
NAME_PREFIX=prod-lz
LINUX_INSTANCE_COUNT=5
WINDOWS_INSTANCE_COUNT=2
ENABLE_ALB=true
RDS_PASSWORD=SecurePassword123!
```

The pipeline will use these values automatically.

### Example 2: Using tfvars File

1. Create `terraform.tfvars.prod`:
```hcl
aws_region = "us-east-1"
name_prefix = "prod-lz"
linux_instance_count = 10
windows_instance_count = 5
enable_alb = true
```

2. Manually trigger workflow:
   - Environment: `prod`
   - Use tfvars file: `true`

### Example 3: Override via Workflow Inputs

Manually trigger workflow:
- Environment: `dev`
- Use tfvars file: `false`
- Linux instance count: `3`
- Compute OS: `linux`
- Enable ALB: `true`

This will override secrets/defaults for this run only.

---

## Variable Priority Order

1. **Workflow Dispatch Inputs** (highest priority)
2. **GitHub Secrets**
3. **Terraform Defaults** (lowest priority)

---

## Security Best Practices

1. ✅ **Never commit secrets** to the repository
2. ✅ **Use GitHub Secrets** for sensitive values (passwords, keys)
3. ✅ **Use AWS Secrets Manager** for RDS passwords (recommended)
4. ✅ **Use OIDC** instead of access keys when possible
5. ✅ **Restrict secret access** using GitHub Environments
6. ✅ **Rotate secrets** regularly

---

## Troubleshooting

### Variables Not Applied

- Check secret names match exactly (case-sensitive)
- Verify secrets are set in the correct repository
- Check workflow logs for variable values (non-sensitive)

### Boolean Values

GitHub Secrets are strings. Use:
- `true` or `false` (lowercase)
- `1` or `0`
- `yes` or `no`

### JSON/Complex Values

For `tags` or complex objects, use JSON format:
```json
{"Project":"MyProject","Environment":"prod","Owner":"DevOps"}
```

### Missing Required Variables

If `RDS_PASSWORD` is not set and `CREATE_RDS=true`, Terraform will fail. Either:
- Set the secret, or
- Set `CREATE_RDS=false`

---

## Additional Resources

- [Terraform Variables Documentation](https://www.terraform.io/docs/language/values/variables.html)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

