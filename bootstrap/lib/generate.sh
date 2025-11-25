#!/bin/bash

#######################################
# Automatic File Generation
# Generates Dockerfile, docker-compose.yml, and deploy.sh when missing
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# Dockerfile Generation
#######################################

# Generate Dockerfile for Spring Boot/Java projects
generate_dockerfile_spring_boot() {
    cat <<'EOF'
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy JAR from build stage
# The wildcard *.jar automatically finds your JAR regardless of name
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
}

# Generate Dockerfile for Node.js projects
generate_dockerfile_nodejs() {
    cat <<'EOF'
FROM node:18-alpine AS build
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci

# Copy source
COPY . .

# Build if needed
RUN npm run build || true

# Runtime stage
FROM node:18-alpine
WORKDIR /app

# Copy dependencies and build
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app .

# Expose port
EXPOSE 3000

# Run the application
CMD ["npm", "start"]
EOF
}

# Generate Dockerfile for Python projects
generate_dockerfile_python() {
    cat <<'EOF'
FROM python:3.11-slim AS build
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Runtime stage
FROM python:3.11-slim
WORKDIR /app

# Copy dependencies and app
COPY --from=build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=build /app .

# Expose port
EXPOSE 8000

# Run the application
CMD ["python", "app.py"]
EOF
}

#######################################
# docker-compose.yml Generation
#######################################

# Generate docker-compose.yml for Spring Boot
generate_docker_compose_spring_boot() {
    local port="${1:-8080}"
    cat <<EOF
version: '3.8'

services:
  app:
    build: .
    container_name: \${PROJECT_NAME:-app}
    ports:
      - "${port}:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=\${ENVIRONMENT:-prod}
    env_file:
      - .env
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF
}

# Generate docker-compose.yml for Node.js
generate_docker_compose_nodejs() {
    local port="${1:-3000}"
    cat <<EOF
version: '3.8'

services:
  app:
    build: .
    container_name: \${PROJECT_NAME:-app}
    ports:
      - "${port}:3000"
    environment:
      - NODE_ENV=\${ENVIRONMENT:-production}
    env_file:
      - .env
    restart: unless-stopped
EOF
}

# Generate docker-compose.yml for Python
generate_docker_compose_python() {
    local port="${1:-8000}"
    cat <<EOF
version: '3.8'

services:
  app:
    build: .
    container_name: \${PROJECT_NAME:-app}
    ports:
      - "${port}:8000"
    environment:
      - ENVIRONMENT=\${ENVIRONMENT:-production}
    env_file:
      - .env
    restart: unless-stopped
EOF
}

#######################################
# deploy.sh Generation
#######################################

# Generate deploy.sh script
generate_deploy_script() {
    local port="${1:-8080}"
    cat <<'EOF'
#!/bin/bash

set -e

echo "🚀 Starting deployment..."

# Build and start with Docker Compose
if [ -f "docker-compose.yml" ]; then
    echo "🐳 Building with Docker Compose..."
    docker-compose build
    
    echo "▶️ Starting services..."
    docker-compose up -d
    
    echo "🏥 Waiting for application to start..."
    sleep 20
    
    # Health check
    echo "Checking application health..."
    for i in {1..30}; do
        if curl -s -f http://localhost:PORT/actuator/health > /dev/null 2>&1; then
            echo ""
            echo "✅ Application is healthy!"
            echo ""
            echo "📊 Container Status:"
            docker-compose ps
            echo ""
            echo "📝 View logs: docker-compose logs -f app"
            exit 0
        fi
        echo -n "."
        sleep 2
    done
    
    echo ""
    echo "⚠️ Health check timed out (app may still be starting)"
    echo "📋 Recent logs:"
    docker-compose logs --tail=50 app
    echo ""
    echo "Check logs with: docker-compose logs -f app"
else
    echo "❌ No docker-compose.yml found"
    exit 1
fi
EOF
    # Replace PORT placeholder
    sed "s/PORT/$port/g"
}

#######################################
# Main Generation Logic
#######################################

# Generate all missing files for a project
# Arguments:
#   $1 - Project directory
#   $2 - Project type (spring-boot, nodejs, python)
#   $3 - Port (optional)
generate_missing_files() {
    local project_dir="$1"
    local project_type="$2"
    local port="${3:-8080}"
    
    cd "$project_dir" || return 1
    
    local files_generated=()
    
    # Generate Dockerfile if missing
    if [[ ! -f "Dockerfile" ]]; then
        log_info "No Dockerfile found. Generating one..."
        
        local dockerfile_content=""
        case "$project_type" in
            spring-boot|java)
                dockerfile_content=$(generate_dockerfile_spring_boot)
                ;;
            nodejs)
                dockerfile_content=$(generate_dockerfile_nodejs)
                ;;
            python)
                dockerfile_content=$(generate_dockerfile_python)
                ;;
            *)
                log_warn "Unknown project type: $project_type. Skipping Dockerfile generation."
                ;;
        esac
        
        if [[ -n "$dockerfile_content" ]]; then
            echo ""
            echo "========== Generated Dockerfile =========="
            echo "$dockerfile_content"
            echo "=========================================="
            echo ""
            
            if confirm "Create this Dockerfile?" "y"; then
                echo "$dockerfile_content" > Dockerfile
                log_success "Dockerfile created"
                files_generated+=("Dockerfile")
            else
                log_info "Skipped Dockerfile creation"
            fi
        fi
    fi
    
    # Generate docker-compose.yml if missing
    if [[ ! -f "docker-compose.yml" ]]; then
        log_info "No docker-compose.yml found. Generating one..."
        
        local compose_content=""
        case "$project_type" in
            spring-boot|java)
                compose_content=$(generate_docker_compose_spring_boot "$port")
                ;;
            nodejs)
                compose_content=$(generate_docker_compose_nodejs "$port")
                ;;
            python)
                compose_content=$(generate_docker_compose_python "$port")
                ;;
            *)
                log_warn "Unknown project type: $project_type. Skipping docker-compose.yml generation."
                ;;
        esac
        
        if [[ -n "$compose_content" ]]; then
            echo ""
            echo "========== Generated docker-compose.yml =========="
            echo "$compose_content"
            echo "=================================================="
            echo ""
            
            if confirm "Create this docker-compose.yml?" "y"; then
                echo "$compose_content" > docker-compose.yml
                log_success "docker-compose.yml created"
                files_generated+=("docker-compose.yml")
            else
                log_info "Skipped docker-compose.yml creation"
            fi
        fi
    fi
    
    # Generate deploy.sh if missing
    if [[ ! -f "deploy.sh" ]]; then
        log_info "No deploy.sh found. Generating one..."
        
        local deploy_content
        deploy_content=$(generate_deploy_script "$port")
        
        echo ""
        echo "========== Generated deploy.sh =========="
        echo "$deploy_content"
        echo "=========================================="
        echo ""
        
        if confirm "Create this deploy.sh?" "y"; then
            echo "$deploy_content" > deploy.sh
            chmod +x deploy.sh
            log_success "deploy.sh created"
            files_generated+=("deploy.sh")
        else
            log_info "Skipped deploy.sh creation"
        fi
    fi
    
    if [[ ${#files_generated[@]} -gt 0 ]]; then
        log_success "Generated files: ${files_generated[*]}"
        return 0
    else
        log_info "No files needed to be generated"
        return 0
    fi
}

export -f generate_dockerfile_spring_boot
export -f generate_dockerfile_nodejs
export -f generate_dockerfile_python
export -f generate_docker_compose_spring_boot
export -f generate_docker_compose_nodejs
export -f generate_docker_compose_python
export -f generate_deploy_script
export -f generate_missing_files

log_debug "generate.sh loaded successfully"
