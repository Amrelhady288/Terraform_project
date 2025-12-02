terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# --------------------------
# VPC + Subnets
# --------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "main-vpc" }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"
  tags = { Name = "subnet-1" }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1b"
  tags = { Name = "subnet-2" }
}

# Internet Gateway + Route Table
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------------
# Security Group
# --------------------------
resource "aws_security_group" "main_sg" {
  name   = "main-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "main-sg" }
}

# --------------------------
# Latest Ubuntu AMI
# --------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --------------------------
# EC2 Instance
# --------------------------
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  tags = { Name = "app-server" }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              EOF
}

# --------------------------
# RDS MariaDB
# --------------------------
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_db_instance" "mariadb" {
  identifier             = "app-mariadb"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "Admin123456AB"
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}

# --------------------------
# Amazon MQ (RabbitMQ)
# --------------------------
resource "aws_mq_broker" "rabbitmq" {
  broker_name         = "app-mq"
  engine_type         = "RabbitMQ"
  engine_version      = "3.13"
  host_instance_type  = "mq.t3.micro"
  publicly_accessible = true
  subnet_ids           = [aws_subnet.subnet1.id]

  user {
    username = "admin"
    password = "Admin123456789"
  }

  logs {
    general = true
  }

  auto_minor_version_upgrade = true
}

# --------------------------
# ElastiCache Redis
# --------------------------
resource "aws_elasticache_subnet_group" "redis_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id        = "app-redis"
  engine            = "redis"
  node_type         = "cache.t3.micro"
  num_cache_nodes   = 1
  subnet_group_name = aws_elasticache_subnet_group.redis_group.name
  security_group_ids = [aws_security_group.main_sg.id]
}

# --------------------------
# Outputs
# --------------------------
output "app_server_ip" {
  value = aws_instance.app_server.public_ip
}

output "mariadb_endpoint" {
  value = aws_db_instance.mariadb.address
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
