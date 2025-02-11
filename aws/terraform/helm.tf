resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.11.0"
  namespace  = "kube-system"
  timeout    = "300"
  wait       = "false"
  
  set {
    name  = "clusterName"
    value = "${var.project}-cluster"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  depends_on            = [
    aws_eks_node_group.workernode
    ]
}

resource "helm_release" "inforiver" {
  name       = "inforiverdeployment"
  repository = "https://newmannbritto.github.io/Turing-Helm"
  chart      = "inforiver"
  version    = "0.1.0"
  timeout    = "300"
  wait       = "false"

  set {
    name  = "image.tag"
    value = var.imagetag
  }

  set {
    name  = "env.ADMIN_PORTAL_URL"
    value = var.AdminPortalURL
  }

  set {
    name  = "env.APP_HOST"
    value = var.AppHost
  }  

  set {
    name  = "env.AWS_REGION"
    value = var.region
  }  

  set {
    name  = "env.BLOB_CONTAINER_NAME"
    value = var.S3BucketName
  }  

  set {
    name  = "env.BOOTSTRAP_ON_PREMISE_WORKSPACE_ADMIN"
    value = var.WorkspaceAdministratorEmail
  }  

  set {
    name  = "env.BOOTSTRAP_ON_PREMISE_WORKSPACE_DOMAIN"
    value = var. WorkspaceDomain
  }  

  set {
    name  = "env.BOOTSTRAP_ON_PREMISE_WORKSPACE_LICENSE"
    value = var.WorkspaceLicenseKey
  }  

  set {
    name  = "env.BOOTSTRAP_ON_PREMISE_WORKSPACE_NAME"
    value = var.WorkspaceName
  }  

  set {
    name  = "env.DB_HOST"
    value = aws_db_instance.turing_db.address
  }  

 set {
    name  = "env.DB_NAME"
    value = "Turingdb"
  }  

  set {
    name  = "env.DB_PASS"
    value = var.db_admin_password
  }  

  set {
    name  = "env.DB_USER"
    value = var.db_admin_username
  }  

  set {
    name  = "env.DOCKER_REGISTRY_SERVER_PASSWORD"
    value = var.Dockerpwd
  }  

  set {
    name  = "env.FABRIC_WAREHOUSE_STORAGE_ACCOUNT_NAME"
    value = var.FabricStorageAccountName
  } 

  set {
    name  = "env.FABRIC_WAREHOUSE_STORAGE_ACCOUNT_KEY"
    value = var.FabricStorageAccountKey
  } 

  set {
    name  = "env.O365_APP_CLIENT_ID"
    value = var.Appclientid
  }  

  set {
    name  = "env.O365_APP_SECRET_ID"
    value = var.Appsecretid
  }  

  set {
    name  = "env.O365_APP_TENANT_ID"
    value = var.Apptenantid
  }  

  set {
    name  = "env.PORT"
    value = "12000"
  }  

  set {
    name  = "env.REDIS_HOST"
    value = aws_elasticache_replication_group.elastic_cache.primary_endpoint_address
  }  

  set {
    name  = "env.REDIS_PASSWORD"
    value = var.redis_auth_token
  }  

  set {
    name  = "env.REDIS_PORT"
    value = 6379
  }  

  set {
    name  = "env.SMTP_API_KEY"
    value = var.SMTPAPIKey
  }  

  set {
    name  = "env.SMTP_HOST"
    value = var.SMTPHost
  }  

  set {
    name  = "env.SMTP_PORT"
    value = 2525
  }  

  set {
    name  = "env.SMTP_USERNAME"
    value = var.SMTPUsername
  }  

  set {
    name  = "env.SMTP_SERVICE"
    value = var.SMTPservice
  }  

  set {
    name  = "env.WEBHOOK_KEY"
    value = var.WebHookKey
  }  

  set {
    name  = "imageCredentials.password"
    value = var.Dockerpwd
  }  

  set {
    name  = "loadbalancer.SG_ARN"
    value = aws_security_group.alb_securitygroup.id
  } 

  set {
    name  = "loadbalancer.SSL_ARN"
    value = var.SSL_ARN
  } 

  set {
    name  = "loadbalancer.NAME"
    value = "${var.project}-loadbalancer"
  } 

  set {
    name  = "role.ROLE_ARN"
    value = aws_iam_role.workernode_role.arn
  } 

  set {
    name  = "pv.efs_id"
    value = aws_efs_file_system.inforiver_efs.id
  } 


  depends_on            = [
    aws_eks_node_group.workernode,
    aws_instance.jump_box,
    helm_release.aws-load-balancer-controller
    ]
}