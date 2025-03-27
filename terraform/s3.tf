resource "aws_s3_bucket" "log_data_bucket" {
  bucket = "${var.project_name}-${var.environment}-log-data-bucket-${random_pet.id.id}"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.log_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_configuration" {
  bucket = aws_s3_bucket.log_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.log_data_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.log_data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "log_data_bucket_policy" {
  bucket = aws_s3_bucket.log_data_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DenyIncorrectEncryptionHeader"
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.log_data_bucket.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.log_data_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "null"
          }
        }
      }
    ]
  })
}