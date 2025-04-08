resource "aws_lambda_function" "anomaly_detection_lambda" {
  function_name = "${var.project_name}-${var.environment}-anomaly-detection-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:anomaly-detection-latest" # Verify
  role          = aws_iam_role.lambda_role.arn # Use the correct role

  timeout = 30
  memory_size = 512

  depends_on = [aws_ecr_repository.lambda_repository, aws_iam_role.lambda_role]
}

resource "aws_lambda_function" "anomaly_remediation_lambda" {
  function_name = "${var.project_name}-${var.environment}-anomaly-remediation-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:anomaly-remediation-latest"  # Verify
  role          = aws_iam_role.lambda_role.arn # Use the correct role

  timeout = 30
  memory_size = 512

  depends_on = [aws_ecr_repository.lambda_repository, aws_iam_role.lambda_role]
}

# Lambda function to append logs
resource "aws_lambda_function" "log_appender_lambda" {
  function_name    = "${var.project_name}-${var.environment}-log-appender"
  runtime          = "python3.9"  # Or a later version
  handler          = "log_appender.lambda_handler" #  log_appender.py file, lambda_handler function
  role             = aws_iam_role.log_appender_lambda_role.arn
  timeout          = 300 # increased timeout
  memory_size      = 256

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.log_data_bucket.bucket
    }
  }
  depends_on = [aws_iam_role_policy_attachment.log_appender_lambda_policy_attachment]
}

# Kinesis event source mapping to trigger lambda
resource "aws_lambda_event_source_mapping" "kinesis_event_source_mapping" {
  function_name    = aws_lambda_function.log_appender_lambda.arn
  event_source_arn = aws_kinesis_stream.log_stream.arn
  starting_position = "LATEST"
  batch_size       = 100
}