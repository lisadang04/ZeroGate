# ------------------------------------------------------
# Load Balancer Security Group (Public)
# ------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "zerogate-alb-sg"
  description = "Allow inbound HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.main.id

  # Allow standard web traffic from anywhere
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow the ALB to send traffic anywhere (needed to reach the containers)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "zerogate-alb-sg"
  }
}

# ------------------------------------------------------
# Gateway Container Security Group (Private)
# ------------------------------------------------------
resource "aws_security_group" "gateway_sg" {
  name        = "zerogate-gateway-sg"
  description = "Allow traffic ONLY from the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # No CIDR block. Reference the ALB's Security Group ID.
  ingress {
    description     = "Traffic routed from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "zerogate-gateway-sg"
  }
}

# ------------------------------------------------------
# Microservice Container Security Group (Private)
# ------------------------------------------------------
resource "aws_security_group" "microservice_sg" {
  name        = "zerogate-microservice-sg"
  description = "Allow traffic ONLY from the Zero-Trust Gateway"
  vpc_id      = aws_vpc.main.id

  # Only accept traffic that has been successfully authenticated by the Gateway.
  ingress {
    description     = "Traffic explicitly from Gateway"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "zerogate-microservice-sg"
  }
}