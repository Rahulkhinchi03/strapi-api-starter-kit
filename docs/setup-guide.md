# 🚀 AI API Starter Kit Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v18 or higher)
- **npm** or **yarn**
- **Docker** and **Docker Compose** (for containerized setup)
- **Git**

## 🎯 Quick Start (5 minutes)

### Option 1: Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/treblle/ai-api-starter-kit.git
   cd ai-api-starter-kit
   ```

2. **Setup Strapi Backend**
   ```bash
   cd strapi-backend
   cp .env.example .env
   npm install
   ```

3. **Configure Environment Variables**
   
   Edit `.env` file with your credentials:
   ```bash
   # Get these from your Treblle dashboard (https://treblle.com)
   TREBLLE_API_KEY=your_treblle_api_key_here
   TREBLLE_PROJECT_ID=your_treblle_project_id_here
   
   # Generate secure secrets
   APP_KEYS="$(openssl rand -base64 32),$(openssl rand -base64 32)"
   API_TOKEN_SALT="$(openssl rand -base64 32)"
   ADMIN_JWT_SECRET="$(openssl rand -base64 32)"
   TRANSFER_TOKEN_SALT="$(openssl rand -base64 32)"
   JWT_SECRET="$(openssl rand -base64 32)"
   WEBHOOK_SECRET="$(openssl rand -base64 32)"
   ```

4. **Start Ollama (for local AI)**
   ```bash
   # Install Ollama (https://ollama.ai)
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Start Ollama service
   ollama serve
   
   # In another terminal, pull the model
   ollama pull llama2
   ```

5. **Start Strapi**
   ```bash
   npm run develop
   ```

6. **Create Admin User**
   
   Visit http://localhost:1337/admin and create your admin account.

### Option 2: Docker Setup (Recommended for Production)

1. **Clone and configure**
   ```bash
   git clone https://github.com/treblle/ai-api-starter-kit.git
   cd ai-api-starter-kit
   cp .env.example .env
   ```

2. **Configure environment variables**
   
   Edit `.env` file with your Treblle credentials.

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Pull Ollama model**
   ```bash
   docker exec -it ai-api-ollama ollama pull llama2
   ```

5. **Access services**
   - Strapi Admin: http://localhost:1337/admin
   - API Documentation: http://localhost:1337/documentation
   - N8n Workflows: http://localhost:5678
   - Ollama API: http://localhost:11434

## 🔧 Configuration Details

### Treblle Setup

1. **Create Treblle Account**
   - Visit [treblle.com](https://treblle.com)
   - Sign up for a free account
   - Create a new project

2. **Get API Credentials**
   - Go to your project dashboard
   - Copy your `API Key` and `Project ID`
   - Add them to your `.env` file

### N8n Workflow Setup

1. **Access N8n**
   - Open http://localhost:5678
   - Login with credentials from `.env` file (default: admin/admin123)

2. **Import Workflows**
   ```bash
   # Copy workflow files
   cp n8n-workflows/*.json /path/to/n8n/workflows/
   ```

3. **Configure Credentials**
   - Add Strapi API credentials in N8n
   - Set webhook URLs and secrets

### AI Model Configuration

#### Option A: Ollama (Local, Free)
```bash
# Available models
ollama pull llama2        # 7B parameters
ollama pull llama2:13b    # 13B parameters
ollama pull codellama     # Code-specific model
ollama pull mistral       # Mistral 7B
```

#### Option B: OpenAI API
```bash
# Add to .env
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-3.5-turbo
```

#### Option C: Other OpenAI-Compatible APIs
```bash
# For services like Together AI, Groq, etc.
OPENAI_BASE_URL=https://api.together.xyz/v1
OPENAI_API_KEY=your_api_key_here
OPENAI_MODEL=meta-llama/Llama-2-7b-chat-hf
```

## 🧪 Testing Your Setup

### 1. Test Strapi API
```bash
curl -X GET http://localhost:1337/api/health
```

### 2. Test Authentication
```bash
# Register a user
curl -X POST http://localhost:1337/api/auth/local/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

### 3. Test API Analysis
```bash
# Get JWT token first, then:
curl -X POST http://localhost:1337/api/api-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "input": "GET /users/{id}/followers",
    "type": "endpoint"
  }'
```

### 4. Test N8n Webhook
```bash
curl -X POST http://localhost:5678/webhook/api-analysis \
  -H "Content-Type: application/json" \
  -d '{
    "input": "POST /users",
    "type": "endpoint",
    "webhook_secret": "your_webhook_secret"
  }'
```

## 🔐 Security Configuration

### Production Security Checklist

- [ ] Change all default passwords
- [ ] Use strong, unique secrets for JWT and API tokens
- [ ] Enable HTTPS with proper SSL certificates
- [ ] Configure proper CORS origins
- [ ] Set up rate limiting
- [ ] Enable authentication for all sensitive endpoints
- [ ] Configure firewall rules
- [ ] Set up monitoring and logging

### Environment Variables for Production

```bash
# Security
NODE_ENV=production
ENABLE_CORS=true
CORS_ORIGIN=https://yourdomain.com

# Rate Limiting
RATE_LIMIT_MAX=1000
RATE_LIMIT_WINDOW_MS=3600000

# Database (use PostgreSQL in production)
DATABASE_CLIENT=postgres
DATABASE_HOST=your-postgres-host
DATABASE_NAME=strapi_prod
DATABASE_USERNAME=strapi_user
DATABASE_PASSWORD=secure_password
DATABASE_SSL=true
```

## 📊 Monitoring Setup

### Enable Monitoring Stack
```bash
# Start with monitoring services
docker-compose --profile monitoring up -d
```

Services included:
- **Prometheus**: Metrics collection (http://localhost:9090)
- **Grafana**: Dashboards (http://localhost:3000)
- **Treblle**: API observability (automatic)

### Key Metrics to Monitor

1. **API Performance**
   - Response times
   - Error rates
   - Request volume
   - Cache hit rates

2. **AI Analysis Metrics**
   - Processing times
   - Model accuracy
   - Queue lengths
   - Resource usage

3. **System Health**
   - CPU and memory usage
   - Database performance
   - Network latency
   - Disk space

## 🚨 Troubleshooting

### Common Issues

1. **Ollama Connection Failed**
   ```bash
   # Check if Ollama is running
   curl http://localhost:11434/api/tags
   
   # Restart Ollama service
   ollama serve
   ```

2. **Database Connection Error**
   ```bash
   # Check PostgreSQL is running
   docker ps | grep postgres
   
   # Check database credentials
   psql -h localhost -U strapi_user -d strapi_db
   ```

3. **N8n Workflow Not Triggering**
   - Check webhook URLs in configuration
   - Verify webhook secrets match
   - Check N8n logs: `docker logs ai-api-n8n`

4. **Treblle Not Tracking Requests**
   - Verify API key and project ID
   - Check middleware is properly loaded
   - Review Strapi logs for errors

### Getting Help

- **Documentation**: Check `/docs` folder for detailed guides
- **GitHub Issues**: Report bugs and feature requests
- **Treblle Support**: Contact support@treblle.com
- **Community**: Join our Discord/Slack community

## 🎉 Next Steps

Once your setup is complete:

1. **Explore the API Documentation** at http://localhost:1337/documentation
2. **Try the example workflows** in the N8n interface
3. **Check your API analytics** in the Treblle dashboard
4. **Customize the AI prompts** for your specific use case
5. **Deploy to production** using the Docker setup

## 📝 Additional Resources

- [Strapi Documentation](https://docs.strapi.io/)
- [N8n Documentation](https://docs.n8n.io/)
- [Ollama Models](https://ollama.ai/library)
- [Treblle Documentation](https://docs.treblle.com/)
- [API Best Practices Guide](./api-best-practices.md)