terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {

  region     = "${var.region}"

  # for authentication
}

provider "kubernetes" {
  host                   = aws_eks_cluster.inforiver_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.inforiver_eks.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.inforiver_eks.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.inforiver_eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.inforiver_eks.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.inforiver_eks.name]
      command     = "aws"
    }
  }
}