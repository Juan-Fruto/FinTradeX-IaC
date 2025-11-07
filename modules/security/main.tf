data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "fargate_instance_sg" {
  name        = "fargate-instance-sg"
  description = "Security group for public Fargate instances"
  vpc_id      = data.aws_vpc.default.id
}

# Ingress rule for the public REST API (container port 8082)
resource "aws_security_group_rule" "allow_api_inbound" {
  type              = "ingress"
  from_port         = 8082
  to_port           = 8082
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = aws_security_group.fargate_instance_sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = aws_security_group.fargate_instance_sg.id
}

# RDS Security Group allowing MySQL from Fargate SG
resource "aws_security_group" "rds_sg" {
  name        = "fintradex-rds-sg"
  description = "Allow MySQL from Fargate user service"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "rds_ingress_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.fargate_instance_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "rds_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = aws_security_group.rds_sg.id
}

output "fargate_instance_sg_id" {
  value = aws_security_group.fargate_instance_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
