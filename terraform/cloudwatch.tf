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
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
  log_destination_type = "cloud-watch-logs"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 7
}