terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key

  profile = var.aws_access_key_id == null && var.aws_secret_access_key == null ? var.aws_profile: null

  region = var.region
}
