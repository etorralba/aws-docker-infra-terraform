# RDS PostgreSQL instance
resource "aws_db_instance" "main_postgres_db" {
  allocated_storage     = 20
  max_allocated_storage = 100

  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true

  tags = {
    Name         = "${var.main_organization}-${var.environment}-rds"
    Organization = var.main_organization
  }
}

# DB subnet group for RDS
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.main_organization}-${var.environment}-db-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  tags = {
    Organization = var.main_organization
  }
}

# Security group for RDS instance
resource "aws_security_group" "rds_sg" {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.main_organization}-${var.environment}-rds-sg"
    Organization = var.main_organization
  }
}

resource "random_id" "random_prefix" {
  byte_length = 6
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "${var.main_organization}-${var.environment}-rds-credentials-${random_id.random_prefix.hex}"
  tags = {
    Organization = var.main_organization
  }
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    host     = aws_db_instance.main_postgres_db.endpoint
    port     = "5432"
    dbname   = aws_db_instance.main_postgres_db.db_name
    username = var.db_username
    password = var.db_password
  })
}
