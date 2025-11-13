resource "random_id" "kp" {
  byte_length = 4
  count       = var.create_key_pair && var.key_pair_name == "" ? 1 : 0
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
  count     = var.create_key_pair && var.key_pair_name == "" ? 1 : 0
}

resource "aws_key_pair" "this" {
  count      = var.create_key_pair && var.key_pair_name == "" ? 1 : 0
  key_name   = "${var.name_prefix}-kp-${random_id.kp[0].hex}"
  public_key = tls_private_key.this[0].public_key_openssh
  tags       = var.tags
}

resource "local_file" "private_key_pem" {
  count    = var.create_key_pair && var.key_pair_name == "" && var.generated_key_save_to != "" ? 1 : 0
  content  = tls_private_key.this[0].private_key_pem
  filename = var.generated_key_save_to
  file_permission = "0600"
}

locals {
  resolved_key_name = var.key_pair_name != "" ? var.key_pair_name : (var.create_key_pair ? aws_key_pair.this[0].key_name : null)
}

resource "aws_security_group" "compute" {
  name        = "${var.name_prefix}-compute-sg"
  description = "Security group for compute instances"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_from_sg_id != "" ? [1] : []
    content {
      description     = "App traffic from ALB"
      from_port       = var.app_port
      to_port         = var.app_port
      protocol        = "tcp"
      security_groups = [var.ingress_from_sg_id]
    }
  }

  dynamic "ingress" {
    for_each = var.common_security_rules.ingress
    content {
      description = try(ingress.value.description, null)
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = try(ingress.value.cidr_blocks, [])
    }
  }

  dynamic "egress" {
    for_each = var.common_security_rules.egress
    content {
      description = try(egress.value.description, null)
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = try(egress.value.cidr_blocks, ["0.0.0.0/0"])
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-compute-sg"
  })
}

data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  count              = var.enable_ssm ? 1 : 0
  name               = "${var.name_prefix}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.name_prefix}-ssm-profile"
  role  = aws_iam_role.ssm[0].name
  tags  = var.tags
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

locals {
  filter_val = lower(var.os_filter)
  filtered_instances = [
    for inst in var.instances :
    inst if (
      local.filter_val == "both" ||
      (local.filter_val == "linux" && lower(inst.os) == "linux") ||
      (local.filter_val == "windows" && lower(inst.os) == "windows")
    )
  ]
  instance_map = {
    for idx, inst in local.filtered_instances :
    idx => merge(inst, {
      ami_id = coalesce(try(inst.ami_id, null), lower(inst.os) == "windows" ? data.aws_ami.windows.id : data.aws_ami.linux.id)
      subnet_id = var.subnet_ids[ try(inst.subnet_index, 0) % length(var.subnet_ids) ]
      associate_public_ip_address = try(inst.associate_public_ip_address, null)
    })
  }
}

resource "aws_instance" "this" {
  for_each               = local.instance_map
  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  key_name               = local.resolved_key_name
  vpc_security_group_ids = [aws_security_group.compute.id]
  associate_public_ip_address = try(each.value.associate_public_ip_address, null)
  iam_instance_profile   = var.enable_ssm ? aws_iam_instance_profile.ssm[0].name : null

  root_block_device {
    volume_size = try(each.value.volume_size_gb, 20)
    volume_type = try(each.value.volume_type, "gp3")
  }

  user_data = try(each.value.user_data, null)

  tags = merge(var.tags, try(each.value.additional_tags, {}), {
    Name = "${var.name_prefix}-${each.value.name}"
    OS   = lower(each.value.os)
  })
}


