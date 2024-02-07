# EKS Cluster
resource "aws_eks_cluster" "inforiver_eks" {
  name                      = "${var.project}-cluster"
  role_arn                  = aws_iam_role.cluster_role.arn
  version                   = "1.27" #Kubernetes version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  vpc_config {
    subnet_ids              = [aws_subnet.public.id,aws_subnet.application.id,aws_subnet.database.id]
    security_group_ids      = [aws_security_group.eks_security_group.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
    Name                    = "${var.project}-Cluster",
    Description             = "Created for the ${var.project} application"
  }

  depends_on                = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_vpc.inforiver_vpc,aws_subnet.public,aws_subnet.application,aws_subnet.database,
    aws_security_group.eks_security_group
  ]
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = data.tls_certificate.eks_cluster.url
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster_role" {
  name                      = "${var.project}-Cluster-Role"

  assume_role_policy        = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn                = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role                      = aws_iam_role.cluster_role.name
  depends_on                = [
    aws_iam_role.cluster_role
  ]
}

# EKS worker node IAM Role
resource "aws_iam_role" "workernode_role" {
  name                      = "${var.project}-Workernode-Role"
  assume_role_policy        = jsonencode({

    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:AssumeRoleWithWebIdentity"
      ] 
        Principal = {
          Service   = "ec2.amazonaws.com",
          Federated = aws_iam_openid_connect_provider.oidc.arn
      }
           
      },
   ]
  })
  depends_on                = [
    aws_iam_openid_connect_provider.oidc
  ]
}

# Bucket permission policy for the application

resource "aws_iam_policy" "turing_bucket_policy" {
  name        = "${var.project}-bucket-policy"
  description = "Bucket permission policy for the application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
       {
           "Sid": "VisualEditor0",
           "Effect": "Allow",
           "Action": [
               "s3:PutObject",
               "s3:GetObject",
               "s3:ListBucket",
               "s3:DeleteObject"
           ],
           "Resource": [
               "arn:aws:s3:::inforiver-*",
               "arn:aws:s3:::inforiver-*/*"
            ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "workernode_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", 
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  policy_arn                = each.value
  role                      = aws_iam_role.workernode_role.name
  depends_on                = [
    aws_iam_role.workernode_role
    
  ]
}

resource "aws_iam_role_policy_attachment" "workernode_bucket_policy" {

  policy_arn                = aws_iam_policy.turing_bucket_policy.arn
  role                      = aws_iam_role.workernode_role.name
  depends_on                = [
    aws_iam_role.workernode_role,
    aws_iam_policy.turing_bucket_policy

    
  ]
}

resource "aws_launch_template" "workernodelaunchtemplate" {
  name = "${var.project}-worker-node-launchtemplate"
  description = "Launch template for the workernode role."
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
      delete_on_termination = "true"
      encrypted = "false"
    }
  }

  instance_type = "${var.instance_type}"
  key_name = aws_key_pair.EKS_workernode_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.alb_securitygroup.id,aws_security_group.eks_security_group.id]

}

# EKS Cluster Node group 
resource "aws_eks_node_group" "workernode" {
  cluster_name              = aws_eks_cluster.inforiver_eks.name
  node_group_name           = "${var.project}-nodegroup"
  node_role_arn             = "${aws_iam_role.workernode_role.arn}"
  subnet_ids                = [aws_subnet.application.id]
  ami_type                  = "AL2_x86_64"
  capacity_type             = "ON_DEMAND"
  launch_template{
    id                      = aws_launch_template.workernodelaunchtemplate.id
    version                 = aws_launch_template.workernodelaunchtemplate.latest_version
  }
  scaling_config {
    desired_size            = 1
    max_size                = 2
    min_size                = 1
  }

  update_config {
    max_unavailable         = 1
  }
    
  tags = {
    Name                      = "${var.project}-workernode"
  }
  depends_on                  = [
    aws_eks_cluster.inforiver_eks,
    aws_iam_role_policy_attachment.workernode_policy,
    aws_launch_template.workernodelaunchtemplate

  ]
}

#EKS add-on

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.inforiver_eks.name
  addon_name                  = "coredns"

  depends_on            = [
    aws_eks_node_group.workernode
    ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.inforiver_eks.name
  addon_name                  = "vpc-cni"

  depends_on            = [
    aws_eks_node_group.workernode
    ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.inforiver_eks.name
  addon_name                  = "kube-proxy"

  depends_on            = [
    aws_eks_node_group.workernode
    ]
}

resource "aws_eks_addon" "cloud-watch" {
  cluster_name                = aws_eks_cluster.inforiver_eks.name
  addon_name                  = "amazon-cloudwatch-observability"

  depends_on            = [
    aws_eks_node_group.workernode
    ]
}

