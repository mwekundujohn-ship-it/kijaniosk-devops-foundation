data "aws_caller_identity" "current" {}

locals {
  common_labels = {
    project    = "kijaniosk"
    managed_by = "terraform"
    capstone   = "track-a"
    account_id = data.aws_caller_identity.current.account_id
  }

  receipts_buckets = {
    staging    = "${var.receipts_bucket_prefix}-staging-${data.aws_caller_identity.current.account_id}"
    production = "${var.receipts_bucket_prefix}-production-${data.aws_caller_identity.current.account_id}"
  }
}

resource "kubernetes_namespace_v1" "staging" {
  metadata {
    name = var.staging_namespace
    labels = merge(local.common_labels, {
      environment = "staging"
    })
  }
}

resource "kubernetes_namespace_v1" "production" {
  metadata {
    name = var.production_namespace
    labels = merge(local.common_labels, {
      environment = "production"
    })
  }
}

resource "aws_s3_bucket" "receipts" {
  for_each = local.receipts_buckets

  bucket        = each.value
  force_destroy = true

  tags = merge(local.common_labels, {
    environment = each.key
    purpose     = "receipts"
  })
}

resource "aws_s3_bucket_versioning" "receipts" {
  for_each = aws_s3_bucket.receipts

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "receipts" {
  for_each = aws_s3_bucket.receipts

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "receipts" {
  for_each = aws_s3_bucket.receipts

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
