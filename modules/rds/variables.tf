variable "db_username" {
  type        = string
  description = "Master username for the database"
  default     = "fintradex"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security groups to associate with the RDS instance"
}