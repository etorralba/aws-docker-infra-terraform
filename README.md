# aws-docker-infra-terraform
AWS infrastructure project using Terraform and Docker. Includes a Linux-based compute service (EC2/ECS), RDS PostgreSQL database, SSH security policies, and a Docker image with Git, VS Code, Maven, PostgreSQL, Java JRE, .NET Core SDK, and Apache. 

## Pre-requisites
- Java JDK 17
- Maven 3.9.9
- Dotnet Core SDK 8.0.401
- Docker
- Docker Compose
- Terraform
- (Act)[https://github.com/nektos/act]

## Setup and Manual Deployment
1. Clone the repository

2. Create a `.env` file in the root directory with the following environment variables:
    ```
    # Docker image
    IMAGE_VERSION=latest

    # AWS
    AWS_ACCOUNT_ID=1234567890
    AWS_REGION=us-east-1
    AWS_PROFILE=default

    # Terraform
    LAYER=network # network, compute
    ORGANIZATION=default

    ```

3. Build the Docker image
- Run `make docker-build` to build the Docker image - It will create a docker image with the following name: `java-dotnet-apache:${IMAGE_VERSION}`

4. Bootstrap the Terraform 
- Navigate to the `terraform/bootstrap` directory
- Create a `terraform.tfvars` file with the following variables:
    ```
    aws_profile       = "default"
    region            = "us-east-1"
    main_organization = "arroyo"
    account_id        = "1234567890"
    ```
- Run the following commands:
    ```
    terraform init
    terraform plan
    terraform apply
    ```
_Note: The bootstrap Terraform script will create the S3 bucket and DynamoDB table for the Terraform state. The state of this layer will be managed locally._

5. Deploy the infrastructure
- change the `LAYER` variable in the `.env` file to `network`, `compute` or `database`
- Run make terraform-plan - It will create a plan for the selected layer
- Run make terraform-apply - It will apply the plan for the selected layer

_Note: The `network` layer will create the VPC, subnets, route tables, internet gateway, and security groups. The `compute` layer will create the EC2 AutoScaling Group and ECS cluster. The `database` layer will create the RDS PostgreSQL database._

> __The order of deployment is important. The `network` layer must be deployed first, followed by the `database` layer, and finally the `compute` layer.__

6. Push the Docker image to ECR
- Run `aws ecr get-login-password -profile ${AWS_PROFILE} --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com` to authenticate the Docker client to your ECR registry

- Run `make docker-push` to push the Docker image to the ECR registry - It assumes the ECR repository is named `${ORGANIZATION}-repo`

7. Destroy the infrastructure
- Run `make terraform-destroy` to destroy the infrastructure, remember to destroy the layers in the reverse order of deployment (compute, database, network)

## Run with pipeline
1. Ensure Act is installed
2. Create the `.secrets` file with the necessary environment variables
    ```
    AWS_ACCOUNT_ID=1234567890
    AWS_REGION=us-east-1
    AWS_SECRET_ACCESS_KEY=**********************************
    AWS_ACCESS_KEY_ID=**************
    DB_PASSWORD=password
    DB_USERNAME=useradmin
    ORGANIZATION=arroyo
    ```
__Also create these secrets in the GitHub repository settings: `AWS_ACCOUNT_ID`, `AWS_REGION`, `AWS_SECRET_ACCESS_KEY`, `AWS_ACCESS_KEY_ID`, `DB_PASSWORD`, `DB_USERNAME`, `ORGANIZATION`__

3. Run `make act-infra` to run the pipeline

4. Run `make act-destroy-infra` to destroy the infrastructure

_Note: The pipeline can be triggered manually on GitHub_

5. You can manually run the ci pipeline by running `make act-ci`, this will build and push the Docker image to ECR. 
_You could also trigger the pipeline manually on GitHub or by pushing a commit to the repository_

## Docker Image

The Docker image is based on the `ubuntu:20.04` image and is built with 2 stages: `build-stage` and `runtime-stage`. The `build-stage` installs the necessary tools and dependencies to build the Java and .NET Core applications, while the `runtime-stage` copies the built applications and sets up the Apache server to serve the static content.

Using the `docker-compose.yml` file, we can target the `build-stage` to build the Java and .NET Core applications, and the `runtime-stage` to run the Apache server with the built applications.

## Explanation on the Infrastructure
### State Management
It has been created a separate Terraform layer for the bootstrap configuration to manage the state of the infrastructure. The state of the bootstrap layer is managed locally, while the state of the network, compute, and database layers is stored in an S3 bucket and locked with a DynamoDB table.

State locking prevents concurrent modifications to the state, ensuring that only one user or automation process can modify the state at a time.

### RDS and ECS
ECS has been selected as the compute service due to its ability to run containerized applications at scale, manage container lifecycle.

RDS PostgreSQL has been selected as the database service due to the ease of setup, management, and scalability. Being an open-source relational database, PostgreSQL is widely used and supported by the community, hence the compatibility with various tools and frameworks. Additionally is cost-effective for small to medium-sized applications.


## Architecture
### Network
- VPC: A Virtual Private Cloud (VPC) is a logically isolated section of the AWS cloud where you can launch AWS resources in a virtual network that you define. The VPC includes:
    - __Subnets__: 3 public and 3 private subnets to distribute resources across multiple availability zones.
    - __Internet gateway__: Allows communication between instances in your VPC and the internet.
    - __Route tables__: Public and private route tables to manage traffic routing within the VPC.
    - __Security groups__: Act as virtual firewalls to control inbound and outbound traffic for your instances.
        - _ALB security group_: Allows inbound traffic on port 80 and 443 from the internet. Allows all io traffic.
    - __NAT gateway__: Enables instances in a private subnet to connect to the internet or other AWS services, but prevents the internet from initiating a connection with those instances.
    - __ALB__: Application Load Balancer to distribute incoming application traffic across multiple targets, such as EC2 instances, in multiple availability zones.


### Database
- __RDS PostgreSQL__: A managed relational database service that provides PostgreSQL databases.
- __Security group__: Acts as a virtual firewall to control inbound and outbound traffic for the RDS instance. Allows inbound traffic on the PostgreSQL port (default 5432) from the compute layer.
    - _RDS security group_: Allows inbound traffic on port 5432 EC2 instances in the AutoScaling Group and ECS tasks (set in the compute layer). Allows all outbound traffic.
- __Secret__: Stores sensitive information such as database credentials securely in AWS Secrets Manager.
    ```
    {
        "username": "******",
        "password": "******"
        "port": "5432",
        "host": "database-1.cjvzvzvzvzvz.us-east-1.rds.amazonaws.com",
        "dbname": "******"
    }
    ```

### Compute
- __ECS Cluster__: A group of EC2 instances managed as a cluster for running containerized applications.
- __ECS Task Definition__: Defines the containerized application running in the ECS cluster.
- __ECS Service__: Manages the deployment of the ECS tasks within the ECS cluster, ensuring the correct number of tasks are running, performing rolling updates, and connecting tasks to the Application Load Balancer (ALB).
- __Auto Scaling Group (ASG)__: Automatically adjusts the number of EC2 instances running in the ECS cluster to meet application demand.
- __CloudWatch Logs Group__: Stores logs from the ECS tasks and EC2 instances for monitoring and troubleshooting.
- __ECR Repository__: A private Docker container registry to store and manage Docker images for the ECS tasks.
- __ECS Launch Template__: A configuration template for launching EC2 instances in the ECS cluster, defining instance type, security groups, and other settings.
- __Security group__: Controls inbound and outbound traffic for the EC2 instances and ECS tasks within the ECS cluster.
    - _ECS security group_: Allows outbound traffic to the RDS security group on port 5432 and all inbound traffic from the ALB security group. Allows all outbound traffic.
- __IAM Roles__: Provides granular permissions for ECS tasks and EC2 instances, including access to RDS, Secrets Manager, and other AWS services.
    - _EC2 Instance Role_: Allows EC2 instances to interact with AWS services for ECS tasks
    - _ECS Service Role_: Allows ECS service to interact with load balancers.
    - _ECS Task Role_:  Allows specific permissions for ECS tasks itself.
    - _ECS Task Execution Role_: grants the task the necessary permissions to interact with AWS services such as pulling container images, fetching secrets, etc.

## Makefile commands
### Build Commands
- `build-java`: Build the Java application with Maven
- `build-dot`: Build the .NET Core application
- `build-java-netcore`: Build the Java and .NET Core applications using docker-compose

### Run Commands
- `all-java`: Build the Java application with Maven and run the JAR file
- `all-dotnet`: Build the .NET Core application and run the executable
- `run-java`: Run the Java application
- `run-dot`: Run the .NET Core application
- `run-server`: Run the Apache server using docker-compose

### Clean Commands
- `clean-java`: Clean the Java application
- `clean-dotnet`: Clean the .NET Core application

### Docker Commands
- `docker-build`: Build the Docker image
- `docker-push`: Push the Docker image to the ECR repository
- `docker-run`: Run the Docker container with the built image
- `docker clean`: Remove the Docker image, container, and volume related to the application
- `docker-prune`: Remove all unused Docker images, containers, networks, and volumes

### Terraform Commands
- `terraform-init`: Initialize the Terraform workspace
- `terraform-plan`: Create an execution plan for the selected layer
- `terraform-apply`: Apply the selected layer
- `terraform-destroy`: Destroy the selected layer
- `terraform-output`: Display the output values of the selected layer
- `terraform-fmt`: Format the Terraform configuration files

## Folder Structure
```
.
├── Dockerfile
├── Makefile
├── README.md
├── docker-compose.yml
├── index.html
├── java-app
│   ├── pom.xml
│   └──  src
│       ├── main
│       └── test
├── net-core-app
│   ├── Program.cs
│   └── net-core-app.csproj
├── scripts
│   ├── apply.sh
│   ├── destroy.sh
│   ├── format.sh
│   ├── init.sh
│   ├── output.sh
│   ├── plan.sh
│   └── start-services.sh
└── terraform
    ├── bootstrap
    │   ├── main.tf
    │   ├── output.tf
    │   ├── provider.tf
    │   └── variables.tf
    ├── compute
    │   ├── data.tf
    │   ├── ecr.tf
    │   ├── ecs.tf
    │   ├── main.tf
    │   ├── output.tf
    │   ├── provider.tf
    │   └── variables.tf
    ├── database
    │   ├── data.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── provider.tf
    │   └── variables.tf
    └── network
        ├── alb.tf
        ├── main.tf
        ├── outputs.tf
        ├── provider.tf
        └── variables.tf
```