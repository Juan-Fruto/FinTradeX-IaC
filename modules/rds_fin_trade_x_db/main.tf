resource "aws_db_instance" "fin-trade-x-rdb" {
  allocated_storage    = 10
  db_name              = "fin-trade-x-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = fin-trade-x-rds-dev
  password             = "abc123"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  multi_az = false
}