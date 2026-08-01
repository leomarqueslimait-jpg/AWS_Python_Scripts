variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the demo instances"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "prod_subnet_cidr" {
  description = "CIDR block for the prod subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "dev_subnet_cidr" {
  description = "CIDR block for the dev subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH into instances. Restrict this to your own IP before applying."
  type        = string
  default     = "0.0.0.0/0"
}
