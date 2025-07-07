#!/bin/bash

# AI API Starter Kit - Local Development Setup Script
# Optimized for localhost development with Treblle API monitoring

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ASCII Art Banner
echo -e "${BLUE}"
cat << "EOF"
     _    ___    _    ____ ___   ____  _             _            
    / \  |_ _|  / \  |  _ \_ _| / ___|| |_ __ _ _ __| |_ ___ _ __ 
   / _ \  | |  / _ \ | |_) | |  \___ \| __/ _` | '__| __/ _ \ '__|
  / ___ \ | | / ___ \|  __/| |   ___) | || (_| | |  | ||  __/ |   
 /_/   \_\___/_/   \_\_|  |___| |____/ \__\__,_|_|   \__\___|_|   
                                                                  
 _____ _     _     _   _  _  ___  _  _     _____ ___ _____        
|_   _| |__ | |__ | | | || ||_ _|| \| |   |  _  |   |_   _|       
  | | | '_ \| '_ \| | | || | | | | . ` |   | | | | \ | | |         
  | | | |_) | |_) | | | || | | | | |\  |   | |_| |\ \| | |         
  |_| |_.__/|_.__/|_| |_||_||___||_| \_|   |_____| \_\_|_|         
                                                                  
EOF
echo -e "${NC}"

echo -e "${GREEN}🚀 AI API Starter Kit - Local Development Setup${NC}"
echo -e "${YELLOW}Treblle + Strapi + Local AI for API Analysis${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${PURPLE}============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate secure random string
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Check prerequisites
print_section "Checking Prerequisites"

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | cut -d'v' -f2)
    
    if [ "$NODE_MAJOR" -ge 18 ]; then
        print_status "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js version 18+ required. Current: $NODE_VERSION"
        echo "Please install Node.js 18+ from https://nodejs.org"
        exit 1
    fi
else
    print_error "Node.js not found. Please install Node.js 18+ from https://nodejs.org"
    exit 1
fi

# Check npm
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    print_status "npm found: $NPM_VERSION"
else
    print_error "npm not found. Please install npm"
    exit 1
fi

# Check Git
if command_exists git; then
    GIT_VERSION=$(git --version)
    print_status "Git found: $GIT_VERSION"
else
    print_error "Git not found. Please install Git"
    exit 1
fi

# Check curl
if command_exists curl; then
    print_status "curl found"
else
    print_error "curl not found. Please install curl"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "strapi-backend/package.json" ]]; then
    print_error "Please run this script from the project root directory"
    print_info "Expected structure: ./strapi-backend/package.json"
    exit 1
fi

print_status "All prerequisites met!"

# Treblle Configuration
print_section "Treblle Configuration"
echo -e "${BLUE}Get your Treblle credentials from: ${YELLOW}https://app.treblle.com${NC}"
echo -e "${BLUE}Treblle provides complete API observability and monitoring${NC}"
echo ""

# Check if .env already exists
ENV_EXISTS=false
if [ -f "strapi-backend/.env" ]; then
    print_warning ".env file already exists"
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE_ENV
    if [ "$OVERWRITE_ENV" != "y" ] && [ "$OVERWRITE_ENV" != "Y" ]; then
        print_status "Keeping existing .env file"
        ENV_EXISTS=true
    fi
fi

# Get Treblle credentials if creating new .env
if [ "$ENV_EXISTS" != true ]; then
    echo ""
    read -p "Enter your Treblle API Key: " TREBLLE_API_KEY
    read -p "Enter your Treblle Project ID: " TREBLLE_PROJECT_ID
    
    if [ -z "$TREBLLE_API_KEY" ] || [ -z "$TREBLLE_PROJECT_ID" ]; then
        print_error "Treblle credentials are required for API monitoring"
        print_info "Sign up for free at https://treblle.com"
        exit 1
    fi
    
    print_status "Treblle credentials captured"
fi

# Environment Configuration
print_section "Environment Configuration"

if [ "$ENV_EXISTS" != true ]; then
    print_info "Generating secure secrets and creating .env file..."
    
    # Generate secure secrets
    APP_KEY1=$(generate_secret)
    APP_KEY2=$(generate_secret)
    API_TOKEN_SALT=$(generate_secret)
    ADMIN_JWT_SECRET=$(generate_secret)
    TRANSFER_TOKEN_SALT=$(generate_secret)
    JWT_SECRET=$(generate_secret)
    WEBHOOK_SECRET=$(generate_secret)
    
    print_status "Creating .env file for local development..."
    
    cd strapi-backend
    
    cat > .env << EOF
# ===========================================
# AI API Starter Kit - Local Development
# ===========================================

# Server Configuration
HOST=0.0.0.0
PORT=1337
NODE_ENV=development

# Security Keys (Auto-generated)
APP_KEYS="$APP_KEY1,$APP_KEY2"
API_TOKEN_SALT=$API_TOKEN_SALT
ADMIN_JWT_SECRET=$ADMIN_JWT_SECRET
TRANSFER_TOKEN_SALT=$TRANSFER_TOKEN_SALT
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d

# Treblle Configuration (Required for API monitoring)
TREBLLE_API_KEY=$TREBLLE_API_KEY
TREBLLE_PROJECT_ID=$TREBLLE_PROJECT_ID

# Database Configuration (SQLite for local development)
DATABASE_CLIENT=sqlite
DATABASE_FILENAME=.tmp/data.db

# AI Configuration (Local Ollama - Free)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2

# Webhook Security
WEBHOOK_SECRET=$WEBHOOK_SECRET

# Security Configuration
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW_MS=900000
ENABLE_CORS=true
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:1337

# Performance Configuration
ENABLE_COMPRESSION=true
ENABLE_RESPONSE_CACHE=true
CACHE_TTL=300

# Session Configuration
SESSION_KEYS=session-key-1,session-key-2

# N8n Integration (Optional)
N8N_WEBHOOK_URL=http://localhost:5678/webhook/api-analysis
EOF

    cd ..
    print_status ".env file created successfully"
fi

# Validate environment configuration
validate_env_file() {
    print_info "Validating environment configuration..."
    
    if grep -q "your_treblle_api_key_here" strapi-backend/.env 2>/dev/null; then
        print_error "Please update TREBLLE_API_KEY in .env file"
        echo "Get your credentials from: https://app.treblle.com"
        exit 1
    fi
    
    if grep -q "your_treblle_project_id_here" strapi-backend/.env 2>/dev/null; then
        print_error "Please update TREBLLE_PROJECT_ID in .env file"
        echo "Get your credentials from: https://app.treblle.com"
        exit 1
    fi
    
    print_status "Environment configuration validated"
}

validate_env_file

# Install Dependencies
print_section "Installing Dependencies"

cd strapi-backend
print_info "Installing Strapi and dependencies..."
npm install

if [ $? -eq 0 ]; then
    print_status "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi
cd ..

# Ollama Setup for Local AI
print_section "Local AI Setup (Ollama)"

print_info "Setting up Ollama for local AI analysis..."

# Check if Ollama is installed
if command_exists ollama; then
    print_status "Ollama found"
    OLLAMA_INSTALLED=true
else
    print_warning "Ollama not found. Installing Ollama..."
    if command_exists curl; then
        curl -fsSL https://ollama.ai/install.sh | sh
        if [ $? -eq 0 ]; then
            print_status "Ollama installed successfully"
            OLLAMA_INSTALLED=true
        else
            print_error "Failed to install Ollama"
            print_info "Please install manually from https://ollama.ai"
            OLLAMA_INSTALLED=false
        fi
    else
        print_error "curl not found. Please install Ollama manually from https://ollama.ai"
        OLLAMA_INSTALLED=false
    fi
fi

if [ "$OLLAMA_INSTALLED" = true ]; then
    # Check if Ollama service is running
    print_info "Checking Ollama service..."
    
    if curl -f http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_status "Ollama service is running"
    else
        print_info "Starting Ollama service..."
        ollama serve &
        OLLAMA_PID=$!
        
        # Wait for Ollama to start
        echo "Waiting for Ollama to start..."
        sleep 5
        
        # Check again
        if curl -f http://localhost:11434/api/tags >/dev/null 2>&1; then
            print_status "Ollama service started successfully"
        else
            print_warning "Ollama service may not be fully ready"
        fi
    fi
    
    # Pull the default model
    print_info "Pulling Llama2 model (this may take a while on first run)..."
    ollama pull llama2
    
    if [ $? -eq 0 ]; then
        print_status "Llama2 model ready for AI analysis"
    else
        print_warning "Failed to pull Llama2 model. You can pull it later with: ollama pull llama2"
    fi
fi

# Database Setup
print_section "Database Setup"

cd strapi-backend
print_info "Setting up SQLite database for local development..."
print_info "Building Strapi application..."

npm run build

if [ $? -eq 0 ]; then
    print_status "Database and application built successfully"
else
    print_warning "Build completed with warnings"
fi

cd ..

# Health Check
print_section "Health Check"

print_info "Starting Strapi in development mode for health check..."

cd strapi-backend
# Start Strapi in background for testing
npm run develop &
STRAPI_PID=$!

# Wait for Strapi to start
echo "Waiting for Strapi to start..."
sleep 15

# Check if Strapi is running
if curl -f http://localhost:1337/_health >/dev/null 2>&1; then
    print_status "Strapi is running successfully!"
    STRAPI_HEALTHY=true
elif curl -f http://localhost:1337/admin >/dev/null 2>&1; then
    print_status "Strapi admin panel is accessible"
    STRAPI_HEALTHY=true
else
    print_warning "Strapi health check failed, but this might be normal on first run"
    STRAPI_HEALTHY=false
fi

# Check Ollama connection
if [ "$OLLAMA_INSTALLED" = true ]; then
    if curl -f http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_status "Ollama AI service is healthy"
    else
        print_warning "Ollama service not responding"
    fi
fi

# Kill the background Strapi process
if [ ! -z "$STRAPI_PID" ]; then
    kill $STRAPI_PID 2>/dev/null || true
fi

# Kill Ollama if we started it
if [ ! -z "$OLLAMA_PID" ]; then
    kill $OLLAMA_PID 2>/dev/null || true
fi

cd ..

# Final Instructions
print_section "🎉 Setup Complete!"

echo -e "${GREEN}Your AI API Starter Kit is ready for local development!${NC}"
echo ""

echo -e "${YELLOW}🚀 Start Development:${NC}"
echo "   cd strapi-backend"
echo "   npm run develop"
echo ""

echo -e "${YELLOW}🌐 Access Points:${NC}"
echo "   • Admin Panel: http://localhost:1337/admin"
echo "   • API Docs: http://localhost:1337/documentation"
echo "   • Health Check: http://localhost:1337/_health"
echo "   • API Base: http://localhost:1337/api"
echo ""

echo -e "${YELLOW}👤 Admin Setup:${NC}"
echo "   1. Open http://localhost:1337/admin"
echo "   2. Create your admin user account"
echo "   3. Start building your API!"
echo ""

echo -e "${YELLOW}🔑 Test Your API:${NC}"
echo "   1. Register a user:"
echo "      curl -X POST http://localhost:1337/api/auth/local/register \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -d '{\"username\":\"test\",\"email\":\"test@example.com\",\"password\":\"test123\"}'"
echo ""
echo "   2. Analyze an API endpoint:"
echo "      curl -X POST http://localhost:1337/api/api-analysis \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\"
echo "        -d '{\"input\":\"GET /users/{id}\",\"type\":\"endpoint\"}'"
echo ""

echo -e "${YELLOW}📊 Monitor with Treblle:${NC}"
echo "   • Dashboard: https://app.treblle.com"
echo "   • View all API requests, responses, and performance metrics"
echo "   • Real-time monitoring and error tracking"
echo ""

echo -e "${YELLOW}🤖 AI Features:${NC}"
echo "   • Endpoint Analysis: Analyze single API endpoints"
echo "   • OpenAPI Analysis: Analyze complete API specifications"
echo "   • Batch Processing: Analyze multiple endpoints at once"
echo "   • Export Results: JSON, CSV, and PDF formats"
echo ""

echo -e "${YELLOW}🛠️ Useful Commands:${NC}"
echo "   • Start development: npm run develop"
echo "   • Build application: npm run build"
echo "   • Check Ollama models: ollama list"
echo "   • Pull new AI model: ollama pull [model-name]"
echo ""

echo -e "${YELLOW}📚 Documentation:${NC}"
echo "   • Setup Guide: docs/setup-guide.md"
echo "   • API Documentation: docs/api-documentation.md"
echo "   • Treblle Docs: https://docs.treblle.com"
echo ""

if [ "$STRAPI_HEALTHY" = true ]; then
    echo -e "${GREEN}✅ Everything looks good! Ready to start developing.${NC}"
else
    echo -e "${YELLOW}⚠️  Some services may need manual verification.${NC}"
    echo -e "${YELLOW}   This is normal on first setup. Try starting with 'npm run develop'${NC}"
fi

echo ""
echo -e "${PURPLE}===========================================${NC}"
echo -e "${GREEN}🎊 Happy API Building with Treblle! 🎊${NC}"
echo -e "${PURPLE}===========================================${NC}"
echo ""

# Optional: Ask if user wants to start development server now
read -p "Would you like to start the development server now? (y/N): " START_NOW

if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
    echo ""
    print_info "Starting development server..."
    echo -e "${BLUE}Press Ctrl+C to stop the server${NC}"
    echo ""
    
    cd strapi-backend
    npm run develop
fi