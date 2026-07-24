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

resource "aws_s3_bucket" "guardzen_demo" {
  bucket = "guardzen-demo-reports-bucket"
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
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "guardzen_demo_encryption" {
  bucket = aws_s3_bucket.guardzen_demo.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_security_group" "guardzen_demo_sg" {
  name        = "guardzen-demo-sg"
  description = "Demo SG - hardened, no public SSH"

  ingress {
    description = "SSH from internal VPN range only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  egress {
    description = "Allow outbound HTTPS only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}