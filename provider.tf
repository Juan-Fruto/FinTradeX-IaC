terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.19.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "fargate_user" {
  source = "./modules/fargate_user"
  providers = {
    aws = aws
  }
}