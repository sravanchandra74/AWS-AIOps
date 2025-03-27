resource "aws_sagemaker_notebook_instance" "ml_notebook" {
  name          = "${var.project_name}-${var.environment}-ml-notebook"
  instance_type = "ml.t2.medium"
  role_arn      = aws_iam_role.sagemaker_notebook_role.arn

  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.notebook_lifecycle.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ml-notebook"
  }

  depends_on = [aws_iam_role_policy_attachment.sagemaker_notebook_policy, aws_sagemaker_notebook_instance_lifecycle_configuration.notebook_lifecycle]
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "notebook_lifecycle" {
  name = "${var.project_name}-${var.environment}-notebook-lifecycle"

  on_create = <<EOF
    #!/bin/bash
    set -e
    pip install boto3 sagemaker pandas scikit-learn
    # Add any other setup commands here
  EOF

  on_start = <<EOF
    #!/bin/bash
    set -e
    echo "Starting notebook..."
  EOF
}