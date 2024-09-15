resource "aws_security_group" "alb_sg" {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.main_organization}-alb-sg"
  }
}

resource "aws_lb" "app_lb" {
  name               = "${var.main_organization}-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.terraform_remote_state.network.outputs.public_subnet_a_id, data.terraform_remote_state.network.outputs.public_subnet_b_id, ]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.main_organization}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    path                = "/"
    interval            = 30        # Time between each health check (in seconds)
    timeout             = 15        # Time before marking a health check as failed (in seconds)
    healthy_threshold   = 2         # Number of successful health checks before considering healthy
    unhealthy_threshold = 3         # Number of failed health checks before considering unhealthy
    matcher             = "200-299" # HTTP status codes to consider healthy
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

