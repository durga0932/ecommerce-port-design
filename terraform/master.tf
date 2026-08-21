terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ============================================================
# VARIABLES
# ============================================================

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "ecommerce-eks"
}

variable "key_name" {
  type = string
}

variable "admin_cidr" {
  type = string
}

# ============================================================
# AWS PROVIDER
# ============================================================

provider "aws" {
  region = var.aws_region
}

# ============================================================
# AVAILABILITY ZONES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# UBUNTU AMI
# Used only for Ansible EC2
# ============================================================

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# ============================================================
# VPC
# ============================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "ecommerce-devops-vpc"
  cidr = "10.0.0.0/16"

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  # NAT Gateway for private EKS nodes
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Project     = "ecommerce-port-design"
    Environment = "dev"
  }
}

# ============================================================
# EC2 SECURITY GROUP
# ============================================================

resource "aws_security_group" "ansible_ec2" {
  name        = "ecommerce-ansible-ec2-sg"
  description = "Security group for Ansible managed EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = [
      var.admin_cidr
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

# ============================================================
# EC2 - ANSIBLE SERVER
# ============================================================

resource "aws_instance" "ansible_server" {
  ami           = data.aws_ssm_parameter.ubuntu.value
  instance_type = "t3.micro"

  subnet_id = module.vpc.public_subnets[0]

  vpc_security_group_ids = [
    aws_security_group.ansible_ec2.id
  ]

  key_name = var.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "ecommerce-ansible-server"
    Role    = "ansible-managed"
    Project = "ecommerce-port-design"
  }
}

# ============================================================
# EKS CLUSTER
# ============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id

  # EKS nodes will run inside private subnets
  subnet_ids = module.vpc.private_subnets

  # ==========================================================
  # EKS MANAGED NODE GROUP
  # ==========================================================

  eks_managed_node_groups = {
    main = {
      name = "ecommerce-node-group"

      # EKS worker node
      # Changed from t3.micro to t3.small
      instance_types = [
        "t3.small"
      ]

      # Low-cost testing configuration
      min_size     = 1
      desired_size = 1
      max_size     = 2

      disk_size = 20

      capacity_type = "ON_DEMAND"
    }
  }

  # ==========================================================
  # EKS TAGS
  # ==========================================================

  tags = {
    Project     = "ecommerce-port-design"
    Environment = "dev"
  }
}

# ============================================================
# OUTPUTS
# ============================================================

output "ec2_public_ip" {
  value = aws_instance.ansible_server.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.ansible_server.private_ip
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}