#########################
# ECS Cluster           #
#########################

resource "aws_ecs_cluster" "user_cluster" {
  name = "user-service-cluster"
}

#########################
# IAM Roles             #
#########################

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

resource "aws_iam_policy" "datadog_ecs_readonly" {
  name        = "datadog_ecs_readonly"
  description = "Allow Datadog agent to list and describe ECS resources"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datadog_ecs_readonly_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.datadog_ecs_readonly.arn
}

#########################
# ECS Task + Service    #
#########################

module "user_task_definition" {

  source = "DataDog/ecs-datadog/aws//modules/ecs_fargate"

  family       = "user-service"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512
  execution_role = {
    arn = aws_iam_role.task_execution_role.arn
  }
  task_role = {
    arn = aws_iam_role.task_role.arn
  }

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
    }
  ])

  # datadog configuration

  dd_api_key = var.datadog_api_key
  dd_site    = var.datadog_uri
  dd_dogstatsd = {
    enabled = true,
  }
  dd_apm = {
    enabled = true,
  }
  dd_log_collection = {
    enabled = true
    fluentbit_config = {
      api_key                          = var.datadog_api_key

      is_log_router_essential          = true
      is_log_router_dependency_enabled = true

      log_driver_configuration = {
        host_endpoint = "http-intake.logs.${var.datadog_uri}"
        tls = true
      }
    }
  }

}
