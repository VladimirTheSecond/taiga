# Bucket names are global across all AWS accounts, so the account ID makes it unique.
resource "aws_s3_bucket" "tfstate" {
  bucket = "taiga-tfstate-${data.aws_caller_identity.current.account_id}"

  # Losing the bucket means losing the state of the main stack.
  lifecycle {
    prevent_destroy = true
  }
}

# Every state write becomes a new object version: a broken state can be rolled back.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# State can contain secrets in plain text, so encrypt at rest.
# SSE-S3 (AES256) instead of KMS: free, no key policy to manage, enough for a pet project.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Old state versions pile up with every apply; keep the last 10 for 90 days.
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 10
    }
  }

  depends_on = [aws_s3_bucket_versioning.tfstate]
}
