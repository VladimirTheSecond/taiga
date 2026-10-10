terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Remote state in the bucket from terraform/bootstrap/.
  # use_lockfile = native S3 locking (a .tflock object next to the state), so no DynamoDB table.
  # Backend blocks cannot use variables, so the bucket name is hardcoded.
  backend "s3" {
    bucket       = "taiga-tfstate-941791592956"
    key          = "taiga/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "taiga"
      Environment = "personal"
      ManagedBy   = "terraform"
    }
  }
}
