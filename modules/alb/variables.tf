variable "enable" {
  type    = bool
  default = false
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_instance_ids" {
  type    = list(string)
  default = []
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "app_port" {
  type    = number
  default = 80
}

variable "enable_https" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "redirect_http_to_https" {
  type    = bool
  default = true
}

variable "health_check" {
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

variable "tags" {
  type    = map(string)
  default = {}
}


