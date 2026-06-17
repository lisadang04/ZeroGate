# ZeroGate: Cloud-Native Zero-Trust API Gateway

ZeroGate is a high-concurrency, containerized API gateway deployed on AWS Fargate. It secures internal microservices by enforcing strict identity token validation, fixed-window rate limiting, and real-time telemetry streaming before traffic ever reaches the private network layer.

<img width="825" height="681" alt="ZeroGate Diagram" src="https://github.com/user-attachments/assets/15561e27-42c4-40c1-8644-dda07abc527e" />

Made in Excalidraw.

---

## Highlights
* **Zero-Trust Perimeter:** Rejects unauthenticated traffic at the edge, ensuring downstream microservices only process verified requests.
* **Infrastructure as Code (IaC):** 100% of the AWS environment (VPCs, ALBs, ECS clusters) is provisioned dynamically using Terraform.
* **Defense in Depth:** Utilizes cascaded AWS Security Groups to physically isolate backend containers from the internet.
* **Observability First:** Injects structured JSON telemetry logs with sub-millisecond latency tracking into standard output for seamless Datadog/Splunk ingestion.

---

## Overview
As modern distributed systems scale, the traditional "castle-and-moat" security model falls apart. If an attacker breaches the perimeter, they gain lateral access to everything. 

ZeroGate was built to solve this by moving authentication directly to the service edge. Acting as an asynchronous reverse proxy, it intercepts traffic, executes security middleware, and routes validated requests via AWS Cloud Map internal DNS. It demonstrates a complete, production-ready cloud deployment lifecycle from local Docker development to highly available AWS Fargate orchestration.

---

## Engineering Decisions & The "Why"

This architecture required solving several deep systems-engineering challenges to ensure performance, security, and cloud compatibility.

* **Avoiding the `.local` Multicast DNS Trap:** Initially, AWS Application Load Balancer health checks failed due to `504 Gateway Time-out` errors. I diagnosed this as a blocking loop inside the Debian container's `systemd-resolved` daemon, which intercepted `.local` addresses as Multicast DNS queries instead of routing them to the AWS Route 53 Resolver. I engineered a fix by migrating the VPC's private hosted zone to an `.internal` namespace, entirely bypassing the Linux mDNS trap and restoring sub-millisecond dynamic routing.
* **Custom ALB Health Checks:** Standard AWS Load Balancers terminate containers that do not return a `200 OK`. However, a true Zero-Trust gateway *should* return a `401 Unauthorized` to unauthenticated pings. I customized the Terraform Target Group matcher (`matcher = "200,401"`) to explicitly accept `401` responses, harmonizing strict application security with infrastructure lifecycle checks.
* **ARM64 Compute Optimization:** To prevent `exec format errors` caused by deploying Apple Silicon-built Docker images onto default x86_64 nodes, I optimized the Terraform `runtime_platform` to explicitly provision ARM64 Fargate instances. This eliminated emulation overhead during CI/CD builds and reduced cluster compute costs by 20%.
* **Asynchronous Concurrency:** The gateway is built on FastAPI and `httpx` to leverage native asynchronous Python (`async/await`). This prevents blocking threads during network I/O, allowing the gateway to handle high-throughput authentication routing without premature horizontal scaling.

---

## Technologies Used
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi&logoColor=white)
![Pytest](https://img.shields.io/badge/Pytest-0A9EDC?style=for-the-badge&logo=pytest&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/Amazon_AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)

* **Application:** Python 3.12, FastAPI, Uvicorn, Pytest
* **Containerization:** Docker, Multi-Stage Builds, Non-Root Execution
* **Cloud Infrastructure:** AWS (VPC, ALB, ECS Fargate, ECR, Cloud Map, Route Table/NAT Gateway)
* **Provisioning:** Terraform (HCL)

---

## Local Usage

You can spin up the entire isolated microservice environment locally using Docker Compose.

```bash
# Clone the repository
git clone [https://github.com/YourUsername/ZeroGate.git](https://github.com/YourUsername/ZeroGate.git)
cd ZeroGate

# Build and start the local cluster
docker compose up --build

# Test the Zero-Trust rejection (Returns 401)
curl -i [http://127.0.0.1:8000/api/v1/secure-data](http://127.0.0.1:8000/api/v1/secure-data)

# Test successful authentication (Returns 200)
curl -i -H "Authorization: Bearer clear-secure-identity-token-2026" [http://127.0.0.1:8000/api/v1/secure-data](http://127.0.0.1:8000/api/v1/secure-data)
```
---
## Automated Testing

This project utilizes `pytest` alongside `httpx` to validate the asynchronous routing and security middleware. The test suite ensures 100% path coverage for the authentication perimeter.

```bash
cd apps/gateway
pytest test_gateway.py -v
```
---
## Cloud Deployment (Terraform)
The `terraform/` directory contains the complete infrastructure blueprint for deploying this stack to AWS.

```bash
cd terraform

# Initialize the AWS provider
terraform init

# Review the infrastructure execution plan
terraform plan

# Deploy the network, clusters, and load balancers to AWS
terraform apply
```
---
## Author
Designed and engineered by Lisa Dang.

If you are interested in discussing cloud architecture, threat modeling, or backend optimization, feel free to reach out via [LinkedIn](http://linkedin.com/in/lisa-dang04) or check out my other projects.
