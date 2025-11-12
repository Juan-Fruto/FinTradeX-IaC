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
  publicly_accessible  = true
  vpc_security_group_ids = var.vpc_security_group_ids
}