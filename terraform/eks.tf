resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.project_name}-${var.environment}-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.project_name}-${var.environment}-nodegroup"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
  capacity_type   = "ON_DEMAND"
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  depends_on = [aws_eks_cluster.eks_cluster]
}

#  Example EKS Addon for Logging
resource "aws_eks_addon" "aws_logging" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name         = "aws-logging"
  addon_version      = "v1.0.2-eksmanifest-1.18" #  Specify Version.  Find the correct version for your EKS version.
  configuration_values = jsonencode({
    "enable" : true,
    "logGroupName" : "/aws/eks/${var.project_name}-${var.environment}-eks"
  })
}