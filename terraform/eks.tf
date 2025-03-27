# eks.tf
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.project_name}-${var.environment}-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.subnet_2.id, aws_subnet.subnet_3.id] # Replace with your subnets
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}