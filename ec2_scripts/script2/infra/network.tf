data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ec2-scheduler-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ec2-scheduler-igw"
  }
}

# prod and dev each get their own subnet so they can eventually get
# different route tables / NACLs without touching the other environment
resource "aws_subnet" "prod" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.prod_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "prod-subnet"
    Environment = "prod"
  }
}

resource "aws_subnet" "dev" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.dev_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "dev-subnet"
    Environment = "dev"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ec2-scheduler-public-rt"
  }
}

resource "aws_route_table_association" "prod" {
  subnet_id      = aws_subnet.prod.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "dev" {
  subnet_id      = aws_subnet.dev.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "instances" {
  name        = "ec2-scheduler-sg"
  description = "Allow SSH inbound, all outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-scheduler-sg"
  }
}
