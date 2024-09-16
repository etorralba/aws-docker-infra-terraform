# ECS Instance Role
resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.main_organization}-${var.environment}-ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role.json
  tags = {
    Organization = var.main_organization
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ECS Service Role
resource "aws_iam_role" "ecs_service_role" {
  name = "${var.main_organization}-${var.environment}-ecs-service-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_service_assume_role.json
  tags = {
    Organization = var.main_organization
  }
}

resource "aws_iam_role_policy_attachment" "ecs_service_policy" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "ecs_service_cloudwatch_policy" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.main_organization}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags = {
    Organization = var.main_organization
  }
}

resource "aws_iam_role_policy" "ecs_task_rds_policy" {
  name   = "${var.main_organization}-ecs_task-rds-policy"
  role   = aws_iam_role.ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_rds_policy.json
}

resource "aws_iam_role_policy" "ecs_task_secret_policy" {
  name   = "${var.main_organization}-ecs_task-secret-policy"
  role   = aws_iam_role.ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_secret_policy.json
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.main_organization}-${var.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
  tags = {
    Organization = var.main_organization
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_rds_policy" {
  name   = "${var.main_organization}-ecs-task-execution-rds-policy"
  role   = aws_iam_role.ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.ecs_rds_policy.json
}

resource "aws_iam_role_policy" "ecs_task_execution_secret_policy" {
  name   = "${var.main_organization}-ecs-task-execution-secret-policy"
  role   = aws_iam_role.ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.ecs_secret_policy.json
}
