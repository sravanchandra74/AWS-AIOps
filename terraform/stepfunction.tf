resource "aws_sfn_state_machine" "anomaly_remediation" {
  name     = "${var.project_name}-${var.environment}-anomaly-remediation"
  role_arn = aws_iam_role.step_functions_role.arn
  definition = jsonencode({
    Comment = "Anomaly Remediation Pipeline",
    StartAt = "DetectAnomaly",
    States = {
      DetectAnomaly = {
        Type = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = "anomaly-detection-lambda"
        },
        Next = "Remediate"
      },
      Remediate = {
        Type = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = "anomaly-remediation-lambda"
        },
        End = true
      }
    }
  })
  depends_on = [aws_iam_role.step_functions_role]
}