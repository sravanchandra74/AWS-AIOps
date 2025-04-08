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

    # 1. Check if virtualenv is installed, install if not
    if ! command -v virtualenv &>/dev/null; then
      echo "virtualenv not found, installing..."
      pip install virtualenv
    else
      echo "virtualenv is already installed."
    fi

    # 2. Create a virtual environment
    VENV_NAME="anomaly_detection_env"
    if [ ! -d "\$VENV_NAME" ]; then
      echo "Creating virtual environment \$VENV_NAME..."
      virtualenv "\$VENV_NAME"
    else
      echo "Virtual environment \$VENV_NAME already exists."
    fi

    # 3. Activate the virtual environment and install requirements
    echo "Activating virtual environment and installing requirements..."
    source "\$VENV_NAME/bin/activate"
    pip install -r /home/ec2-user/SageMaker/requirements.txt
    # Copy requirements.txt if needed
    if ! [ -f "/home/ec2-user/SageMaker/requirements.txt" ]; then
      echo "Copying requirements.txt to /home/ec2-user/SageMaker/"
      mkdir -p /home/ec2-user/SageMaker/
      cp /home/ec2-user/SageMaker/requirements.txt /home/ec2-user/SageMaker/requirements.txt
    fi

    echo "Virtual environment setup and requirements installed."
  EOF

  on_start = <<EOF
    #!/bin/bash
    set -e
    echo "Starting notebook..."
    source /home/ec2-user/anomaly_detection_env/bin/activate
    echo "Activated virtual environment for notebook start."
  EOF
}
