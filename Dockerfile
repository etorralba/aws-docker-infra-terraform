# Base Image for building Java and .NET Core applications
FROM ubuntu:20.04 as build-stage

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_APP_DIR="/java-app"
ENV NETCORE_APP_DIR="/net-core-app"

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    gnupg2 \
    lsb-release \
    software-properties-common \
    ca-certificates \
    apt-transport-https \
    openjdk-17-jdk maven\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN \
    # Install Visual Studio Code
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" && \
    apt-get update && apt-get install -y code && \
    # Install .NET Core SDK
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ${JAVA_APP_DIR} ${JAVA_APP_DIR}
RUN cd ${JAVA_APP_DIR} && mvn clean package

COPY ${NETCORE_APP_DIR} ${NETCORE_APP_DIR}
RUN cd ${NETCORE_APP_DIR} && dotnet build

# Final runtime stage
FROM ubuntu:20.04 as runtime-stage

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_APP_DIR="/java-app"
ENV NETCORE_APP_DIR="/net-core-app"
ENV JAVA_APP_JAR="/usr/local/lib/java-app.jar"
ENV DOTNET_APP_DIR="/usr/local/lib/net-core-app"

# Install runtime dependencies (Java JRE, PostgreSQL, Apache)
RUN apt-get update && apt-get install -y \
    apache2 \
    openjdk-17-jdk maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy built Java and .NET Core applications from the build stage
COPY --from=build-stage ${JAVA_APP_DIR}/target/my-java-app-1.0-SNAPSHOT.jar ${JAVA_APP_JAR}

COPY --from=build-stage ${NETCORE_APP_DIR}/bin/Debug/net8.0/* ${DOTNET_APP_DIR}

# Copy the "Hello World" HTML file into the Apache web root
COPY ./index.html /var/www/html/index.html

# Copy the start-services.sh script to the container
COPY ./scripts/start-services.sh /usr/local/bin/start-services.sh

# Make the script executable
RUN chmod +x /usr/local/bin/start-services.sh

# Expose Apache's port 80
EXPOSE 80

# Start Apache server
CMD ["/usr/local/bin/start-services.sh"]