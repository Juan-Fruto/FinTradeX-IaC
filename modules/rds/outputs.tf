output "rds_endpoint" {
  value = aws_db_instance.fin_trade_x_rdb.endpoint
}

output "rds_username" {
  value = var.db_username
}

output "rds_db_name" {
  value = aws_db_instance.fin_trade_x_rdb.db_name
}

# Expose the Secrets Manager ARN for the generated master password
output "rds_master_secret_arn" {
  value     = aws_db_instance.fin_trade_x_rdb.master_user_secret[0].secret_arn
  sensitive = true
}