provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "ecs-vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Name = var.app_name
    Env  = var.env
  }
}

resource "aws_internet_gateway" "ecs-igw" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags   = {
    Name = var.app_name
    Env  = var.env
  }
}

resource "aws_subnet" "ecs-private-subnet" {
  vpc_id            = aws_vpc.ecs-vpc.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index )
  availability_zone = element(var.availability_zones, count.index )

  tags   = {
    Name = "${lower(var.app_name)}-private-subnet-${count.index}"
    Env  = var.env
  }
}

resource "aws_subnet" "ecs-public-subnet" {
  vpc_id            = aws_vpc.ecs-vpc.id
  count             = length(var.public_subnets)
  cidr_block        = element(var.public_subnets, count.index )
  availability_zone = element(var.availability_zones, count.index )
  map_public_ip_on_launch = true

  tags   = {
    Name = "${lower(var.app_name)}-public-subnet-${count.index}"
    Env  = var.env
  }
}

resource "aws_route_table" "ecs-public-route-table" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags   = {
    Name = "${lower(var.app_name)}public-route-table"
    Env  = var.env
  }
}

resource "aws_route" "ecs-public-route" {
  route_table_id = aws_route_table.ecs-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ecs-igw.id
}

resource "aws_route_table_association" "ecs-public-route-association" {
  count = length(var.public_subnets)
  subnet_id = element(aws_subnet.ecs-public-subnet.*.id,count.index )
  route_table_id = aws_route_table.ecs-public-route-table.id
}