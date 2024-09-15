output "db_instance_endpoint" {
  value = aws_db_instance.main_postgres_db.endpoint
}

output "db_instance_port" {
  value = aws_db_instance.main_postgres_db.port
}

output "db_instance_arn" {
  value = aws_db_instance.main_postgres_db.arn
}

output "db_security_group_id" {
  value = aws_security_group.rds_sg.id
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}