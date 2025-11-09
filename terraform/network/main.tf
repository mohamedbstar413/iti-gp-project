provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "iti_vpc" {
  cidr_block =              var.cidr_block
  enable_dns_hostnames =    true
  enable_dns_support =      true
  tags = {
    Name =                  "iti-vpc"
  }
}

resource "aws_internet_gateway" "iti_igw" {
  vpc_id =                  aws_vpc.iti_vpc.id
  tags = {
    Name =                  "iti-igw"
  }
}

resource "aws_eip" "iti_nat_eip" {
  domain =                  "vpc"
  tags = {
    Name =                  "iti-nat-eip"
  }
}

resource "aws_nat_gateway" "iti_ngw" {
  allocation_id =           aws_eip.iti_nat_eip.id
  subnet_id =               aws_subnet.public_subnets[0].id
}

resource "aws_route_table" "iti_public_route_table" {
  vpc_id =                  aws_vpc.iti_vpc.id

  route {
    cidr_block =            var.cidr_block
    gateway_id =            "local"
  }
  route {
    cidr_block =            "0.0.0.0/0"
    gateway_id =            aws_internet_gateway.iti_igw.id
  }
  tags = {
    Name =                  "iti-public-route-table"
  }
}

resource "aws_route_table" "iti_private_route_table" {
  vpc_id =                  aws_vpc.iti_vpc.id
  route {
    cidr_block =            var.cidr_block
    gateway_id =            "local"
  }
  route {
    cidr_block =            "0.0.0.0/0"
    gateway_id =            aws_nat_gateway.iti_ngw.id
  }
  tags = {
    Name =                  "iti-private-route-table"
  }
}

resource "aws_subnet" "private_subnets" {
  count =                   var.num_private_subnets
  vpc_id =                  aws_vpc.iti_vpc.id
  cidr_block =              cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone =       element(["us-east-1a","us-east-1b", "us-east-1c"], count.index)
  map_public_ip_on_launch = false

  tags = {
    Name =                  "private-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "public_subnets" {
  count =                   var.num_public_subnets
  vpc_id =                  aws_vpc.iti_vpc.id
  cidr_block =              cidrsubnet(var.cidr_block, 8, count.index+3)
  availability_zone =       element(["us-east-1a","us-east-1b", "us-east-1c"], count.index+3)
  map_public_ip_on_launch = true

  tags = {
    Name =                  "private-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "iti_public_rt_assoc" {
  count =                   var.num_public_subnets
  subnet_id =               aws_subnet.public_subnets[count.index].id
  route_table_id =          aws_route_table.iti_public_route_table.id
}

resource "aws_route_table_association" "iti_private_rt_assoc" {
  count =                   var.num_private_subnets
  subnet_id =               aws_subnet.private_subnets[count.index].id
  route_table_id =          aws_route_table.iti_private_route_table.id
}
