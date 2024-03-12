terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    archive = {
      source = "archive"
      version = "~> 2.4"
    }
  }
}


provider "aws" {
  region = "ap-south-1"
  allowed_account_ids = ["000000000000"]
}
