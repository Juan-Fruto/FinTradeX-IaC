resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = var.ecs_cluster_id
  task_definition = var.task_definition_arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  # depends_on = [aws_ecs_task_definition.user_service]
}

# Data sources for default VPC subnets (public)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}