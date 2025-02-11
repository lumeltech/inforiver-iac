# RDS Mssql database for Inforiver.

resource "aws_db_instance" "turing_db" {

  license_model              = "license-included"
  engine                     = "sqlserver-web"
  engine_version             = "15.00.4073.23.v1"
  publicly_accessible        = false
  multi_az                   = false
  auto_minor_version_upgrade = true
  availability_zone          = data.aws_availability_zones.available.names[1]
  storage_type               = "gp2" 
  port                       = 1433
  network_type               = "IPV4"  
  identifier                 = "${var.db_identifiername}"     
  instance_class             = "${var.db_instance_class}"  
  username                   = "${var.db_admin_username}"
  password                   = "${var.db_admin_password}"
  allocated_storage          = "${var.db_storage_allocation}" 
  vpc_security_group_ids     = ["${aws_security_group.rds_mssql_security_group.id}"]
  db_subnet_group_name       = "${aws_db_subnet_group.mssql_subnet_group.id}"
  backup_retention_period    = 3
  storage_encrypted          = false
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.project}-db-final-snapshot"
  tags                       = {
    Name                     = "${var.db_identifiername}"
    Description              = "Created for ${var.project} application "
  }
  
  depends_on                 = [
    aws_db_subnet_group.mssql_subnet_group,
    aws_security_group.rds_mssql_security_group,
    ]

}

# Amazon Redis cache for Inforiver

resource "aws_elasticache_replication_group" "elastic_cache" {
  auto_minor_version_upgrade    = false
  at_rest_encryption_enabled    = false
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  transit_encryption_enabled    = true
  replicas_per_node_group       = 2
  port                          = 6379
  replication_group_id          = "${var.project}-redis-cache"
  description                   = "Redis cache for ${var.project}"
  engine                        = "redis"
  engine_version                = "7.0"
  node_type                     = "${var.cache_instance_class}"  
  subnet_group_name             = "${aws_elasticache_subnet_group.redis_subnet_group.name}"
  security_group_ids            = [aws_security_group.redis_security_group.id]
  auth_token                    = "${var.redis_auth_token}"
  tags                          = {             
    
    Name                        = "${var.project}-ElastiCache-Redis"
  }
  depends_on                    = [
    aws_elasticache_subnet_group.redis_subnet_group,
    aws_security_group.redis_security_group,
    ]
}

#EC-2 Instance to create Database inside the database server

resource "aws_instance" "jump_box" {
  ami                           = data.aws_ami.linux.id
  instance_type                 = "t2.micro"
  availability_zone             = data.aws_availability_zones.available.names[0]
  subnet_id                     = aws_subnet.public.id
  associate_public_ip_address   = true
  key_name                      = aws_key_pair.EKS_workernode_key_pair.key_name
  vpc_security_group_ids        = [
    aws_security_group.alb_securitygroup.id
  ]
 
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
    encrypted = false
  }

  user_data                     = <<-EOF
  #!/bin/bash                 
  sudo curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo
  sudo ACCEPT_EULA=Y yum -y install mssql-tools unixODBC-devel 
  sudo yum check-update
  sudo yum -y update mssql-tools
  echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
  echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
  source ~/.bashrc                     
  sqlcmd -S ${local.db_address} -U ${local.db_username}  -P ${local.db_password} -Q "CREATE DATABASE Turingdb"  

  EOF

  tags = {
    Name = "Jump-box"
  }

  depends_on                    = [
    aws_db_instance.turing_db
    ]
}