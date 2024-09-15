resource "aws_ecr_repository" "repo" {
  name = "${var.main_organization}-repo"
  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Name         = "${var.main_organization}-repo"
    Organization = var.main_organization
  }
}