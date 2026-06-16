# ------------------------------------------------------
# NAT Gateway Configuration (For outbound internet access)
# ------------------------------------------------------

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "zerogate-nat-eip"
  }
}

# Create the NAT Gateway in the first public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "zerogate-nat-gw"
  }

  # Ensure the Internet Gateway exists before creating the NAT Gateway
  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------------------------------
# Public Routing (Internet Gateway Access)
# ------------------------------------------------------

# Create the Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # Send all outbound traffic (0.0.0.0/0) to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "zerogate-public-rt"
  }
}

# Associate Public Subnet 1 with Public Route Table
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Public Subnet 2 with Public Route Table
resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------------------------------
# Private Routing (NAT Gateway Access)
# ------------------------------------------------------

# Create the Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  # Send all outbound traffic (0.0.0.0/0) to the NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "zerogate-private-rt"
  }
}

# Associate Private Subnet 1 with Private Route Table
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Private Subnet 2 with Private Route Table
resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}