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

#########################
# ECS Cluster           #
#########################

resource "aws_ecs_cluster" "user_cluster" {
  name = "user-service-cluster"
}

#########################
# IAM Roles             #
#########################

# IAM role for task execution (pulling images, writing logs)
resource "aws_iam_role" "task_execution_role" {
  name = "user_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# (Optional) task role if container needs AWS API access in future
resource "aws_iam_role" "task_role" {
  name = "user_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Effect = "Allow"
    }]
  })
}

#########################
# ECS Task + Service    #
#########################

resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  requires_compatibilities  = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "user"
      image     = "699475922534.dkr.ecr.us-east-1.amazonaws.com/dev/find-trade-x-rep:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8082
          hostPort      = 8082
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = var.rds_endpoint },
        { name = "DB_USER", value = var.rds_username },
        { name = "DB_NAME", value = var.rds_db_name },
        { name = "SERVER_PORT", value = "8082" }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = var.rds_master_secret_arn
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.user_cluster.id
  task_definition = aws_ecs_task_definition.user_service.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [var.security_group_id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.user_service]
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

output "ecs_service_name" {
  value = aws_ecs_service.user_service.name
}
