output "ecs_service_name" {
  value = aws_ecs_service.user_service.name
}

output "user_service_log_group_name" {
  value = aws_cloudwatch_log_group.user_service.name
}