terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Deploying to the N. Virginia region
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "ZeroGate"
      Environment = "Development"
      ManagedBy   = "Terraform"
    }
  }
}