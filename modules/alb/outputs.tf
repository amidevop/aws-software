output "alb_arn" {
  value = try(aws_lb.this[0].arn, null)
}

output "alb_dns_name" {
  value = try(aws_lb.this[0].dns_name, null)
}

output "alb_sg_id" {
  value = try(aws_security_group.alb[0].id, null)
}


