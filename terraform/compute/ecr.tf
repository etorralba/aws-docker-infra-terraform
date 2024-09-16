# Create ECR repository
resource "aws_ecr_repository" "repo" {
  name = "${var.main_organization}-${var.environment}-repo"
  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Organization = var.main_organization
    Environment  = var.environment
  }
}