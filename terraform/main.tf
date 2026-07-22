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

resource "aws_s3_bucket_acl" "guardzen_demo_acl" {
  bucket = aws_s3_bucket.guardzen_demo.id
  acl    = "private"
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
  description = "Demo SG - hardened"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}