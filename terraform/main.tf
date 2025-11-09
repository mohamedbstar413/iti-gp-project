provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./network"
  cidr_block = "10.0.0.0/16"
  cluster_name = "iti-gp-cluster"
  num_private_subnets = 3
  num_public_subnets = 3
}