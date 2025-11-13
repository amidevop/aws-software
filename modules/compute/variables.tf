variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instances" {
  type = list(object({
    name                          = string
    os                            = string
    ami_id                        = optional(string)
    instance_type                 = string
    subnet_index                  = optional(number)
    associate_public_ip_address   = optional(bool)
    volume_size_gb                = optional(number, 20)
    volume_type                   = optional(string, "gp3")
    additional_tags               = optional(map(string), {})
    user_data                     = optional(string)
  }))
}

variable "os_filter" {
  type    = string
  default = "both"
}

variable "common_security_rules" {
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
}

variable "app_port" {
  type    = number
  default = 80
}

variable "ingress_from_sg_id" {
  type    = string
  default = ""
}

variable "enable_ssm" {
  type    = bool
  default = false
}

variable "key_pair_name" {
  type    = string
  default = ""
}

variable "create_key_pair" {
  type    = bool
  default = false
}

variable "generated_key_save_to" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}


