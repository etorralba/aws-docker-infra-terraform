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

data "aws_iam_policy_document" "ecs_instance_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs_service_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Policy document for ECS Service to access Secrets Manager
data "aws_iam_policy_document" "ecs_secret_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      data.terraform_remote_state.database.outputs.db_secret_id
    ]
  }
}

# Policy document for ECS task to access RDS
data "aws_iam_policy_document" "ecs_rds_policy" {
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:ModifyDBInstance",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:CreateDBSnapshot",
      "rds:DeleteDBSnapshot"
    ]
    resources = [
      data.terraform_remote_state.database.outputs.db_instance_arn
    ]
  }
}

# Policy document for ECS task execution role
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

