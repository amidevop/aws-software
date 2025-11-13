output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "ec2_instance_ids" {
  value       = module.compute.instance_ids
  description = "EC2 instance IDs"
}

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ALB DNS name (if created)"
}

output "s3_bucket_name" {
  value       = module.s3.bucket_name
  description = "S3 bucket name (if created)"
}

output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "RDS endpoint (if created)"
}


