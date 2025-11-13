output "instance_ids" {
  value = [for i in aws_instance.this : i.id]
}

output "instance_private_ips" {
  value = [for i in aws_instance.this : i.private_ip]
}

output "instance_public_ips" {
  value = [for i in aws_instance.this : try(i.public_ip, null)]
}


