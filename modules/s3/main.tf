resource "random_id" "suffix" {
  byte_length = 3
  count       = var.create_bucket && var.bucket_name == "" ? 1 : 0
}

locals {
  create = var.create_bucket
  name   = var.bucket_name != "" ? var.bucket_name : "storage-${random_id.suffix[0].hex}"
}

resource "aws_s3_bucket" "this" {
  count         = local.create ? 1 : 0
  bucket        = local.name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = local.create ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = local.create && var.enable_sse ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.sse_kms_key_arn != "" ? var.sse_kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = local.create && var.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


