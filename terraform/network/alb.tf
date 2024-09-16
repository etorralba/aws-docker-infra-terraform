locals {
  environments = ["dev", "prod"]
}

# Create an Application Load Balancer
resource "aws_lb" "app_lb" {
  for_each = toset(local.environments)

  name               = "${var.main_organization}-${each.key}-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[each.key].id] # Fix here
  subnets            = aws_subnet.public_subnet[*].id

  tags = {
    Organization = var.main_organization
    Environment  = each.key
  }
}

# Create a Security Group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  for_each = toset(local.environments)

  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name         = "${var.main_organization}-${each.key}-alb-sg"
    Organization = var.main_organization
    Environment  = each.key
  }
}

# Create a Target Group for the Application Load Balancer
resource "aws_lb_target_group" "app_tg" {
  for_each = toset(local.environments)

  name     = "${var.main_organization}-${each.key}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  tags = {
    Organization = var.main_organization
    Environment  = each.key
  }
}

# Create a listener for the load balancer
resource "aws_lb_listener" "app_lb_listener" {
  for_each = toset(local.environments)

  load_balancer_arn = aws_lb.app_lb[each.key].arn # Fix here
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_tg[each.key].arn # Fix here
    type             = "forward"
  }

  tags = {
    Organization = var.main_organization
    Environment  = each.key
  }
}