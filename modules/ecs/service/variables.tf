variable "ecs_cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the ECS Task Definition resource"
  type        = string
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the Fargate service"
}