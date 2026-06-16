data "aws_caller_identity" "current" {}

# ------------------------------------------------------
# ECS Cluster
# ------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "zerogate-cluster"
}

# ------------------------------------------------------
# Task Definitions (The Blueprints for the Containers)
# ------------------------------------------------------

# Microservice Task Definition
resource "aws_ecs_task_definition" "microservice" {
  family                   = "zerogate-microservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "microservice"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/zerogate-microservice:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
        }
      ]
    }
  ])
}

# Gateway Task Definition
resource "aws_ecs_task_definition" "gateway" {
  family                   = "zerogate-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "gateway"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/zerogate-gateway:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [
        # Dynamically inject the service endpoint into the container environment variable
        { name = "BACKEND_SERVICE_URL", value = "http://microservice.internal:8001" }
      ]
    }
  ])
}

# ------------------------------------------------------
# ECS Services (To run and maintain the tasks)
# ------------------------------------------------------

# Microservice Service
resource "aws_ecs_service" "microservice" {
  name            = "zerogate-microservice-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Tell ECS to register the dynamic IP with our DNS registry
  service_registries {
    registry_arn = aws_service_discovery_service.microservice.arn
  }

  network_configuration {
    subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.microservice_sg.id]
  }
}

# Gateway Service
resource "aws_ecs_service" "gateway" {
  name            = "zerogate-gateway-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway_tg.arn
    container_name   = "gateway"
    container_port   = 8000
  }

  network_configuration {
    subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.gateway_sg.id]
  }
}