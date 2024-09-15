data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name         = "${var.main_organization}-vpc"
    Organization = var.main_organization
  }
}

# Create 3 Public Subnets, one in each of the first 3 AZs
resource "aws_subnet" "public_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name         = "${var.main_organization}-public-subnet-${count.index}"
    Organization = var.main_organization
  }
}

# Create 3 Private Subnets, one in each of the first 3 AZs
resource "aws_subnet" "private_subnet" {
  count             = 3
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name         = "${var.main_organization}-private-subnet-${count.index}"
    Organization = var.main_organization
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name         = "${var.main_organization}-igw"
    Organization = var.main_organization
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name         = "${var.main_organization}-public-rt"
    Organization = var.main_organization
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public_association" {
  count          = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create NAT Gateway
resource "aws_eip" "nat_eip" {
  count = 3
  tags = {
    Name         = "${var.main_organization}-nat-eip-${count.index}"
    Organization = var.main_organization
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = 3
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags = {
    Name         = "${var.main_organization}-nat-gateway-${count.index}"
    Organization = var.main_organization
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  count  = 3
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name         = "${var.main_organization}-private-rt-${count.index}"
    Organization = var.main_organization
  }
}

# Associate Private Subnets with Route Table
resource "aws_route_table_association" "private_association" {
  count          = 3
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}
