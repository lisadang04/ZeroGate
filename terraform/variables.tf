variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be provisioned."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The deployment environment name tag."
  default     = "production"
}

variable "project_name" {
  type        = string
  description = "Prefix for naming resources across the infrastructure."
  default     = "zerogate"
}

variable "vpc_cidr" {
  type        = string
  description = "The core CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private subnets."
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}