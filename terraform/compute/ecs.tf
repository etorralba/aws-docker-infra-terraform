locals {
  container_name = "apache-server"
  container_port = 80
  image_name     = "${aws_ecr_repository.repo.repository_url}:latest"
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.main_organization}-ecs-cluster"
  tags = {
    Organization = var.main_organization
  }
}

# ECS Instance Profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.main_organization}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name

  tags = {
    Organization = var.main_organization
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.main_organization}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = local.container_name
    image     = local.image_name
    essential = true
    memory    = 512
    cpu       = 256
    portMappings = [{
      containerPort = local.container_port
      hostPort      = 80
    }]
    secrets = [
      {
        name      = "DB_SECRET"
        valueFrom = "${data.terraform_remote_state.database.outputs.db_secret_id}"
      },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.main_organization}-ecs-task"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }

  }])

  tags = {
    Name         = "${var.main_organization}-ecs-task"
    Organization = var.main_organization
  }
}

resource "aws_ecs_service" "ecs_service" {
  name                               = "${var.main_organization}-service"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.task.arn
  desired_count                      = 1
  launch_type                        = "EC2"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  load_balancer {
    target_group_arn = data.terraform_remote_state.network.outputs.app_tg_arn
    container_name   = local.container_name
    container_port   = local.container_port
  }
  iam_role = aws_iam_role.ecs_service_role.arn
  tags = {
    Name         = "${var.main_organization}-ecs-service"
    Organization = var.main_organization
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.main_organization}-ecs-task"
  retention_in_days = 7
  tags = {
    Name         = "${var.main_organization}-ecs-task-log-group"
    Organization = var.main_organization
  }
}
