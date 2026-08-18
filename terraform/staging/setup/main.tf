terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region  = "ap-southeast-2"
  profile = "keto-granola-terraform-setup-staging"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "keto-granola-staging-tfstate-v1"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---- Scoped IAM user for Cloudflare ----
resource "aws_iam_user" "cloudflare_staging" {
  name = "keto-granola-staging-cloudflare"
}

resource "aws_iam_user_policy" "cloudflare_staging_state_access" {
  name = "terraform-state-access"
  user = aws_iam_user.cloudflare_staging.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.tf_state.arn,
          "${aws_s3_bucket.tf_state.arn}/cloudflare/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "cloudflare_staging" {
  user = aws_iam_user.cloudflare_staging.name
}
