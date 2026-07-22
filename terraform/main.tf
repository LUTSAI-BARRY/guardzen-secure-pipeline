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

# VULN: publicly readable/writable S3 bucket + no encryption.
# tfsec/Checkov should flag both the public ACL and missing
# server-side encryption as high-severity findings.
resource "aws_s3_bucket" "guardzen_demo" {
  bucket = "guardzen-demo-reports-bucket"
}

resource "aws_s3_bucket_acl" "guardzen_demo_acl" {
  bucket = aws_s3_bucket.guardzen_demo.id
  acl    = "public-read-write"
}

# VULN: security group open to the world on SSH.
resource "aws_security_group" "guardzen_demo_sg" {
  name        = "guardzen-demo-sg"
  description = "Demo SG with intentional over-permissive rule"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
