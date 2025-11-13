provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id != "" ? var.aws_access_key_id : null
  secret_key = var.aws_secret_access_key != "" ? var.aws_secret_access_key : null
  token      = var.aws_session_token != "" ? var.aws_session_token : null
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : "landing"
  generated_linux_instances = [
    for i in range(var.linux_instance_count) : {
      name                          = "linux-${i + 1}"
      os                            = "linux"
      ami_id                        = try(var.linux_instance_defaults.ami_id, null)
      instance_type                 = try(var.linux_instance_defaults.instance_type, "t3.micro")
      subnet_index                  = try(var.linux_instance_defaults.subnet_index, 0)
      associate_public_ip_address   = try(var.linux_instance_defaults.associate_public_ip_address, null)
      volume_size_gb                = try(var.linux_instance_defaults.volume_size_gb, 20)
      volume_type                   = try(var.linux_instance_defaults.volume_type, "gp3")
      additional_tags               = try(var.linux_instance_defaults.additional_tags, {})
      user_data                     = try(var.linux_instance_defaults.user_data, null)
    }
  ]
  generated_windows_instances = [
    for i in range(var.windows_instance_count) : {
      name                          = "windows-${i + 1}"
      os                            = "windows"
      ami_id                        = try(var.windows_instance_defaults.ami_id, null)
      instance_type                 = try(var.windows_instance_defaults.instance_type, "t3.large")
      subnet_index                  = try(var.windows_instance_defaults.subnet_index, 0)
      associate_public_ip_address   = try(var.windows_instance_defaults.associate_public_ip_address, null)
      volume_size_gb                = try(var.windows_instance_defaults.volume_size_gb, 50)
      volume_type                   = try(var.windows_instance_defaults.volume_type, "gp3")
      additional_tags               = try(var.windows_instance_defaults.additional_tags, {})
      user_data                     = try(var.windows_instance_defaults.user_data, null)
    }
  ]
  all_instances = concat(var.instances, local.generated_linux_instances, local.generated_windows_instances)
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr_block       = var.vpc_cidr_block
  azs                  = var.azs
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  tags                 = var.tags
}

module "s3" {
  source = "./modules/s3"

  create_bucket       = var.create_s3_bucket
  bucket_name         = var.s3_bucket_name
  force_destroy       = var.s3_force_destroy
  enable_versioning   = var.s3_enable_versioning
  enable_sse          = var.s3_enable_sse
  sse_kms_key_arn     = var.s3_sse_kms_key_arn
  block_public_access = var.s3_block_public_access
  tags                = var.tags
}

module "compute" {
  source = "./modules/compute"

  name_prefix            = local.name_prefix
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = var.ec2_use_public_subnets ? module.vpc.public_subnet_ids : module.vpc.private_subnet_ids
  instances              = local.all_instances
  os_filter              = var.compute_os
  app_port               = var.app_port
  ingress_from_sg_id     = var.enforce_alb_only_ingress && var.enable_alb ? try(module.alb.alb_sg_id, "") : ""
  common_security_rules  = var.ec2_common_security_rules
  key_pair_name          = var.ec2_key_pair_name
  create_key_pair        = var.ec2_create_key_pair
  generated_key_save_to  = var.ec2_generated_key_save_to
  enable_ssm             = var.compute_enable_ssm
  tags                   = var.tags
}

module "alb" {
  source = "./modules/alb"

  enable          = var.enable_alb
  name_prefix     = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  target_instance_ids = module.compute.instance_ids
  listener_port   = var.alb_listener_port
  app_port        = var.app_port
  enable_https    = var.alb_enable_https
  certificate_arn = var.alb_certificate_arn
  redirect_http_to_https = var.alb_redirect_http_to_https
  health_check    = var.alb_health_check
  tags            = var.tags
}

module "rds" {
  source = "./modules/rds"

  create                 = var.create_rds
  name_prefix            = local.name_prefix
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  family                 = var.rds_parameter_group_family
  instance_class         = var.rds_instance_class
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  storage_type           = var.rds_storage_type
  username               = var.rds_username
  password               = var.rds_password
  db_name                = var.rds_db_name
  multi_az               = var.rds_multi_az
  publicly_accessible    = var.rds_publicly_accessible
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection    = var.rds_deletion_protection
  tags                   = var.tags
}


