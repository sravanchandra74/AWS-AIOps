# IAM Role for Log Streaming (EC2, EKS, etc.)
#  IAM Role for EC2 Log Streaming
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "${var.project_name}-${var.environment}-ec2-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
         Condition = {
          StringEquals = {
            "sts:ExternalId" = "CloudWatchAgent"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_cloudwatch_policy" {
  name        = "${var.project_name}-${var.environment}-ec2-cloudwatch-policy"
  description = "Allows EC2 instances to send logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${var.project_name}-${var.environment}-ec2:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_role_policy_attachment" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = aws_iam_policy.ec2_cloudwatch_policy.arn
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_instance_profile" {
  name = "${var.project_name}-${var.environment}-ec2-cloudwatch-instance-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

#  IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name        = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  description = "Allows VPC Flow Logs to write to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/${var.project_name}-${var.environment}-vpc-flow-logs:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs_role_policy_attachment" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.vpc_flow_logs_policy.arn
}

resource "aws_iam_role" "log_streaming_role" {
  name = "log-streaming-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_streaming_policy" {
  role       = aws_iam_role.log_streaming_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # Adjust as needed
}

resource "aws_iam_role_policy_attachment" "s3_write_policy" {
    role = aws_iam_role.log_streaming_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# IAM Role for SageMaker Training and Endpoint
resource "aws_iam_role" "sagemaker_role" {
  name = "sagemaker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# IAM Role for Kinesis
resource "aws_iam_role" "kinesis_role" {
  name = "kinesis-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "kinesis.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis_policy" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

#  IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role" #  More specific name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

#  IAM Policy for Lambda function
resource "aws_iam_policy" "log_appender_lambda_policy" {
  name = "log-appender-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = "${aws_s3_bucket.log_data_bucket.arn}/*"
      },
       {
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream"
        ],
        Effect = "Allow",
        Resource = aws_kinesis_stream.log_stream.arn
      }
    ]
  })
}

#  Attach policy to role
resource "aws_iam_role_policy_attachment" "log_appender_lambda_policy_attachment" {
  role       = aws_iam_role.log_appender_lambda_role.name
  policy_arn = aws_iam_policy.log_appender_lambda_policy.arn
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "step-functions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess" # Adjust to your needs
}
