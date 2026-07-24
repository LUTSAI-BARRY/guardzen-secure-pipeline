terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# KMS key for S3 encryption
resource "aws_kms_key" "guardzen_demo_key" {
  description             = "KMS key for GuardZen S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "guardzen-demo-key"
  }
}

resource "aws_kms_alias" "guardzen_demo_key_alias" {
  name          = "alias/guardzen-demo-key"
  target_key_id = aws_kms_key.guardzen_demo_key.key_id
}

# S3 bucket for logs
resource "aws_s3_bucket" "guardzen_demo_logs" {
  bucket = "guardzen-demo-logs-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "guardzen-demo-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "guardzen_demo_logs_block" {
  bucket                  = aws_s3_bucket.guardzen_demo_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "guardzen_demo_logs_encryption" {
  bucket = aws_s3_bucket.guardzen_demo_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Main S3 bucket
resource "aws_s3_bucket" "guardzen_demo" {
  bucket = "guardzen-demo-reports-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "guardzen-demo-reports"
  }
}

resource "aws_s3_bucket_public_access_block" "guardzen_demo_block" {
  bucket                  = aws_s3_bucket.guardzen_demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "guardzen_demo_ownership" {
  bucket = aws_s3_bucket.guardzen_demo.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "guardzen_demo_versioning" {
  bucket = aws_s3_bucket.guardzen_demo.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

# KMS encryption instead of AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "guardzen_demo_encryption" {
  bucket = aws_s3_bucket.guardzen_demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.guardzen_demo_key.arn
    }
    bucket_key_enabled = true
  }
}

# Enable logging
resource "aws_s3_bucket_logging" "guardzen_demo_logging" {
  bucket = aws_s3_bucket.guardzen_demo.id

  target_bucket = aws_s3_bucket.guardzen_demo_logs.id
  target_prefix = "guardzen-demo-logs/"
}

# Restrict security group
resource "aws_security_group" "guardzen_demo_sg" {
  name        = "guardzen-demo-sg"
  description = "Demo SG - hardened, no public SSH"

  tags = {
    Name = "guardzen-demo-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_internal" {
  security_group_id = aws_security_group.guardzen_demo_sg.id

  description = "SSH from internal VPN range only"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/24"

  tags = {
    Name = "ssh-internal"
  }
}

resource "aws_vpc_security_group_egress_rule" "https_only" {
  security_group_id = aws_security_group.guardzen_demo_sg.id

  description = "Allow outbound HTTPS only"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "https-outbound"
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
