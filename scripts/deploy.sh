#!/bin/bash

# AI API Starter Kit - Production Deployment Script
# Deploy to various cloud providers and environments
# Follows Treblle's 7 key lessons with production-ready configurations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION=$(date +%Y%m%d_%H%M%S)
DEPLOYMENT_LOG="deployment_${VERSION}.log"

# Default values
ENVIRONMENT="production"
DEPLOY_TARGET="docker"
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_DELAY=10

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🚀 AI API Starter Kit Deployment               ║"
    echo "║                  Production Deployment                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy AI API Starter Kit to production environment

OPTIONS:
    -e, --environment   Environment (production|staging|development) [default: production]
    -t, --target        Deployment target (docker|aws|gcp|azure|digitalocean|railway) [default: docker]
    -r, --region        Cloud region (for cloud deployments)
    -d, --domain        Custom domain name
    -s, --ssl           Enable SSL/HTTPS [default: true]
    -m, --monitoring    Enable monitoring stack [default: true]
    -b, --backup        Enable automated backups [default: true]
    -c, --config        Custom config file path
    -h, --help          Show this help message

EXAMPLES:
    # Deploy with Docker Compose
    $0 --target docker --environment production

    # Deploy to AWS with custom domain
    $0 --target aws --environment production --domain api.mycompany.com --region us-east-1

    # Deploy to staging environment
    $0 --target docker --environment staging

    # Deploy with custom configuration
    $0 --target docker --config ./custom-deploy.conf

REQUIREMENTS:
    - Docker and Docker Compose installed
    - Environment variables configured
    - Cloud CLI tools (for cloud deployments)
    - Valid SSL certificates (for HTTPS)

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -t|--target)
                DEPLOY_TARGET="$2"
                shift 2
                ;;
            -r|--region)
                CLOUD_REGION="$2"
                shift 2
                ;;
            -d|--domain)
                CUSTOM_DOMAIN="$2"
                shift 2
                ;;
            -s|--ssl)
                ENABLE_SSL="$2"
                shift 2
                ;;
            -m|--monitoring)
                ENABLE_MONITORING="$2"
                shift 2
                ;;
            -b|--backup)
                ENABLE_BACKUP="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

# Load configuration
load_config() {
    log_step "Loading Configuration"
    
    # Load custom config if provided
    if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
        log_info "Loading custom config from: $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
    
    # Set defaults
    ENABLE_SSL=${ENABLE_SSL:-true}
    ENABLE_MONITORING=${ENABLE_MONITORING:-true}
    ENABLE_BACKUP=${ENABLE_BACKUP:-true}
    CLOUD_REGION=${CLOUD_REGION:-us-east-1}
    
    # Validate required environment variables
    local required_vars=(
        "TREBLLE_API_KEY"
        "TREBLLE_PROJECT_ID"
    )
    
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_info "Please set these variables in your .env file or environment"
        exit 1
    fi
    
    log_success "Configuration loaded successfully"
}

# Pre-deployment checks
pre_deployment_checks() {
    log_step "Running Pre-deployment Checks"
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/strapi-backend/package.json" ]]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check Docker availability for Docker deployments
    if [[ "$DEPLOY_TARGET" == "docker" ]]; then
        if ! command -v docker >/dev/null 2>&1; then
            log_error "Docker is not installed or not in PATH"
            exit 1
        fi
        
        if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
            log_error "Docker Compose is not installed or not in PATH"
            exit 1
        fi
        
        if ! docker info >/dev/null 2>&1; then
            log_error "Docker daemon is not running"
            exit 1
        fi
    fi
    
    # Check cloud CLI tools
    case "$DEPLOY_TARGET" in
        aws)
            if ! command -v aws >/dev/null 2>&1; then
                log_error "AWS CLI is not installed"
                exit 1
            fi
            ;;
        gcp)
            if ! command -v gcloud >/dev/null 2>&1; then
                log_error "Google Cloud CLI is not installed"
                exit 1
            fi
            ;;
        azure)
            if ! command -v az >/dev/null 2>&1; then
                log_error "Azure CLI is not installed"
                exit 1
            fi
            ;;
    esac
    
    log_success "Pre-deployment checks passed"
}

# Generate production environment file
generate_production_env() {
    log_step "Generating Production Environment Configuration"
    
    local env_file="$PROJECT_ROOT/.env.production"
    
    # Generate secure secrets
    local app_keys="$(openssl rand -base64 32 | tr -d '=+/'),$(openssl rand -base64 32 | tr -d '=+/')"
    local api_token_salt=$(openssl rand -base64 32 | tr -d '=+/')
    local admin_jwt_secret=$(openssl rand -base64 32 | tr -d '=+/')
    local transfer_token_salt=$(openssl rand -base64 32 | tr -d '=+/')
    local jwt_secret=$(openssl rand -base64 32 | tr -d '=+/')
    local webhook_secret=$(openssl rand -base64 32 | tr -d '=+/')
    
    cat > "$env_file" << EOF
# Production Environment Configuration
# Generated on: $(date)
# Version: $VERSION

# Environment
NODE_ENV=production
ENVIRONMENT=$ENVIRONMENT

# Server Configuration
HOST=0.0.0.0
PORT=1337
APP_KEYS="$app_keys"
API_TOKEN_SALT=$api_token_salt
ADMIN_JWT_SECRET=$admin_jwt_secret
TRANSFER_TOKEN_SALT=$transfer_token_salt

# JWT Configuration
JWT_SECRET=$jwt_secret
JWT_EXPIRES_IN=7d

# Database Configuration (Production)
DATABASE_CLIENT=postgres
DATABASE_HOST=\${DATABASE_HOST:-postgres}
DATABASE_PORT=\${DATABASE_PORT:-5432}
DATABASE_NAME=\${DATABASE_NAME:-strapi_prod}
DATABASE_USERNAME=\${DATABASE_USERNAME:-strapi_user}
DATABASE_PASSWORD=\${DATABASE_PASSWORD:-$(openssl rand -base64 32 | tr -d '=+/')}
DATABASE_SSL=\${DATABASE_SSL:-true}

# Treblle Configuration
TREBLLE_API_KEY=$TREBLLE_API_KEY
TREBLLE_PROJECT_ID=$TREBLLE_PROJECT_ID

# AI/LLM Configuration
OLLAMA_BASE_URL=\${OLLAMA_BASE_URL:-http://ollama:11434}
OLLAMA_MODEL=\${OLLAMA_MODEL:-llama2}
OPENAI_API_KEY=\${OPENAI_API_KEY}
OPENAI_MODEL=\${OPENAI_MODEL:-gpt-3.5-turbo}

# N8n Configuration
N8N_WEBHOOK_URL=\${N8N_WEBHOOK_URL:-http://n8n:5678/webhook/api-analysis}
N8N_API_KEY=\${N8N_API_KEY}

# Security Configuration
RATE_LIMIT_MAX=1000
RATE_LIMIT_WINDOW_MS=3600000
ENABLE_CORS=true
CORS_ORIGIN=\${CORS_ORIGIN:-https://$CUSTOM_DOMAIN}

# Performance Configuration
ENABLE_COMPRESSION=true
ENABLE_RESPONSE_CACHE=true
CACHE_TTL=3600

# Webhook Security
WEBHOOK_SECRET=$webhook_secret

# SSL Configuration
ENABLE_SSL=$ENABLE_SSL
SSL_CERT_PATH=\${SSL_CERT_PATH:-/etc/ssl/certs}
SSL_KEY_PATH=\${SSL_KEY_PATH:-/etc/ssl/private}

# Monitoring
ENABLE_MONITORING=$ENABLE_MONITORING
PROMETHEUS_ENABLED=\${PROMETHEUS_ENABLED:-true}
GRAFANA_ENABLED=\${GRAFANA_ENABLED:-true}

# Backup Configuration
ENABLE_BACKUP=$ENABLE_BACKUP
BACKUP_SCHEDULE=\${BACKUP_SCHEDULE:-0 2 * * *}
BACKUP_RETENTION_DAYS=\${BACKUP_RETENTION_DAYS:-30}

# Cloud Configuration
CLOUD_PROVIDER=\${CLOUD_PROVIDER:-$DEPLOY_TARGET}
CLOUD_REGION=\${CLOUD_REGION:-$CLOUD_REGION}
CUSTOM_DOMAIN=\${CUSTOM_DOMAIN:-$CUSTOM_DOMAIN}

EOF
    
    log_success "Production environment file generated: $env_file"
}

# Build and tag Docker images
build_docker_images() {
    log_step "Building Docker Images"
    
    cd "$PROJECT_ROOT"
    
    # Build Strapi image
    log_info "Building Strapi production image..."
    docker build -t "ai-api-strapi:$VERSION" -t "ai-api-strapi:latest" -f docker/Dockerfile.strapi ./strapi-backend
    
    # Build custom images if needed
    if [[ -f "docker/Dockerfile.nginx" ]]; then
        log_info "Building custom Nginx image..."
        docker build -t "ai-api-nginx:$VERSION" -t "ai-api-nginx:latest" -f docker/Dockerfile.nginx ./docker
    fi
    
    log_success "Docker images built successfully"
}

# Deploy with Docker Compose
deploy_docker() {
    log_step "Deploying with Docker Compose"
    
    cd "$PROJECT_ROOT"
    
    # Copy production environment
    cp .env.production .env
    
    # Create production docker-compose file
    local compose_file="docker-compose.prod.yml"
    
    cat > "$compose_file" << 'EOF'
version: '3.8'

services:
  strapi:
    image: ai-api-strapi:latest
    container_name: ai-api-strapi-prod
    restart: unless-stopped
    env_file: .env
    ports:
      - "1337:1337"
    volumes:
      - strapi_uploads:/opt/app/public/uploads
      - strapi_data:/opt/app/.tmp
    depends_on:
      - postgres
      - redis
    networks:
      - ai_api_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:1337/_health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    container_name: ai-api-postgres-prod
    restart: unless-stopped
    env_file: .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - ai_api_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DATABASE_USERNAME:-strapi_user}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: ai-api-redis-prod
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - ai_api_network

  nginx:
    image: nginx:alpine
    container_name: ai-api-nginx-prod
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/ssl:ro
    depends_on:
      - strapi
    networks:
      - ai_api_network

  ollama:
    image: ollama/ollama:latest
    container_name: ai-api-ollama-prod
    restart: unless-stopped
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - ai_api_network
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

volumes:
  postgres_data:
  strapi_uploads:
  strapi_data:
  redis_data:
  ollama_data:

networks:
  ai_api_network:
    driver: bridge
EOF
    
    # Add monitoring stack if enabled
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        cat >> "$compose_file" << 'EOF'

  prometheus:
    image: prom/prometheus:latest
    container_name: ai-api-prometheus-prod
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    networks:
      - ai_api_network

  grafana:
    image: grafana/grafana:latest
    container_name: ai-api-grafana-prod
    restart: unless-stopped
    env_file: .env
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - ai_api_network

volumes:
  prometheus_data:
  grafana_data:
EOF
    fi
    
    # Start services
    log_info "Starting production services..."
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "$compose_file" up -d
    else
        docker compose -f "$compose_file" up -d
    fi
    
    # Pull Ollama model
    log_info "Pulling AI model..."
    sleep 10
    docker exec ai-api-ollama-prod ollama pull llama2
    
    log_success "Docker deployment completed"
}

# Deploy to AWS
deploy_aws() {
    log_step "Deploying to AWS"
    
    # This would typically use AWS CDK, CloudFormation, or ECS
    log_info "AWS deployment not implemented in this starter kit"
    log_info "Consider using AWS CDK, ECS, or EC2 with Docker Compose"
    
    # Example AWS deployment steps:
    # 1. Create VPC and security groups
    # 2. Set up RDS for PostgreSQL
    # 3. Deploy to ECS or EC2
    # 4. Configure ALB and Route 53
    # 5. Set up CloudWatch monitoring
    
    log_warning "Manual AWS setup required"
}

# Deploy to Google Cloud Platform
deploy_gcp() {
    log_step "Deploying to Google Cloud Platform"
    
    log_info "GCP deployment not implemented in this starter kit"
    log_info "Consider using Cloud Run, GKE, or Compute Engine"
    
    log_warning "Manual GCP setup required"
}

# Deploy to Azure
deploy_azure() {
    log_step "Deploying to Azure"
    
    log_info "Azure deployment not implemented in this starter kit"
    log_info "Consider using Container Instances, AKS, or App Service"
    
    log_warning "Manual Azure setup required"
}

# Deploy to DigitalOcean
deploy_digitalocean() {
    log_step "Deploying to DigitalOcean"
    
    log_info "DigitalOcean deployment not implemented in this starter kit"
    log_info "Consider using App Platform or Droplets with Docker"
    
    log_warning "Manual DigitalOcean setup required"
}

# Health checks
run_health_checks() {
    log_step "Running Health Checks"
    
    local health_url="http://localhost:1337/_health"
    if [[ -n "$CUSTOM_DOMAIN" ]]; then
        if [[ "$ENABLE_SSL" == "true" ]]; then
            health_url="https://$CUSTOM_DOMAIN/_health"
        else
            health_url="http://$CUSTOM_DOMAIN/_health"
        fi
    fi
    
    log_info "Checking application health at: $health_url"
    
    for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
        if curl -f -s "$health_url" >/dev/null 2>&1; then
            log_success "Health check passed (attempt $i/$HEALTH_CHECK_RETRIES)"
            break
        else
            log_warning "Health check failed (attempt $i/$HEALTH_CHECK_RETRIES)"
            if [[ $i -eq $HEALTH_CHECK_RETRIES ]]; then
                log_error "Health checks failed after $HEALTH_CHECK_RETRIES attempts"
                return 1
            fi
            sleep $HEALTH_CHECK_DELAY
        fi
    done
    
    # Check individual services
    log_info "Checking individual services..."
    
    # Check Strapi API
    if curl -f -s "http://localhost:1337/api/health" >/dev/null 2>&1; then
        log_success "Strapi API is healthy"
    else
        log_warning "Strapi API health check failed"
    fi
    
    # Check Ollama
    if curl -f -s "http://localhost:11434/api/tags" >/dev/null 2>&1; then
        log_success "Ollama service is healthy"
    else
        log_warning "Ollama service health check failed"
    fi
    
    # Check PostgreSQL
    if docker exec ai-api-postgres-prod pg_isready -U "${DATABASE_USERNAME:-strapi_user}" >/dev/null 2>&1; then
        log_success "PostgreSQL is healthy"
    else
        log_warning "PostgreSQL health check failed"
    fi
    
    log_success "Health checks completed"
}

# Setup SSL certificates
setup_ssl() {
    if [[ "$ENABLE_SSL" != "true" ]]; then
        return 0
    fi
    
    log_step "Setting up SSL Certificates"
    
    if [[ -z "$CUSTOM_DOMAIN" ]]; then
        log_warning "No custom domain specified, skipping SSL setup"
        return 0
    fi
    
    # Create SSL directory
    mkdir -p "$PROJECT_ROOT/ssl"
    
    # Check if certificates already exist
    if [[ -f "$PROJECT_ROOT/ssl/$CUSTOM_DOMAIN.crt" && -f "$PROJECT_ROOT/ssl/$CUSTOM_DOMAIN.key" ]]; then
        log_info "SSL certificates already exist for $CUSTOM_DOMAIN"
        return 0
    fi
    
    # Generate self-signed certificate for development
    log_info "Generating self-signed SSL certificate for $CUSTOM_DOMAIN"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$PROJECT_ROOT/ssl/$CUSTOM_DOMAIN.key" \
        -out "$PROJECT_ROOT/ssl/$CUSTOM_DOMAIN.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$CUSTOM_DOMAIN"
    
    log_success "SSL certificate generated"
    log_warning "Using self-signed certificate. For production, use Let's Encrypt or a proper CA"
}

# Setup monitoring
setup_monitoring() {
    if [[ "$ENABLE_MONITORING" != "true" ]]; then
        return 0
    fi
    
    log_step "Setting up Monitoring"
    
    # Create monitoring configuration
    mkdir -p "$PROJECT_ROOT/monitoring"
    
    # Prometheus configuration
    cat > "$PROJECT_ROOT/monitoring/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files: []

scrape_configs:
  - job_name: 'strapi'
    static_configs:
      - targets: ['strapi:1337']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
    scrape_interval: 30s

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    scrape_interval: 30s

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']
    scrape_interval: 30s
EOF
    
    log_success "Monitoring configuration created"
}

# Setup backups
setup_backups() {
    if [[ "$ENABLE_BACKUP" != "true" ]]; then
        return 0
    fi
    
    log_step "Setting up Automated Backups"
    
    # Create backup directory
    mkdir -p "$PROJECT_ROOT/backups"
    
    # Create backup script
    cat > "$PROJECT_ROOT/scripts/backup.sh" << 'EOF'
#!/bin/bash

# Database backup script
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="${DATABASE_NAME:-strapi_prod}"
DB_USER="${DATABASE_USERNAME:-strapi_user}"

# Create database backup
pg_dump -h postgres -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_DIR/db_backup_$DATE.sql"

# Compress backup
gzip "$BACKUP_DIR/db_backup_$DATE.sql"

# Clean up old backups (keep last 30 days)
find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: db_backup_$DATE.sql.gz"
EOF
    
    chmod +x "$PROJECT_ROOT/scripts/backup.sh"
    
    log_success "Backup system configured"
    log_info "Add to crontab: ${BACKUP_SCHEDULE:-0 2 * * *} /path/to/scripts/backup.sh"
}

# Generate deployment summary
generate_deployment_summary() {
    log_step "Generating Deployment Summary"
    
    local summary_file="deployment_summary_$VERSION.md"
    
    cat > "$summary_file" << EOF
# AI API Starter Kit Deployment Summary

**Deployment ID:** $VERSION  
**Environment:** $ENVIRONMENT  
**Target:** $DEPLOY_TARGET  
**Date:** $(date)  
**Domain:** ${CUSTOM_DOMAIN:-localhost}  

## Services Deployed

- ✅ **Strapi API** - Main application backend
- ✅ **PostgreSQL** - Primary database
- ✅ **Redis** - Caching layer
- ✅ **Nginx** - Reverse proxy and load balancer
- ✅ **Ollama** - Local AI model hosting
$(if [[ "$ENABLE_MONITORING" == "true" ]]; then echo "- ✅ **Prometheus** - Metrics collection"; fi)
$(if [[ "$ENABLE_MONITORING" == "true" ]]; then echo "- ✅ **Grafana** - Monitoring dashboards"; fi)

## Access URLs

- **API Endpoint:** $(if [[ "$ENABLE_SSL" == "true" ]]; then echo "https://"; else echo "http://"; fi)${CUSTOM_DOMAIN:-localhost}:1337/api
- **Admin Panel:** $(if [[ "$ENABLE_SSL" == "true" ]]; then echo "https://"; else echo "http://"; fi)${CUSTOM_DOMAIN:-localhost}:1337/admin
- **API Documentation:** $(if [[ "$ENABLE_SSL" == "true" ]]; then echo "https://"; else echo "http://"; fi)${CUSTOM_DOMAIN:-localhost}:1337/documentation
$(if [[ "$ENABLE_MONITORING" == "true" ]]; then echo "- **Grafana Dashboard:** http://${CUSTOM_DOMAIN:-localhost}:3000"; fi)

## Configuration

- **SSL Enabled:** $ENABLE_SSL
- **Monitoring Enabled:** $ENABLE_MONITORING
- **Backups Enabled:** $ENABLE_BACKUP
- **Cloud Region:** ${CLOUD_REGION:-N/A}

## Security Notes

- All services are running with production security configurations
- Rate limiting is enabled (1000 requests/hour per IP)
- CORS is configured for specified origins
- Database passwords are auto-generated and secured
- Webhook secrets are randomly generated

## Next Steps

1. **Create Admin User:** Visit the admin panel to create your first admin user
2. **Configure DNS:** Point your domain to the server IP address
3. **Update SSL:** Replace self-signed certificates with proper SSL certificates
4. **Setup Monitoring:** Configure alerting in Grafana
5. **Test API:** Run integration tests against the deployed API

## Support

- **Logs:** \`docker logs ai-api-strapi-prod\`
- **Health Check:** \`curl $(if [[ "$ENABLE_SSL" == "true" ]]; then echo "https://"; else echo "http://"; fi)${CUSTOM_DOMAIN:-localhost}:1337/_health\`
- **Restart Services:** \`docker-compose -f docker-compose.prod.yml restart\`

## Rollback

To rollback this deployment:
\`\`\`bash
./scripts/rollback.sh $VERSION
\`\`\`

---

**Deployment completed successfully!** 🚀

EOF
    
    log_success "Deployment summary generated: $summary_file"
    
    # Display summary
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    DEPLOYMENT SUCCESSFUL!                   ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}🌐 Access your application:${NC}"
    if [[ -n "$CUSTOM_DOMAIN" ]]; then
        echo -e "   API: $(if [[ "$ENABLE_SSL" == "true" ]]; then echo "https://"; else echo "http://"; fi)$CUSTOM_DOMAIN:1337/api"
        echo -e "   Admin: $(if [[ "$ENABLE_SSL" == "true" ]]; then echo "https://"; else echo "http://"; fi)$CUSTOM_DOMAIN:1337/admin"
    else
        echo -e "   API: http://localhost:1337/api"
        echo -e "   Admin: http://localhost:1337/admin"
    fi
    
    echo -e "\n${YELLOW}📊 Monitor your application:${NC}"
    echo -e "   Treblle Dashboard: https://treblle.com (with your API key)"
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        echo -e "   Grafana: http://${CUSTOM_DOMAIN:-localhost}:3000"
    fi
    
    echo -e "\n${YELLOW}📁 Important files:${NC}"
    echo -e "   Environment: .env.production"
    echo -e "   Summary: $summary_file"
    echo -e "   Logs: $DEPLOYMENT_LOG"
}

# Main deployment function
main() {
    print_header
    
    # Start logging
    echo "Deployment started at $(date)" > "$DEPLOYMENT_LOG"
    
    # Parse arguments and load configuration
    parse_arguments "$@"
    load_config
    
    # Run pre-deployment checks
    pre_deployment_checks
    
    # Generate production configuration
    generate_production_env
    
    # Setup SSL if enabled
    setup_ssl
    
    # Setup monitoring if enabled
    setup_monitoring
    
    # Setup backups if enabled
    setup_backups
    
    # Deploy based on target
    case "$DEPLOY_TARGET" in
        docker)
            build_docker_images
            deploy_docker
            ;;
        aws)
            deploy_aws
            ;;
        gcp)
            deploy_gcp
            ;;
        azure)
            deploy_azure
            ;;
        digitalocean)
            deploy_digitalocean
            ;;
        *)
            log_error "Unknown deployment target: $DEPLOY_TARGET"
            exit 1
            ;;
    esac
    
    # Run health checks
    if ! run_health_checks; then
        log_error "Deployment failed health checks"
        exit 1
    fi
    
    # Generate deployment summary
    generate_deployment_summary
    
    log_success "Deployment completed successfully!"
}

# Cleanup function
cleanup() {
    if [[ $? -ne 0 ]]; then
        log_error "Deployment failed. Check logs: $DEPLOYMENT_LOG"
    fi
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"