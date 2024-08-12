#####################################################
#    DATA SOURCE                                    #
#####################################################
data "aws_availability_zones" "available" {}

#####################################################
#    LOCALS                                         #
#####################################################
locals {
  azs = data.aws_availability_zones.available.names
}

#####################################################
#    NETWORK                                        #
#####################################################
# VPC
resource "aws_vpc" "galaxy_demo_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "galaxy_demo_vpc-${random_id.random.dec}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

# IGW
resource "aws_internet_gateway" "galaxy_demo_internet_gateway" {
  depends_on = [aws_vpc.galaxy_demo_vpc]
  vpc_id     = aws_vpc.galaxy_demo_vpc.id

  tags = {
    Name = "galaxy-demo-igw-${random_id.random.dec}"
  }
}

# Route table: galaxy_demo_public_rt
resource "aws_route_table" "galaxy_demo_public_rt" {
  depends_on = [aws_vpc.galaxy_demo_vpc]
  vpc_id     = aws_vpc.galaxy_demo_vpc.id

  tags = {
    "Name" = "galaxy-demo-public-${random_id.random.dec}"
  }
}

# Add route entry
resource "aws_route" "default_route" {
  depends_on             = [aws_route_table.galaxy_demo_public_rt]
  route_table_id         = aws_route_table.galaxy_demo_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.galaxy_demo_internet_gateway.id
}

# Association
resource "aws_route_table_association" "galaxy_demo_public_assoc" {
  depends_on     = [aws_subnet.galaxy_demo_public_subnet, aws_route_table.galaxy_demo_public_rt]
  count          = length(local.azs)
  subnet_id      = aws_subnet.galaxy_demo_public_subnet[count.index].id
  route_table_id = aws_route_table.galaxy_demo_public_rt.id
}

# default route table
resource "aws_default_route_table" "galaxy_demo_private_rt" {
  depends_on             = [aws_vpc.galaxy_demo_vpc]
  default_route_table_id = aws_vpc.galaxy_demo_vpc.default_route_table_id

  tags = {
    "Name" = "galaxy-demo-private-${random_id.random.dec}"
  }
}

# subnet: public
resource "aws_subnet" "galaxy_demo_public_subnet" {
  depends_on              = [aws_vpc.galaxy_demo_vpc]
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.galaxy_demo_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.cidr_extension_number, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    "Name" = "galaxy-demo-public-${count.index + 1}"
  }
}

# subnet: private
resource "aws_subnet" "galaxy_demo_private_subnet" {
  depends_on              = [aws_vpc.galaxy_demo_vpc]
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.galaxy_demo_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.cidr_extension_number, count.index + length(local.azs))
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    "Name" = "galaxy-demo-private-${count.index + 1}"
  }
}

#####################################################
#    MISC                                           #
#####################################################
# random
resource "random_id" "random" {
  byte_length = 2
}