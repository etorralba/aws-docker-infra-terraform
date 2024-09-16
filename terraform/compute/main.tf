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
    subnet_id                   = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
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

  vpc_zone_identifier = data.terraform_remote_state.network.outputs.private_subnet_ids
}

# Security Group for ECS EC2 Instances
resource "aws_security_group" "ecs_instance_sg" {
  name   = "${var.main_organization}-ecs-instance-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.network.outputs.alb_sg_id] # Allow traffic from ALB SG
  }

  # Outbound rule to allow ECS to connect to RDS on port 5432
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.database.outputs.db_security_group_id] # Reference the RDS security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.main_organization}-ecs-instance-sg"
    Organization = var.main_organization
  }
}

data "aws_security_group" "existing_rds_sg" {
  id = data.terraform_remote_state.database.outputs.db_security_group_id
}

resource "aws_security_group_rule" "rds_to_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.existing_rds_sg.id
  source_security_group_id = aws_security_group.ecs_instance_sg.id # Reference the ECS security group
}
