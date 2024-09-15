locals {
  container_name = "apache-server"
  container_port = 80
  tags = {
    Name         = "${var.main_organization}-ecs-cluster"
    Organization = var.main_organization
  }
}

# IAM Role for ECS EC2 Instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.main_organization}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.main_organization}-cluster"
  tags = local.tags
}


# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.main_organization}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.main_organization}-ecs-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([{
    name  = local.container_name
    image = "nginx:latest"
    # image     = "${aws_ecr_repository.repo.repository_url}:latest"
    essential = true
    memory    = 512
    cpu       = 256
    portMappings = [{
      containerPort = local.container_port
      hostPort      = 80
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.main_organization}-ecs-task"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  execution_role_arn = aws_iam_role.ecs_instance_role.arn

  task_role_arn = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.main_organization}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1

  launch_type = "EC2"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.main_organization}-ecs-task"
  retention_in_days = 7 # Set log retention as per your need
  tags = {
    Name         = "${var.main_organization}-ecs-task-log-group"
    Organization = var.main_organization
  }
}

# Security Group for ECS EC2 Instances
resource "aws_security_group" "ecs_instance_sg" {
  name   = "${var.main_organization}-ecs-instance-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow traffic from ALB SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.main_organization}-ecs-instance-sg"
  }
}

# Create Launch Template for EC2 instances to join the ECS Cluster
resource "aws_launch_template" "ecs_launch_template" {
  name          = "${var.main_organization}-ecs-launch-template"
  instance_type = "t2.medium"
  image_id      = data.aws_ami.ecs_optimized.id

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = data.terraform_remote_state.network.outputs.private_subnet_id
    security_groups             = [aws_security_group.ecs_instance_sg.id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
EOF
  )

  tags = {
    Name         = "${var.main_organization}-ecs-instance"
    Organization = var.main_organization
  }

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

# Create an Auto Scaling Group for ECS EC2 Instances
resource "aws_autoscaling_group" "ecs_asg" {
  name = "${var.main_organization}-ecs-asg"
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = [data.terraform_remote_state.network.outputs.private_subnet_id]

}

# ECS Instance Profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.main_organization}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

