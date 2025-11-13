variable "name_prefix" {
  type        = string
  description = "Name prefix"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones; if empty, will use data source to fetch"
  default     = []
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets"
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT gateway"
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default     = {}
}


