resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.project_name}-${var.environment}-eks"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-ec2"
  retention_in_days = 7
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn # Ensure this role exists
  log_destination_type = "cloud-watch-logs"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}-vpc-flow-logs" # Corrected name
  retention_in_days = 7
}

#  CloudWatch Logs Subscription Filter for EC2
resource "aws_cloudwatch_log_subscription_filter" "ec2_log_subscription_filter" {
  name            = "ec2-log-subscription-filter"
  log_group_name  = aws_cloudwatch_log_group.ec2_logs.name #  EC2 Log Group
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.log_stream.arn  # Send to Kinesis
}

#  CloudWatch Logs Subscription Filter for EKS
resource "aws_cloudwatch_log_subscription_filter" "eks_log_subscription_filter" {
  name            = "eks-log-subscription-filter"
  log_group_name  = aws_cloudwatch_log_group.eks_logs.name #  EKS Log Group
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.log_stream.arn  # Send to Kinesis
}

#  CloudWatch Logs Subscription Filter for VPC Flow Logs
resource "aws_cloudwatch_log_subscription_filter" "vpc_flow_log_subscription_filter" {
  name            = "vpc-flow-log-subscription-filter"
  log_group_name  = aws_cloudwatch_log_group.vpc_flow_logs.name #  VPC Flow Logs Group
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.log_stream.arn  # Send to Kinesis
}