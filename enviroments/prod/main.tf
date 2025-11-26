terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.19.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "env" "default" {
  description = "Environment name (e.g., dev, staging, prod)"
  value = "prod"
}

variable "ecr_uri" {
  description = "ECR URI for the Docker images"
  type        = string
}

module "security" {
  source = "./modules/security"
}

module "rds_fin_trade_x_db" {
  source                = "./modules/rds_fin_trade_x_db"
  vpc_security_group_ids = [module.security.rds_sg_id]
}

module "fargate_user" {
  source = "./modules/fargate_user"

  security_group_id     = module.security.fargate_instance_sg_id
  rds_endpoint          = module.rds_fin_trade_x_db.rds_endpoint
  rds_username          = module.rds_fin_trade_x_db.rds_username
  rds_db_name           = module.rds_fin_trade_x_db.rds_db_name
  rds_master_secret_arn = module.rds_fin_trade_x_db.rds_master_secret_arn

  env                   = data.env
  ecr_uri               = var.ecr_uri
}