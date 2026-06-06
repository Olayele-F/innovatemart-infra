data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "project-bedrock-vpc"
    Project = "karatu-2025-capstone"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}-igw"
    Project = "karatu-2025-capstone"
  }
}

# ── Public Subnets ─────────────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/project-bedrock-cluster" = "shared"
    Project                                     = "karatu-2025-capstone"
  }
}

# ── Private Subnets ────────────────────────────────────────────────────────────
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "${var.project_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/project-bedrock-cluster" = "shared"
    Project                                     = "karatu-2025-capstone"
  }
}

# ── NAT Gateway ────────────────────────────────────────────────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name    = "${var.project_name}-nat-eip"
    Project = "karatu-2025-capstone"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
  tags = {
    Name    = "${var.project_name}-nat"
    Project = "karatu-2025-capstone"
  }
}

# ── Route Tables ───────────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = "karatu-2025-capstone"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name    = "${var.project_name}-private-rt"
    Project = "karatu-2025-capstone"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── Security Groups ────────────────────────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow DB traffic from EKS nodes only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = "karatu-2025-capstone"
  }
}
