variable "env" {
    type = string
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the Fargate service"
}

variable "rds_endpoint" {
  type        = string
  description = "RDS endpoint for the application"
}

variable "rds_username" {
  type        = string
  description = "RDS username"
}

variable "rds_db_name" {
  type        = string
  description = "RDS database name"
}

variable "rds_master_secret_arn" {
  type        = string
  description = "Secrets Manager ARN containing the auto-generated master password"
}

variable "ecr_uri" {
  type = string
    description = "ECR URI for the Docker images"
}