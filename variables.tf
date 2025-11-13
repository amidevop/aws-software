variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID (optional - will use environment variables or AWS credentials file if not provided)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key (optional - will use environment variables or AWS credentials file if not provided)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token for temporary credentials (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "linux_instance_count" {
  description = "Number of Linux instances to auto-generate"
  type        = number
  default     = 0
}

variable "windows_instance_count" {
  description = "Number of Windows instances to auto-generate"
  type        = number
  default     = 0
}

variable "linux_instance_defaults" {
  description = "Defaults for generated Linux instances"
  type = object({
    instance_type               = optional(string, "t3.micro")
    subnet_index                = optional(number, 0)
    associate_public_ip_address = optional(bool, null)
    volume_size_gb              = optional(number, 20)
    volume_type                 = optional(string, "gp3")
    additional_tags             = optional(map(string), {})
    user_data                   = optional(string)
    ami_id                      = optional(string)
  })
  default = {}
}

variable "windows_instance_defaults" {
  description = "Defaults for generated Windows instances"
  type = object({
    instance_type               = optional(string, "t3.large")
    subnet_index                = optional(number, 0)
    associate_public_ip_address = optional(bool, null)
    volume_size_gb              = optional(number, 50)
    volume_type                 = optional(string, "gp3")
    additional_tags             = optional(map(string), {})
    user_data                   = optional(string)
    ami_id                      = optional(string)
  })
  default = {}
}

variable "compute_os" {
  description = "Which compute instances to create: linux, windows, both, or none"
  type        = string
  default     = "both"
  validation {
    condition     = contains(["linux", "windows", "both", "none"], lower(var.compute_os))
    error_message = "compute_os must be one of: linux, windows, both, none."
  }
}

variable "name_prefix" {
  description = "Prefix used for resource naming"
  type        = string
  default     = "landing"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway instead of one per AZ"
  type        = bool
  default     = true
}

variable "create_s3_bucket" {
  description = "Create an S3 bucket for storage"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket (random suffix is added if omitted)"
  type        = string
  default     = ""
}

variable "s3_force_destroy" {
  description = "Force destroy bucket even if not empty"
  type        = bool
  default     = false
}

variable "s3_enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_enable_sse" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "s3_sse_kms_key_arn" {
  description = "Optional KMS key ARN for S3 encryption (if empty, use AES256)"
  type        = string
  default     = ""
}

variable "s3_block_public_access" {
  description = "Block all public access to the S3 bucket"
  type        = bool
  default     = true
}

variable "ec2_use_public_subnets" {
  description = "Place EC2 instances in public subnets (vs private)"
  type        = bool
  default     = true
}

variable "instances" {
  description = "List of instances to create with dynamic attributes"
  type = list(object({
    name              = string
    os                = string       # linux | windows
    ami_id            = optional(string)
    instance_type     = string
    subnet_index      = optional(number) # index into chosen subnet_ids
    associate_public_ip_address = optional(bool)
    volume_size_gb    = optional(number, 20)
    volume_type       = optional(string, "gp3")
    additional_tags   = optional(map(string), {})
    user_data         = optional(string)
  }))
  default = []
}

variable "ec2_common_security_rules" {
  description = "Common security rules for EC2 security group"
  type = object({
    ingress = list(object({
      description = optional(string)
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string), [])
    }))
    egress = list(object({
      description = optional(string)
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string), ["0.0.0.0/0"])
    }))
  })
  default = {
    ingress = []
    egress = [
      {
        description = "All egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
}

variable "ec2_key_pair_name" {
  description = "Existing key pair name to use for EC2 instances"
  type        = string
  default     = ""
}

variable "ec2_create_key_pair" {
  description = "Create and manage a key pair for instances"
  type        = bool
  default     = false
}

variable "ec2_generated_key_save_to" {
  description = "Local path to save generated private key (if create_key_pair = true)"
  type        = string
  default     = ""
}

variable "enable_alb" {
  description = "Create an Application Load Balancer"
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Application port used by instances and ALB target group"
  type        = number
  default     = 80
}

variable "enforce_alb_only_ingress" {
  description = "If true, only allow app traffic from the ALB to instances (no public ingress on instance SG)"
  type        = bool
  default     = false
}

variable "alb_listener_port" {
  description = "ALB listener port"
  type        = number
  default     = 80
}

variable "alb_enable_https" {
  description = "Enable HTTPS listener on the ALB"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "alb_redirect_http_to_https" {
  description = "If HTTPS is enabled, redirect HTTP to HTTPS"
  type        = bool
  default     = true
}

variable "compute_enable_ssm" {
  description = "Attach SSM instance profile to EC2 instances for Session Manager access"
  type        = bool
  default     = false
}

variable "alb_health_check" {
  description = "ALB target group health check configuration"
  type = object({
    path                = optional(string, "/")
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
    interval            = optional(number, 30)
    timeout             = optional(number, 5)
    matcher             = optional(string, "200")
  })
  default = {}
}

variable "create_rds" {
  description = "Create an RDS instance"
  type        = bool
  default     = true
}

variable "rds_engine" {
  description = "RDS engine (e.g., mysql, postgres)"
  type        = string
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "8.0"
}

variable "rds_parameter_group_family" {
  description = "RDS parameter group family (e.g., mysql8.0)"
  type        = string
  default     = "mysql8.0"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage (GB)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Max autoscaled storage (GB)"
  type        = number
  default     = 100
}

variable "rds_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "rds_db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "rds_publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}


