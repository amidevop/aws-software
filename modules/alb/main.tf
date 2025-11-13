locals {
  create = var.enable
}

resource "aws_security_group" "alb" {
  count       = local.create ? 1 : 0
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_lb" "this" {
  count                      = local.create ? 1 : 0
  name                       = "${var.name_prefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.subnet_ids
  security_groups            = [aws_security_group.alb[0].id]
  enable_deletion_protection = false
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "this" {
  count    = local.create ? 1 : 0
  name     = "${var.name_prefix}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = try(var.health_check.path, "/")
    healthy_threshold   = try(var.health_check.healthy_threshold, 3)
    unhealthy_threshold = try(var.health_check.unhealthy_threshold, 3)
    interval            = try(var.health_check.interval, 30)
    timeout             = try(var.health_check.timeout, 5)
    matcher             = try(var.health_check.matcher, "200")
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tg"
  })
}

resource "aws_lb_listener" "http_redirect" {
  count             = local.create && var.enable_https && var.redirect_http_to_https ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "http_forward" {
  count             = local.create && (!var.enable_https || !var.redirect_http_to_https) ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}

resource "aws_lb_listener" "https" {
  count             = local.create && var.enable_https && var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}

resource "aws_lb_target_group_attachment" "targets" {
  count            = local.create ? length(var.target_instance_ids) : 0
  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = var.target_instance_ids[count.index]
  port             = var.app_port
}


