terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# KMS Key for Terraform State Encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name      = "terraform-state-encryption"
      Purpose   = "TerraformState"
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# KMS Key for State Lock Table
resource "aws_kms_key" "state_locks" {
  description             = "KMS key for Terraform state locks table encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name      = "terraform-state-locks-encryption"
      Purpose   = "TerraformStateLocks"
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_kms_alias" "state_locks" {
  name          = "alias/terraform-state-locks"
  target_key_id = aws_kms_key.state_locks.key_id
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.owner}-terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state_locks.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.owner}-terraform-state-locks"
      Purpose   = "TerraformStateLocking"
      ManagedBy = "Terraform"
    }
  )
}

# S3 Bucket for Access Logs
resource "aws_s3_bucket" "state_logs" {
  bucket = "${var.state_bucket_name}-access-logs"

  tags = merge(
    var.tags,
    {
      Name      = "${var.state_bucket_name}-access-logs"
      Purpose   = "TerraformStateAccessLogs"
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# Main State Bucket (assumes it already exists)
data "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
}

# Enable versioning on existing state bucket
resource "aws_s3_bucket_versioning" "state" {
  bucket = data.aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access on state bucket
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = data.aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption on state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = data.aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Enable access logging
resource "aws_s3_bucket_logging" "state" {
  bucket = data.aws_s3_bucket.state.id

  target_bucket = aws_s3_bucket.state_logs.id
  target_prefix = "state-access-logs/"
}

# Lifecycle policy for state bucket
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = data.aws_s3_bucket.state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket policy to enforce encryption
resource "aws_s3_bucket_policy" "state" {
  bucket = data.aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${data.aws_s3_bucket.state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          data.aws_s3_bucket.state.arn,
          "${data.aws_s3_bucket.state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = data.aws_s3_bucket.state.arn
}

output "state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = data.aws_s3_bucket.state.id
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB state lock table"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB state lock table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "kms_key_id" {
  description = "ID of the KMS key for state encryption"
  value       = aws_kms_key.terraform_state.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for state encryption"
  value       = aws_kms_key.terraform_state.arn
}
