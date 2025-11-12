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

# Allow execution role to read the DB password secret from Secrets Manager
resource "aws_iam_role_policy" "task_execution_secrets" {
  name = "ecs_task_execution_read_rds_secret"
  role = aws_iam_role.task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        Resource = var.rds_master_secret_arn
      }
    ]
  })
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
# Logging               #
#########################

# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/user-service-${var.env}"
  retention_in_days = 5
}

# Current AWS region to configure awslogs
data "aws_region" "current" {}

#########################
# ECS Task + Service    #
#########################

resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "user"
      image     = "${var.ecr_uri}/${var.env}/find-trade-x-rep:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8082
          hostPort      = 8082
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "FIN_TRADE_X_RDB_URL", value = "${var.rds_endpoint}/${var.rds_db_name}" },
        { name = "FIN_TRADE_X_RDB_USERNAME", value = var.rds_username },
      ]
      secrets = [
        {
          name      = "FIN_TRADE_X_RDB_PASSWORD"
          valueFrom = "${var.rds_master_secret_arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.user_service.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "user"
        }
      }
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
    subnets          = data.aws_subnets.default.ids
    security_groups  = [var.security_group_id]
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
