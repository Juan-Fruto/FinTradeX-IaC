variable "db_username" {
  type        = string
  description = "Master username for the database"
  default     = "fintradex"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security groups to associate with the RDS instance"
}

resource "aws_db_instance" "fin_trade_x_rdb" {
  allocated_storage    = 10
  db_name              = "fintradexdb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro" # low cost
  username             = var.db_username
  manage_master_user_password = true
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  multi_az             = false
  publicly_accessible  = false
  vpc_security_group_ids = var.vpc_security_group_ids
}

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
  value = aws_db_instance.fin_trade_x_rdb.master_user_secret
}
