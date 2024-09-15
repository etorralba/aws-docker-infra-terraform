// Network state
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "${var.account_id}-tf-state"
    key    = "terraform.${var.main_organization}_network.tfstate"
    region = var.region
  }
}

// Database state
data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = "${var.account_id}-tf-state"
    key    = "terraform.${var.main_organization}_database.tfstate"
    region = var.region
  }
}

# Data source for ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  most_recent = true
  owners      = ["amazon"]
}