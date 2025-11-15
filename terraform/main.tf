provider "aws" {
  region = "us-east-1"
}
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}


module "network" {
  source = "./network"
  cidr_block = "10.0.0.0/16"
  cluster_name = "iti-gp-cluster"
  num_private_subnets = 3
  num_public_subnets = 3
}

module "eks" {
  source = "./eks"
  cluster_name = "iti-gp-cluster"
  pri_subnet_1_id = module.network.pri_subnet_1_id
  pri_subnet_2_id = module.network.pri_subnet_2_id
  pri_subnet_3_id = module.network.pri_subnet_3_id
  git_token = var.git_token
}