resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/user-service-${var.env}"
  retention_in_days = 5
}