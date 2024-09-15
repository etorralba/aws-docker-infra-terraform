# Create an Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "${var.main_organization}-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids
}

# Create a Security Group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

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
    Name         = "${var.main_organization}-alb-sg"
    Organization = var.main_organization
  }
}

# Create a Target Group for the Application Load Balancer
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.main_organization}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

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
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_tg.arn
    type             = "forward"
  }
}

