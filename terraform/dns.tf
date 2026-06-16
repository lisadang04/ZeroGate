# ------------------------------------------------------
# Internal DNS Namespace
# ------------------------------------------------------
resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "internal"
  description = "ZeroGate Internal DNS Namespace"
  vpc         = aws_vpc.main.id
}

# ------------------------------------------------------
# Microservice DNS Record
# ------------------------------------------------------
resource "aws_service_discovery_service" "microservice" {
  name = "microservice"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # Allows ECS to deregister the IP immediately if the container dies
  health_check_custom_config {
    failure_threshold = 1
  }
}