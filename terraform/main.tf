terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket = "project-bedrock-tfstate-alt-soe-025-4637"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
    # S3 versioning handles state locking (DynamoDB not required per brief)
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "karatu-2025-capstone"
    }
  }
}

# Kubernetes + Helm providers use EKS cluster credentials
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}

# ── Modules ────────────────────────────────────────────────────────────────────

module "networking" {
  source             = "./modules/networking"
  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

module "eks" {
  source              = "./modules/eks"
  project_name        = var.project_name
  aws_region          = var.aws_region
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  node_instance_type  = var.node_instance_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  account_id          = data.aws_caller_identity.current.account_id
}

module "data" {
  source              = "./modules/data"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  eks_node_sg_id      = module.eks.node_security_group_id
  db_password_mysql   = var.db_password_mysql
  db_password_postgres = var.db_password_postgres
}

module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  student_id   = var.student_id
  account_id   = data.aws_caller_identity.current.account_id
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  account_id   = data.aws_caller_identity.current.account_id
  student_id   = var.student_id
  assets_bucket_arn = module.storage.assets_bucket_arn
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
}

module "observability" {
  source       = "./modules/observability"
  project_name = var.project_name
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  node_group_arn    = module.eks.node_group_arn
}
