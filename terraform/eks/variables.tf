variable "cluster_name" {
  type = string
}

variable "pri_subnet_1_id" {
  type = string
}

variable "pri_subnet_2_id" {
  type = string
}

variable "pri_subnet_3_id" {
  type = string
}

variable "db_password" {
  type = string
  default = "admin123"
}
variable "git_token" {
  type = string
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}