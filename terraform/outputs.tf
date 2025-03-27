output "s3_bucket_name" {
  value = aws_s3_bucket.log_data_bucket.bucket
}

output "sagemaker_notebook_name" {
  value = aws_sagemaker_notebook_instance.ml_notebook.name
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}