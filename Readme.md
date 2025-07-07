# 🤖 AI API Starter Kit - Treblle + Strapi + N8n

> **Built by the Treblle DevRel Team** - Following Treblle's 7 Key Lessons for REST API Excellence

An intelligent API analysis platform that combines the power of **Treblle's API observability**, **Strapi's headless CMS**, and **N8n's workflow automation** to create AI-powered API personas and insights.

## 🚀 What This Kit Does

Transform any API endpoint or OpenAPI specification into actionable insights:

```
Input: GET /users/{id}/followers
Output: 
- Purpose: Fetches the followers of a specific user
- Audience: Social media or creator platform developers  
- Data Sensitivity: Medium — involves user relationships, but not PII
- Authentication Friction: Medium — likely requires user auth token
- Business Model: Likely SaaS or platform API with user accounts
- Example Use Case: A mobile app that shows follower lists on user profiles
```

## ✨ Features

- 🔍 **AI-Powered API Analysis** - Analyze endpoints or OpenAPI specs with local LLMs (Ollama) or OpenAI
- 📊 **API Observability** - Complete request/response monitoring with Treblle
- 🔐 **Production Security** - JWT auth, rate limiting, CORS, helmet protection
- 🤖 **N8n Automation** - Webhook workflows for seamless integrations
- 📈 **Analytics Dashboard** - Track analysis history, confidence scores, and trends
- 🔄 **Batch Processing** - Analyze multiple endpoints simultaneously
- 📄 **Multiple Formats** - Support for endpoints, OpenAPI URLs, and spec content
- 🌐 **Export Options** - JSON, CSV, and PDF export capabilities

## 🛠️ Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **API Framework** | Strapi v4 | Headless CMS and API backend |
| **AI/LLM** | Ollama (Local) / OpenAI | API analysis and persona generation |
| **Observability** | Treblle | Complete API monitoring and analytics |
| **Automation** | N8n | Workflow automation and webhooks |
| **Database** | SQLite (dev) / PostgreSQL (prod) | Data persistence |
| **Authentication** | JWT + bcrypt | Secure user authentication |
| **Security** | Helmet + CORS + Rate Limiting | Production-grade security |

## 🎯 Quick Start (5 minutes)

### Prerequisites

- **Node.js** v18+ 
- **npm** or **yarn**
- **Docker** (optional, for containerized setup)
- **Treblle Account** (free at [treblle.com](https://treblle.com))

### Option 1: Automated Setup

```bash
# Clone the repository
git clone https://github.com/treblle/ai-api-starter-kit.git
cd ai-api-starter-kit

# Run the setup script
chmod +x start.sh
./start.sh
```

The script will guide you through:
1. Creating environment configuration
2. Installing dependencies  
3. Setting up Ollama (local AI)
4. Starting all services

### Option 2: Manual Setup

1. **Configure Environment**
   ```bash
   cp .env.example strapi-backend/.env
   # Edit .env with your Treblle credentials
   ```

2. **Install Dependencies**
   ```bash
   cd strapi-backend
   npm install
   ```

3. **Setup Ollama (Local AI)**
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Start service and pull model
   ollama serve
   ollama pull llama2
   ```

4. **Start Strapi**
   ```bash
   npm run develop
   ```

### Option 3: Docker Setup

```bash
# Start all services with Docker
docker-compose up -d

# Pull AI model
docker exec ai-api-ollama ollama pull llama2
```

## 🎮 Usage Examples

### 1. Analyze Single Endpoint

```bash
curl -X POST http://localhost:1337/api/api-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "input": "GET /users/{id}/followers",
    "type": "endpoint"
  }'
```

### 2. Analyze OpenAPI Spec

```bash
curl -X POST http://localhost:1337/api/api-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "input": "https://petstore.swagger.io/v2/swagger.json",
    "type": "openapi_url"
  }'
```

### 3. Batch Analysis

```bash
curl -X POST http://localhost:1337/api/api-analysis/batch \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "inputs": [
      {"input": "GET /users", "type": "endpoint"},
      {"input": "POST /users", "type": "endpoint"},
      {"input": "GET /users/{id}", "type": "endpoint"}
    ]
  }'
```

### 4. N8n Webhook Integration

```bash
curl -X POST http://localhost:5678/webhook/api-analysis \
  -H "Content-Type: application/json" \
  -d '{
    "input": "DELETE /users/{id}",
    "type": "endpoint",
    "webhook_secret": "your_webhook_secret"
  }'
```

## 📖 API Documentation

### Authentication

Get a JWT token by registering/logging in:

```bash
# Register
curl -X POST http://localhost:1337/api/auth/local/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "developer",
    "email": "dev@example.com", 
    "password": "securepassword123"
  }'

# Login
curl -X POST http://localhost:1337/api/auth/local \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "dev@example.com",
    "password": "securepassword123"  
  }'
```

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api-analysis` | Analyze single API endpoint/spec |
| `GET` | `/api-analysis` | Get analysis history (paginated) |
| `GET` | `/api-analysis/{id}` | Get specific analysis |
| `PUT` | `/api-analysis/{id}` | Update analysis metadata |
| `DELETE` | `/api-analysis/{id}` | Delete analysis |
| `POST` | `/api-analysis/batch` | Batch analyze multiple endpoints |
| `GET` | `/api-analysis/stats` | Get user statistics |
| `GET` | `/api-analysis/export` | Export analyses (JSON/CSV/PDF) |
| `POST` | `/api-analysis/webhook` | N8n webhook endpoint |

Complete API documentation available at: `http://localhost:1337/documentation`

## 🔧 Configuration

### Environment Variables

```bash
# Treblle (Required)
TREBLLE_API_KEY=your_api_key
TREBLLE_PROJECT_ID=your_project_id

# AI Configuration  
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2
# OR
OPENAI_API_KEY=your_openai_key
OPENAI_MODEL=gpt-3.5-turbo

# Security
JWT_SECRET=your_jwt_secret
WEBHOOK_SECRET=your_webhook_secret

# Performance
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW_MS=900000
ENABLE_CORS=true
```

### Available AI Models

**Ollama (Local, Free):**
- `llama2` - General purpose 7B model
- `llama2:13b` - Larger, more capable model  
- `codellama` - Code-specific model
- `mistral` - Fast and efficient model

**OpenAI (Paid API):**
- `gpt-3.5-turbo` - Fast and cost-effective
- `gpt-4` - Most capable model
- `gpt-4-turbo` - Latest with improvements

## 🔍 Treblle Integration

This kit showcases **Treblle's official Strapi SDK** (`@treblle/strapi`) for complete API observability:

### Features Monitored
- 📊 **Request/Response Logging** - Complete payload monitoring
- ⚡ **Performance Metrics** - Response times and throughput  
- 🐛 **Error Tracking** - Automatic error detection and alerting
- 👥 **User Analytics** - API usage patterns and trends
- 🔒 **Security Monitoring** - Suspicious activity detection

### Configuration

```javascript
// config/middlewares.js
module.exports = [
  'plugin::treblle.treblle', // Add Treblle middleware
  // ... other middlewares
]

// config/plugins.js  
module.exports = {
  treblle: {
    config: {
      additionalFieldsToMask: ['password', 'token', 'secret'],
      routesToMonitor: ['api', 'webhook'],
    },
  },
}
```

View your API analytics at: [app.treblle.com](https://app.treblle.com)

## 🤖 N8n Workflows

The kit includes pre-built N8n workflows for:

### 1. API Analysis Workflow
- **Trigger**: Webhook endpoint
- **Process**: Input validation and formatting
- **Analyze**: Call Strapi API for AI analysis  
- **Response**: Return formatted results
- **Notify**: Send to Slack/Discord/Email (optional)

### 2. Batch Processing Workflow
- **Trigger**: File upload or API list
- **Process**: Split into individual analyses
- **Analyze**: Process each endpoint/spec
- **Aggregate**: Combine results with insights
- **Export**: Generate report in requested format

Access N8n at: `http://localhost:5678` (admin/admin123)

## 📊 Following Treblle's 7 Key Lessons

This starter kit demonstrates all of Treblle's REST API best practices:

1. **✅ Use Consistent Naming** - Clear, descriptive endpoint names
2. **✅ Use HTTP Status Codes Correctly** - Proper 200/201/400/404/500 responses  
3. **✅ Use HTTP Methods Correctly** - GET/POST/PUT/DELETE semantic usage
4. **✅ Use Pagination** - Efficient data loading with page/limit params
5. **✅ Use Proper Error Handling** - Structured error responses with details
6. **✅ Use API Versioning** - Future-proof API design patterns
7. **✅ Use Monitoring & Analytics** - Complete observability with Treblle

## 🔒 Security Features

- **🔐 JWT Authentication** - Secure token-based auth with bcrypt
- **🛡️ Rate Limiting** - DDoS protection and abuse prevention  
- **🌐 CORS Configuration** - Secure cross-origin requests
- **🔒 Helmet Security** - Security headers and protection
- **🚫 Input Validation** - Joi schema validation on all inputs
- **🕵️ Access Control** - User-based resource ownership
- **🔑 Webhook Security** - Secret-based webhook validation

## 📈 Performance Optimizations

- **⚡ Response Compression** - Gzip compression for faster transfers
- **🗄️ Database Connection Pooling** - Efficient database connections
- **💾 Intelligent Caching** - Input-based analysis caching
- **📄 Pagination** - Efficient data loading and transfer
- **🔄 Async Processing** - Non-blocking AI analysis operations
- **📊 Resource Monitoring** - Health checks and metrics

## 🚀 Deployment

### Docker Production Deployment

```bash
# Use the production deployment script
chmod +x deploy.sh
./deploy.sh --target docker --environment production --domain your-api.com
```

### Manual Production Setup

1. **Environment Configuration**
   ```bash
   cp .env.example .env.production
   # Configure production values
   ```

2. **Database Setup**
   ```bash
   # Use PostgreSQL for production
   DATABASE_CLIENT=postgres
   DATABASE_HOST=your-postgres-host
   DATABASE_NAME=strapi_prod
   ```

3. **SSL Configuration**
   ```bash
   # Enable HTTPS
   ENABLE_SSL=true
   SSL_CERT_PATH=/path/to/cert
   SSL_KEY_PATH=/path/to/key
   ```

4. **Deploy with Docker**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 🧪 Testing

```bash
# Run tests
npm test

# Test specific endpoints
npm run test:api

# Load testing
npm run test:load

# Security testing  
npm run test:security
```

## 📚 Documentation

- **[Setup Guide](docs/setup-guide.md)** - Detailed installation instructions
- **[API Documentation](docs/api-documentation.md)** - Complete API reference
- **[N8n Workflows](docs/n8n-workflows.md)** - Workflow configuration guide
- **[Deployment Guide](docs/deployment.md)** - Production deployment instructions

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes  
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **📧 Email**: devrel@treblle.com
- **💬 Discord**: [Join our community](https://discord.gg/treblle)
- **🐛 Issues**: [GitHub Issues](https://github.com/treblle/ai-api-starter-kit/issues)
- **📖 Docs**: [docs.treblle.com](https://docs.treblle.com)

## 🙏 Acknowledgments

- **Treblle Team** - For amazing API observability platform
- **Strapi Team** - For the excellent headless CMS
- **N8n Team** - For powerful workflow automation
- **Ollama Team** - For making local LLMs accessible
- **Open Source Community** - For inspiration and contributions

---

**Built with ❤️ by the Treblle DevRel Team**

*Ready to build better APIs? Start with this kit and see the Treblle difference!*