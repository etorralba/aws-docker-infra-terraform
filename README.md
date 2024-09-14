# aws-docker-infra-terraform
AWS infrastructure project using Terraform and Docker. Includes a Linux-based compute service (EC2/ECS), RDS PostgreSQL database, SSH security policies, and a Docker image with Git, VS Code, Maven, PostgreSQL, Java JRE, .NET Core SDK, and Apache. 

## Pre-requisites
- Java JDK 17
- Maven 3.9.9
- Dotnet Core SDK 8.0.401
- Docker

## Setup
1. Clone the repository

2. Create a `.env` file in the root directory with the following environment variables:
```
IMAGE_VERSION=latest
```