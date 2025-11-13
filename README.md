## AWS Landing Zone with Terraform
This configuration creates a parameterized, production-ready landing zone on AWS. It supports both small lab builds and larger greenfield setups with 20+ VMs via variables.

### What gets created
- VPC and Networking
  - One VPC with dynamic public and private subnets across AZs
  - Internet Gateway for public egress/ingress
  - Optional NAT Gateway(s) for private subnets egress
  - Public and private route tables with associations
- Compute (EC2)
  - Dynamic set of Linux and/or Windows instances
  - Shared compute security group (rules controlled via variables)
  - Optional managed key pair generation and local PEM export
  - Optional SSM role/profile to access instances via Session Manager
- Application Load Balancer (optional)
  - Internet-facing ALB in public subnets
  - Target group and listeners (HTTP; optional HTTPS with ACM + redirect)
  - Automatically registers created instances as targets
- Storage (optional)
  - S3 bucket with versioning, server-side encryption, and public access blocks
- Database (optional)
  - RDS instance (e.g., MySQL/Postgres) in private subnets
  - Parameter group and DB subnet group

### High-level architecture
- Public subnets: ALB (if enabled), NAT (if enabled)
- Private subnets: EC2 instances (recommended for prod), RDS (if enabled)
- Ingress paths:
  - Via ALB (recommended): Users → ALB (80/443) → Targets (app_port)
  - Direct to instances: Only if you place instances in public subnets and add explicit SG rules
- Egress: Private instances reach Internet through NAT for updates (if NAT enabled)

### Traffic from the Internet
- If `enable_alb = true`: ALB is internet-facing; it will accept traffic on `alb_listener_port` (80) and optionally HTTPS (443) if enabled.
- If `ec2_use_public_subnets = true` and SG rules allow, instances can be contacted directly.
- If instances are in private subnets and no ALB: no inbound Internet path (egress still allowed via NAT).

---

## Provisioning
1) Prereqs
- Terraform >= 1.5
- AWS credentials configured (environment variables, profile, or SSO)

2) Configure variables
- Copy the example file and adjust values:
```
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` to fit your region, CIDRs, instance counts/types, and options below.

3) Deploy
```
terraform init
terraform plan
terraform apply
```

4) Outputs
- VPC ID, subnet IDs
- Instance IDs and IPs
- ALB DNS name (if created)
- S3 bucket name (if created)
- RDS endpoint (if created)

---

## CI/CD with GitHub Actions

This repository includes GitHub Actions workflows for automated Terraform deployments.

### Quick Setup

1. **Configure GitHub Secrets** (Settings → Secrets and variables → Actions):
   - `AWS_ROLE_ARN` - IAM Role ARN (OIDC) OR `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`
   - `TF_STATE_BUCKET` - S3 bucket for Terraform state
   - `TF_STATE_KEY` - S3 key/path for state file (e.g., `landing-zone/terraform.tfstate`)

2. **Configure Terraform Backend:**
   - Copy `backend.tf.example` to `backend.tf` and update with your values
   - Or use `-backend-config` flags in the workflow (already configured)

3. **Workflow Behavior:**
   - **Pull Requests**: Runs `terraform plan` and comments on PR
   - **Push to main/master**: Runs `terraform apply` automatically
   - **Manual Dispatch**: Use Actions tab to run `plan`, `apply`, or `destroy`

### Detailed Setup Guide

See [`.github/CICD_SETUP.md`](.github/CICD_SETUP.md) for:
- Complete secret configuration
- IAM permissions required
- OIDC setup (recommended)
- Environment-specific configurations
- Troubleshooting guide

---

## Required and optional parameters
See `variables.tf` for full definitions; highlights below.

### Core
- `aws_region` (string): AWS region. Default: us-east-1.
- `name_prefix` (string): Resource name prefix. Default: landing.
- `tags` (map(string)): Common tags.

### Networking
- `vpc_cidr_block` (string): VPC CIDR, e.g., 10.10.0.0/16.
- `public_subnet_count` (number): Count of public subnets. Default: 2.
- `private_subnet_count` (number): Count of private subnets. Default: 2.
- `azs` (list(string)): Optional explicit AZs; otherwise discovered automatically.
- `enable_nat_gateway` (bool): Enable NAT for private egress. Default: true.
- `single_nat_gateway` (bool): One shared NAT vs per-AZ. Default: true.

### Compute (EC2)
Two ways to define instances (can be combined):
1) Explicit list
- `instances` (list(object)):
  - `name` (string): Suffix for tagging (Name = prefix-name).
  - `os` (string): linux | windows.
  - `instance_type` (string): e.g., t3.micro.
  - `subnet_index` (number, optional): Index into chosen subnet_ids (public or private).
  - `ami_id` (string, optional): Override AMI; if omitted auto-selects latest Amazon Linux 2 or Windows Server 2019.
  - `associate_public_ip_address` (bool, optional): Override subnet default.
  - `volume_size_gb`, `volume_type`: Root volume sizing, default gp3 20 GB (Linux), 50 GB (Windows via defaults).
  - `user_data` (string, optional), `additional_tags` (map, optional).

2) Count generators
- `linux_instance_count` (number), `windows_instance_count` (number)
- `linux_instance_defaults`, `windows_instance_defaults` (object):
  - Same fields as explicit instances; applied to generated groups.
- Example: 15 Linux + 5 Windows with consistent defaults without listing each.

Other compute controls
- `compute_os` (string): Filter to create linux | windows | both | none. Default: both.
- `ec2_use_public_subnets` (bool): Place compute in public (true) or private subnets (false). Default: true.
- `ec2_key_pair_name` (string): Use existing key pair.
- `ec2_create_key_pair` (bool): Auto-create a key pair if none provided. Default: false.
- `ec2_generated_key_save_to` (string): Path to save the generated private key PEM.
- `ec2_common_security_rules` (object): SG ingress/egress rules for instances. Defaults to no ingress and open egress.
- `compute_enable_ssm` (bool): Attach SSM role/profile to instances for Session Manager. Default: false.

### Load Balancer (optional)
- `enable_alb` (bool): Create internet-facing ALB in public subnets. Default: false.
- `app_port` (number): Port your app listens on; used by target group and instance SG when enforcing ALB-only ingress. Default: 80.
- `enforce_alb_only_ingress` (bool): If true, allow app traffic only from ALB SG to instances on `app_port`. Default: false.
- `alb_listener_port` (number): HTTP listener port. Default: 80.
- `alb_enable_https` (bool): Add HTTPS listener. Default: false.
- `alb_certificate_arn` (string): Required if HTTPS enabled; ACM cert in same region.
- `alb_redirect_http_to_https` (bool): Redirect HTTP→HTTPS when HTTPS is enabled. Default: true.
- `alb_health_check` (object): `path`, `matcher`, thresholds; defaults provided.

### Storage (optional)
- `create_s3_bucket` (bool): Create S3 bucket. Default: true.
- `s3_bucket_name` (string): Bucket name; if empty a random suffix name is generated.
- `s3_enable_versioning` (bool): Versioning. Default: true.
- `s3_enable_sse` (bool): Server-side encryption (AES256 by default). Default: true.
- `s3_sse_kms_key_arn` (string): Optional KMS key ARN for SSE-KMS.
- `s3_force_destroy` (bool): Force delete even when non-empty. Default: false.
- `s3_block_public_access` (bool): Block all public access. Default: true.

### Database (optional)
- `create_rds` (bool): Create RDS. Default: true.
- `rds_engine`, `rds_engine_version`, `rds_parameter_group_family`
- `rds_instance_class`, `rds_allocated_storage`, `rds_max_allocated_storage`, `rds_storage_type`
- `rds_username`, `rds_password` (sensitive), `rds_db_name`
- `rds_multi_az`, `rds_publicly_accessible`, `rds_backup_retention_period`, `rds_deletion_protection`

---

## Common deployment patterns
Private-only workload (no public ingress)
```
ec2_use_public_subnets   = false
enable_nat_gateway       = true
enable_alb               = false
compute_os               = "both"
linux_instance_count     = 3
windows_instance_count   = 2
ec2_common_security_rules = {
  ingress = [] # no public ingress
  egress  = [{ description = "All", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}
```

Public web behind ALB with HTTPS
```
enable_alb                 = true
alb_listener_port          = 80
alb_enable_https           = true
alb_certificate_arn        = "arn:aws:acm:REGION:ACCOUNT:certificate/xxxx"
alb_redirect_http_to_https = true
app_port                   = 80
enforce_alb_only_ingress   = true
compute_os                 = "linux"
linux_instance_count       = 4
```

Scale without listing every VM
```
linux_instance_count = 15
windows_instance_count = 5
linux_instance_defaults = { instance_type = "t3.micro", subnet_index = 0 }
windows_instance_defaults = { instance_type = "t3.large", subnet_index = 1 }
```

---

## Notes and recommendations
- For production, prefer private subnets for instances (`ec2_use_public_subnets = false`) and ingress via ALB.
- Restrict instance SG ingress; use `enforce_alb_only_ingress = true` and/or SSM access instead of public SSH.
- For HTTPS, the ACM certificate must be in the same region as the ALB and validated before apply.
- RDS default SG allows 3306 from 10.0.0.0/8; tighten to your VPC CIDR or compute SG as required in `modules/rds/main.tf`.
- If you change subnet counts or NAT topology, Terraform will plan route/NAT resource replacements—review plan carefully.


