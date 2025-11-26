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

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  default = "dev"
}

variable "ecr_uri" {
  description = "ECR URI for the Docker images"
  type        = string
}

variable "datadog_uri" {
  description = "Datadog URI, varies by region"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API Key"
  type        = string
  sensitive   = true
}

#########################
# Security             #
#########################

module "security" {
  source = "../../modules/security"
}

#########################
# Database             #
#########################

module "rds_fin_trade_x_db" {
  source                = "../../modules/rds"
  vpc_security_group_ids = [module.security.rds_sg_id]
}


#########################
# Services             #
#########################

module "ecs_cluster" {
  source = "../../modules/ecs/cluster"
}

# user service

module "user_task_definition" {
  source = "../../modules/ecs/task"

  rds_endpoint          = module.rds_fin_trade_x_db.rds_endpoint
  rds_username          = module.rds_fin_trade_x_db.rds_username
  rds_db_name           = module.rds_fin_trade_x_db.rds_db_name
  rds_master_secret_arn = module.rds_fin_trade_x_db.rds_master_secret_arn

  env                   = var.env
  ecr_uri               = var.ecr_uri

  datadog_uri = var.datadog_uri
  datadog_api_key = var.datadog_api_key
}

module "user_ecs_service" {
  source = "../../modules/ecs/service"

  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id
  task_definition_arn = module.user_task_definition.task_definition_arn
  security_group_id = module.security.fargate_instance_sg_id
}