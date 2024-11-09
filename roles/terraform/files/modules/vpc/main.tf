resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "crypto-lake"
    Environment = "prd"
  }
}

resource "aws_internet_gateway" "igw_vpc" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rota_publica_vpc" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc.id
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "rota_publica_id" {
  value = aws_route_table.rota_publica_vpc.id
}