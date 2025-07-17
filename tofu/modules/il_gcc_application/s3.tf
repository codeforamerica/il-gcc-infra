resource "aws_s3_bucket" "get_child_care_illinois" {
  bucket        = "get-child-care-illinois-${var.environment}"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "get_child_care_illinois" {
  bucket = aws_s3_bucket.get_child_care_illinois.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "get_child_care_illinois" {
  bucket = aws_s3_bucket.get_child_care_illinois.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.get_child_care_illinois.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "get_child_care_illinois" {
  bucket = aws_s3_bucket.get_child_care_illinois.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "get_child_care_illinois" {
  bucket        = aws_s3_bucket.get_child_care_illinois.id
  target_bucket = aws_s3_bucket.get_child_care_illinois.id
  target_prefix = "${local.aws_logs_path}/s3accesslogs/${aws_s3_bucket.get_child_care_illinois.id}"
}

resource "aws_s3_bucket_policy" "get_child_care_illinois" {
  bucket = aws_s3_bucket.get_child_care_illinois.id
  policy = templatefile("${path.module}/templates/bucket-policy.json.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    partition : data.aws_partition.current.partition
    bucket : aws_s3_bucket.get_child_care_illinois.bucket
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "get_child_care_illinois" {
  bucket = aws_s3_bucket.get_child_care_illinois.id

  rule {
    id     = "state"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = var.state_version_expiration
    }
  }
}
