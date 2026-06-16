# ------------------------------------------------------
# Gateway Container Registry
# ------------------------------------------------------
resource "aws_ecr_repository" "gateway" {
  name                 = "zerogate-gateway"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allows Terraform to delete the repo even if it contains images (Good for dev/portfolio environments)

  # Scan every image for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "zerogate-gateway-repo"
  }
}

# ------------------------------------------------------
# Microservice Container Registry
# ------------------------------------------------------
resource "aws_ecr_repository" "microservice" {
  name                 = "zerogate-microservice"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "zerogate-microservice-repo"
  }
}

# Output the repository URLs to the terminal after creation so we can use them!
output "gateway_repo_url" {
  value = aws_ecr_repository.gateway.repository_url
}

output "microservice_repo_url" {
  value = aws_ecr_repository.microservice.repository_url
}