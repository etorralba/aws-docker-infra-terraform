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
	docker run -d -p 8080:80 java-dotnet-apache:${IMAGE_VERSION}

# Stop Docker container
docker-stop:
	docker stop $(shell docker ps -q --filter ancestor=java-dotnet-apache:${IMAGE_VERSION})

docker-clean:
	-docker rm -f $$(docker ps -a -q --filter "ancestor=java-dotnet-apache")
	-docker rmi -f java-dotnet-apache
	-docker volume prune --force

docker-prune:
	docker system prune --all --volumes --force

build-java-netcore:
	docker-compose up build-java-netcore

run-server:
	docker-compose up run-server