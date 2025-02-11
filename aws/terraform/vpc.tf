# VPC
resource "aws_vpc" "inforiver_vpc" {
  cidr_block              = var.vpc_cidr

  enable_dns_hostnames    = true
  enable_dns_support      = true

  tags = {
    Name                  = "${var.project}-vpc",
    Description           = "Created for the Inforiver Application"
  }
}

# Public Subnet
resource "aws_subnet" "public" {

  vpc_id                  = aws_vpc.inforiver_vpc.id
  cidr_block              = var.publicsb_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name                                           = "${var.project}-public-subnet"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }

  depends_on             = [
    aws_vpc.inforiver_vpc
    ]
  
}

# Public Subnet 2
resource "aws_subnet" "public_1" {

  vpc_id                  = aws_vpc.inforiver_vpc.id
  cidr_block              = var.publicsb1_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name                                           = "${var.project}-public-subnet-2"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }

  depends_on             = [
    aws_vpc.inforiver_vpc
    ]
  
}

# Service Subnet
resource "aws_subnet" "service" {

  vpc_id                  = aws_vpc.inforiver_vpc.id
  cidr_block              = var.servicesb_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = {
    Name                  = "${var.project}-service-subnet"
  }

  depends_on              = [
    aws_vpc.inforiver_vpc
    ]
}

# Service Subnet 2
resource "aws_subnet" "service_1" {

  vpc_id                  = aws_vpc.inforiver_vpc.id
  cidr_block              = var.service1sb_cidr
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = false
  tags = {
    Name                  = "${var.project}-service-subnet-2"
  }

  depends_on              = [
    aws_vpc.inforiver_vpc
    ]
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id                  = aws_vpc.inforiver_vpc.id

  tags = {
    "Name"                = "${var.project}-igw"
  }

  depends_on              = [
    aws_vpc.inforiver_vpc
    ]
}

# NAT Elastic IP
resource "aws_eip" "elastic_ip" {
  vpc                     = true

  tags = {
    Name                  = "${var.project}-ngw-ip"
  }

  depends_on              = [
    aws_vpc.inforiver_vpc
    ]
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id          = aws_eip.elastic_ip.id
  subnet_id              = aws_subnet.public.id

  tags = {
    Name                 = "${var.project}-ngw"
  }

  depends_on             = [
    aws_subnet.public,aws_eip.elastic_ip
    ]
}

# Route Table(s)
# Route the public subnet traffic through the IGW
resource "aws_route_table" "public_rt" {
  vpc_id                = aws_vpc.inforiver_vpc.id

  route {
    cidr_block          = "0.0.0.0/0"
    gateway_id          = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name                = "${var.project}-public-rt"
  }

  depends_on            = [
    aws_internet_gateway.internet_gateway
    ]
}

# Subnet associations
resource "aws_route_table_association" "public_internet_access" {

  subnet_id             = aws_subnet.public.id
  route_table_id        = aws_route_table.public_rt.id

  depends_on            = [
    aws_route_table.public_rt
    ]
}

resource "aws_route_table" "private_rt" {
  vpc_id                = aws_vpc.inforiver_vpc.id

  route {
    cidr_block          = "0.0.0.0/0"
    nat_gateway_id      = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name                = "${var.project}-private-rt"
  }

  depends_on            = [
    aws_nat_gateway.nat_gw
    ]
}

resource "aws_route_table_association" "private_internet_access" {

  subnet_id             = aws_subnet.service.id
  route_table_id        = aws_route_table.private_rt.id

  depends_on            = [
    aws_route_table.private_rt
    ]
}

# Subnet grouping for Database.
resource "aws_db_subnet_group" "mssql_subnet_group" {
  name                  = replace(lower("${var.project}databasesubnetgroup"), "-", "")
  description           = "The RDS-Mssql private subnet group for ${var.project} application ."
  subnet_ids            = [aws_subnet.service.id, aws_subnet.service_1.id]

  depends_on            = [
    aws_subnet.service_1,
    aws_subnet.service
    ]
}

# Subnet grouping for Turing Redis cache.
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name                 = "${var.project}-cache-subnet-group"
  description          = "The private redis cache subnet group for ${var.project} application."
  subnet_ids           = [aws_subnet.service.id, aws_subnet.service_1.id]

  depends_on           = [
    aws_subnet.service_1
    ]
}

# Security group traffic rules
resource "aws_security_group" "alb_securitygroup" {
  name                 = "${var.project}-Alb-security-group"
  description          = "ELB Allowed ports."
  vpc_id               = aws_vpc.inforiver_vpc.id

  ingress {
    from_port          = 80
    to_port            = 80
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
  }
  ingress {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
      from_port        = 2049
      to_port          = 2049
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
    }  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }  
  tags = {
    Name                                           = "${var.project}-Alb-Sg"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }  

  depends_on           = [
    aws_vpc.inforiver_vpc
    ]
}

#Security group to be attached with Turing Database.
resource "aws_security_group" "rds_mssql_security_group" {
  name                = "${var.project}db-sg"
  description         = "Allow all vpc traffic to rds mssql."
  vpc_id              = aws_vpc.inforiver_vpc.id

  ingress {
    from_port         = 1433
    to_port           = 1433
    protocol          = "tcp"
    security_groups   = [aws_security_group.alb_securitygroup.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  } 

  tags = {
    Name              = "${var.project}-Db-Sg"
  } 

  depends_on          = [
    aws_security_group.alb_securitygroup,
    ]
}

#Security group to be attached with Turing Redis cache.
resource "aws_security_group" "redis_security_group" {
  name                = "${var.project}-redis-security-group"
  description         = "Allow all vpc traffic to Redis cache."
  vpc_id              = aws_vpc.inforiver_vpc.id

  ingress {
    from_port         = 6379
    to_port           = 6379
    protocol          = "tcp"
    security_groups   = [aws_security_group.alb_securitygroup.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  } 

  tags = {
    Name              = "${var.project}-Redis-Sg"
  }

  depends_on          = [
    aws_security_group.alb_securitygroup,
    ]
}

#Security group to be attached with EKS Cluster.
resource "aws_security_group" "eks_security_group" {
  name                = "${var.project}-eks-security-group"
  description         = "EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."
  vpc_id              = aws_vpc.inforiver_vpc.id
  tags = {
    Name                                           = "${var.project}-EKS SecurityGroup"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ingress" {
  description                  = "Allow incoming kubelet traffic."
  referenced_security_group_id = aws_security_group.eks_security_group.id
  security_group_id            = aws_security_group.eks_security_group.id
  from_port                    = "-1"
  ip_protocol                  = "-1"
  to_port                      = "-1"

  depends_on          = [
    aws_security_group.eks_security_group,
    ]
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  description                  = "Allow incoming traffic from loadbalancer."
  referenced_security_group_id = aws_security_group.alb_securitygroup.id
  security_group_id            = aws_security_group.eks_security_group.id
  from_port                    = "-1"
  ip_protocol                  = "-1"
  to_port                      = "-1"

  depends_on          = [
    aws_security_group.eks_security_group,
    ]
}

resource "aws_efs_file_system" "inforiver_efs" {
   creation_token = "${var.project}-efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
   tags = {
    Name              = "${var.project}-efs"
  }
 }

resource "aws_efs_mount_target" "inforiver_efs_mount" {
   file_system_id  = aws_efs_file_system.inforiver_efs.id
   subnet_id = aws_subnet.service.id
   security_groups = [aws_security_group.alb_securitygroup.id]
 }



