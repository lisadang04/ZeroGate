output "alb_dns_name" {
  description = "The public-facing DNS name of the ZeroGate Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "gateway_repo_url" {
  description = "The ECR Registry URL for the Zero-Trust Gateway image."
  value       = aws_ecr_repository.gateway.repository_url
}

output "microservice_repo_url" {
  description = "The ECR Registry URL for the backend microservice image."
  value       = aws_ecr_repository.microservice.repository_url
}