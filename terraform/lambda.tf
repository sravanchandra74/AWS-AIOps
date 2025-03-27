resource "aws_lambda_function" "anomaly_detection_lambda" {
  function_name = "${var.project_name}-${var.environment}-anomaly-detection-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:anomaly-detection-latest"
  role          = aws_iam_role.lambda_role.arn

  timeout = 30
  memory_size = 512

  depends_on = [aws_ecr_repository.lambda_repository, aws_iam_role.lambda_role]
}

resource "aws_lambda_function" "anomaly_remediation_lambda" {
  function_name = "${var.project_name}-${var.environment}-anomaly-remediation-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:anomaly-remediation-latest"
  role          = aws_iam_role.lambda_role.arn

  timeout = 30
  memory_size = 512

  depends_on = [aws_ecr_repository.lambda_repository, aws_iam_role.lambda_role]
}