variable "create_bucket" {
  type    = bool
  default = true
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "enable_sse" {
  type    = bool
  default = true
}

variable "sse_kms_key_arn" {
  type    = string
  default = ""
}

variable "block_public_access" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}


