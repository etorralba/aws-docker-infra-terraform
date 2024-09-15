include .env

JAVA_DIR = java-app
NET_DIR = net-core-app

# Build and package the Java application using Maven
all-java: build-java run-java

all-dot: build-dot run-dot

# Clean the target directory and recompile the project
build-java:
	cd ${JAVA_DIR} && mvn clean install

# Run the Java application
run-java:
	cd ${JAVA_DIR} && mvn exec:java -Dexec.mainClass="com.example.App"

# Clean the project, removing compiled classes and build artifacts
clean-java:
	cd ${JAVA_DIR} && mvn clean

# Build the .NET application
build-dot:
	dotnet build ${NET_DIR}

# Run the .NET application
run-dot:
	dotnet run --project ${NET_DIR}

# Clean the .NET project
clean-dot:
	dotnet clean ${NET_DIR}

# Build Docker image
docker-build:
	docker build . -t java-dotnet-apache:${IMAGE_VERSION}

# Run Docker container
docker-run:
	docker run -d -p 80:80 java-dotnet-apache:${IMAGE_VERSION}

# Stop Docker container
docker-stop:
	docker stop $(shell docker ps -q --filter ancestor=java-dotnet-apache:${IMAGE_VERSION})

docker-clean:
	-docker rm -f $$(docker ps -a -q --filter "ancestor=java-dotnet-apache")
	-docker rmi -f java-dotnet-apache
	-docker volume prune --force

docker-prune:
	docker system prune --all --volumes --force

docker-login:
	aws ecr get-login-password -profile ${AWS_PROFILE} --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker-push:
	docker tag java-dotnet-apache:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ORGANIZATION}-repo:${IMAGE_VERSION}
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ORGANIZATION}-repo:latest

build-java-netcore:
	docker-compose up build-java-netcore

run-server:
	docker-compose up run-server

run:
	AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
	AWS_REGION=${AWS_REGION} \
	AWS_PROFILE=${AWS_PROFILE} \
	./scripts/$(script)

terraform-init:
	@make run script="init.sh ${LAYER} ${ORGANIZATION}"

terraform-plan:
	@make run script="plan.sh ${LAYER} ${ORGANIZATION}"

terraform-apply:
	@make run script="apply.sh ${LAYER} ${ORGANIZATION}"

terraform-output:
	@make run script="output.sh ${LAYER} ${ORGANIZATION}"

terraform-destroy:
	@make run script="destroy.sh ${LAYER} ${ORGANIZATION}"

terraform-fmt:
	@make run script="format.sh"

