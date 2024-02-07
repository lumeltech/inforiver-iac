output "cluster_name" {
  value = aws_eks_cluster.inforiver_eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.inforiver_eks.endpoint
}

output "workernode_role_arn" {
  value = aws_iam_role.workernode_role.arn
}
