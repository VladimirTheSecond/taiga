# Persistent layer: applied once, never destroyed by `make down`.
# Holds resources that must outlive the ephemeral main stack.
#
# State is local on purpose: the S3 bucket for remote state is created here,
# so it cannot be the backend for its own creation (chicken and egg).
terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "taiga"
      Environment = "personal"
      ManagedBy   = "terraform"
      Stack       = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}
