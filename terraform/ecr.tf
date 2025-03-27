resource "aws_ecr_repository" "lambda_repository" {
  name                 = "${var.project_name}-${var.environment}-lambda-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  } # Added newline here
}

resource "aws_ecr_repository" "sagemaker_repository" {
  name                 = "${var.project_name}-${var.environment}-sagemaker-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  } # Added newline here
}