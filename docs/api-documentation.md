# 📖 AI API Analyzer - API Documentation

## Overview

The AI API Analyzer provides intelligent analysis of API endpoints and OpenAPI specifications using advanced language models. Built following Treblle's 7 key lessons for REST API design, this API offers comprehensive API persona generation with detailed insights.

## Base URL

```
Development: http://localhost:1337/api
Production: https://your-domain.com/api
```

## Authentication

The API uses JWT (JSON Web Token) authentication. Include the token in the Authorization header:

```http
Authorization: Bearer <your_jwt_token>
```

### 8. Get User Statistics

Retrieve analysis statistics for the authenticated user.

```http
GET /api-analysis/stats
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "data": {
    "total_analyses": 156,
    "recent_analyses": 23,
    "type_distribution": [
      { "input_type": "endpoint", "count": 89 },
      { "input_type": "openapi_url", "count": 45 },
      { "input_type": "openapi_spec", "count": 22 }
    ],
    "average_confidence": 0.82,
    "activity_by_day": [
      { "date": "2024-12-07", "count": 12 },
      { "date": "2024-12-06", "count": 8 }
    ],
    "first_analysis": "2024-10-15T09:30:00.000Z",
    "last_analysis": "2024-12-07T15:45:00.000Z"
  }
}
```

### 9. Export Analyses

Export user analyses in various formats.

```http
GET /api-analysis/export?format=json&ids=1,2,3
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `format` (string): Export format (`json`, `csv`, `pdf`)
- `ids` (string, optional): Comma-separated analysis IDs (exports all if omitted)

**Response (200 OK):**
The response varies by format:
- **JSON**: Returns structured JSON data
- **CSV**: Returns CSV file with proper headers
- **PDF**: Returns PDF document (simplified text format in this starter)

## Input Types

### 1. Endpoint Analysis
Analyze single API endpoints with HTTP method and path.

**Examples:**
```json
{
  "input": "GET /users/{id}/followers",
  "type": "endpoint"
}
```

```json
{
  "input": "POST /api/v1/orders",
  "type": "endpoint"
}
```

### 2. OpenAPI URL Analysis
Analyze APIs by fetching their OpenAPI specification from a URL.

**Examples:**
```json
{
  "input": "https://petstore.swagger.io/v2/swagger.json",
  "type": "openapi_url"
}
```

### 3. OpenAPI Spec Analysis
Analyze APIs by providing the OpenAPI specification content directly.

**Examples:**
```json
{
  "input": "{\n  \"openapi\": \"3.0.0\",\n  \"info\": {\n    \"title\": \"Sample API\",\n    \"version\": \"1.0.0\"\n  },\n  \"paths\": {\n    \"/users\": {\n      \"get\": {\n        \"summary\": \"List users\"\n      }\n    }\n  }\n}",
  "type": "openapi_spec"
}
```

## Error Responses

### Standard Error Format
```json
{
  "error": "Error Type",
  "message": "Human-readable error message",
  "details": "Additional error details",
  "statusCode": 400,
  "timestamp": "2024-12-07T10:30:00.000Z"
}
```

### Common Error Codes

#### 400 Bad Request
- Invalid input format
- Missing required fields
- Validation errors

```json
{
  "error": "Validation Error",
  "message": "Invalid input type",
  "details": "Type must be one of: endpoint, openapi_url, openapi_spec",
  "statusCode": 400
}
```

#### 401 Unauthorized
- Missing or invalid JWT token
- Expired token

```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing authentication token",
  "statusCode": 401
}
```

#### 403 Forbidden
- Insufficient permissions
- Trying to access another user's data

```json
{
  "error": "Forbidden",
  "message": "You don't have permission to access this resource",
  "statusCode": 403
}
```

#### 404 Not Found
- Analysis not found
- Invalid endpoint

```json
{
  "error": "Not Found",
  "message": "Analysis not found",
  "statusCode": 404
}
```

#### 429 Too Many Requests
- Rate limit exceeded

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Please wait before making more requests.",
  "retryAfter": 900,
  "statusCode": 429
}
```

#### 500 Internal Server Error
- AI analysis failed
- System error

```json
{
  "error": "Internal Server Error",
  "message": "Analysis failed: AI service unavailable",
  "statusCode": 500
}
```

## Rate Limiting

The API implements rate limiting to ensure fair usage:

- **General API**: 100 requests per 15 minutes per IP/user
- **Authentication endpoints**: 10 requests per 15 minutes per IP
- **Sensitive endpoints**: 5 requests per 15 minutes per IP
- **Batch analysis**: 5 requests per 15 minutes per user

Rate limit headers are included in responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 85
X-RateLimit-Reset: 1701950400
```

## Caching

The API implements intelligent caching to improve performance:

- **Input-based caching**: Analyses are cached based on input hash
- **Cache TTL**: 5 minutes for development, 1 hour for production
- **Cache bypass**: Set `cache: false` in options to force fresh analysis

## Pagination

List endpoints support pagination with the following parameters:

- `page`: Page number (starts from 1)
- `pageSize`: Items per page (max 100)
- `sort`: Sort field and direction (`field:asc` or `field:desc`)

**Pagination Response:**
```json
{
  "data": [...],
  "meta": {
    "pagination": {
      "page": 1,
      "pageSize": 25,
      "pageCount": 4,
      "total": 98
    }
  }
}
```

## Filtering and Sorting

### Available Filters

#### Analysis Endpoints
- `input_type`: Filter by input type (`endpoint`, `openapi_url`, `openapi_spec`)
- `confidence_score[$gte]`: Minimum confidence score
- `confidence_score[$lte]`: Maximum confidence score
- `model_used`: Filter by AI model used
- `createdAt[$gte]`: Created after date
- `createdAt[$lte]`: Created before date

**Example:**
```http
GET /api-analysis?filters[input_type]=endpoint&filters[confidence_score][$gte]=0.8&sort=confidence_score:desc
```

### Available Sort Fields
- `createdAt`: Creation date
- `updatedAt`: Last update date
- `confidence_score`: Confidence score
- `processing_time`: Processing time

## Webhooks

### N8n Integration
The API provides webhook endpoints for seamless N8n integration:

```http
POST /api-analysis/webhook
```

**Webhook Security:**
- Requires `webhook_secret` in request body
- Secret must match `WEBHOOK_SECRET` environment variable
- No JWT authentication required (uses webhook secret instead)

### Webhook Events
The API can trigger webhooks to external services on certain events:

1. **Analysis Completed**: Triggered when an analysis is successfully completed
2. **Batch Analysis Completed**: Triggered when batch analysis finishes
3. **Error Occurred**: Triggered on analysis failures (optional)

## SDK and Libraries

### JavaScript/Node.js SDK Example

```javascript
const axios = require('axios');

class AIApiAnalyzer {
  constructor(baseUrl, jwtToken) {
    this.baseUrl = baseUrl;
    this.headers = {
      'Authorization': `Bearer ${jwtToken}`,
      'Content-Type': 'application/json'
    };
  }

  async analyze(input, type, options = {}) {
    const response = await axios.post(`${this.baseUrl}/api-analysis`, {
      input,
      type,
      options
    }, { headers: this.headers });
    
    return response.data;
  }

  async getAnalyses(page = 1, pageSize = 25) {
    const response = await axios.get(`${this.baseUrl}/api-analysis`, {
      params: { page, pageSize },
      headers: this.headers
    });
    
    return response.data;
  }

  async getStats() {
    const response = await axios.get(`${this.baseUrl}/api-analysis/stats`, {
      headers: this.headers
    });
    
    return response.data;
  }
}

// Usage
const analyzer = new AIApiAnalyzer('http://localhost:1337/api', 'your_jwt_token');

analyzer.analyze('GET /users/{id}', 'endpoint')
  .then(result => console.log(result))
  .catch(error => console.error(error));
```

### Python SDK Example

```python
import requests

class AIApiAnalyzer:
    def __init__(self, base_url, jwt_token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Content-Type': 'application/json'
        }
    
    def analyze(self, input_data, input_type, options=None):
        if options is None:
            options = {}
        
        payload = {
            'input': input_data,
            'type': input_type,
            'options': options
        }
        
        response = requests.post(
            f'{self.base_url}/api-analysis',
            json=payload,
            headers=self.headers
        )
        
        response.raise_for_status()
        return response.json()
    
    def get_analyses(self, page=1, page_size=25):
        params = {'page': page, 'pageSize': page_size}
        
        response = requests.get(
            f'{self.base_url}/api-analysis',
            params=params,
            headers=self.headers
        )
        
        response.raise_for_status()
        return response.json()

# Usage
analyzer = AIApiAnalyzer('http://localhost:1337/api', 'your_jwt_token')

result = analyzer.analyze('GET /users/{id}', 'endpoint')
print(result)
```

## OpenAPI Specification

The complete OpenAPI 3.0 specification is available at:
```
GET /documentation
```

This provides interactive API documentation with:
- Complete endpoint descriptions
- Request/response schemas
- Authentication examples
- Try-it-out functionality

## Performance Considerations

### Optimization Tips

1. **Use Caching**: Enable caching for repeated analyses
2. **Batch Processing**: Use batch endpoint for multiple analyses
3. **Appropriate Model Selection**: Choose the right AI model for your needs
4. **Pagination**: Use reasonable page sizes for list endpoints
5. **Filtering**: Use filters to reduce payload sizes

### Response Times

- **Endpoint Analysis**: ~1-3 seconds
- **OpenAPI URL Analysis**: ~3-10 seconds (includes fetching)
- **OpenAPI Spec Analysis**: ~2-5 seconds
- **Batch Analysis**: ~5-30 seconds (depends on batch size)

### Resource Limits

- **Max Input Size**: 10,000 characters
- **Batch Limit**: 10 items per request
- **File Upload**: 10MB max for OpenAPI specs
- **Rate Limits**: See Rate Limiting section

## Support and Resources

- **API Documentation**: Available at `/documentation`
- **GitHub Repository**: [github.com/treblle/ai-api-starter-kit](https://github.com/treblle/ai-api-starter-kit)
- **Treblle Documentation**: [docs.treblle.com](https://docs.treblle.com)
- **Support**: support@treblle.com Getting a JWT Token

#### Register a New User
```http
POST /auth/local/register
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepassword123",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login Existing User
```http
POST /auth/local
Content-Type: application/json

{
  "identifier": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com"
  }
}
```

## API Endpoints

### 1. Analyze API Endpoint or Spec

Generate an AI-powered analysis of an API endpoint or OpenAPI specification.

```http
POST /api-analysis
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "input": "GET /users/{id}/followers",
  "type": "endpoint",
  "options": {
    "model": "llama2",
    "detailed": false,
    "cache": true
  }
}
```

**Parameters:**
- `input` (string, required): API endpoint, OpenAPI spec URL, or spec content
- `type` (string, required): One of `endpoint`, `openapi_url`, `openapi_spec`
- `options` (object, optional):
  - `model` (string): AI model to use (`llama2`, `gpt-3.5-turbo`, etc.)
  - `detailed` (boolean): Whether to include detailed analysis
  - `cache` (boolean): Whether to use cached results if available

**Response (201 Created):**
```json
{
  "data": {
    "id": 42,
    "input": "GET /users/{id}/followers",
    "input_type": "endpoint",
    "input_hash": "sha256_hash_of_input",
    "ai_response": "Full AI analysis text...",
    "persona": {
      "purpose": "Fetches the followers of a specific user",
      "audience": "Social media or creator platform developers",
      "dataSensitivity": "medium",
      "authenticationFriction": "medium",
      "businessModel": "SaaS",
      "exampleUseCase": "A mobile app that shows follower lists on user profiles"
    },
    "confidence_score": 0.85,
    "model_used": "llama2",
    "processing_time": 1500,
    "createdAt": "2024-12-07T10:30:00.000Z",
    "updatedAt": "2024-12-07T10:30:00.000Z"
  },
  "cached": false,
  "message": "Analysis completed successfully"
}
```

### 2. Get Analysis History

Retrieve paginated list of your API analyses.

```http
GET /api-analysis
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `page` (integer, default: 1): Page number
- `pageSize` (integer, default: 25, max: 100): Items per page
- `sort` (string): Sort order (`createdAt:desc`, `createdAt:asc`, etc.)
- `filters[input_type]` (string): Filter by input type
- `filters[confidence_score][$gte]` (number): Minimum confidence score

**Example Request:**
```http
GET /api-analysis?page=1&pageSize=10&sort=createdAt:desc&filters[input_type]=endpoint
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 42,
      "input": "GET /users/{id}/followers",
      "input_type": "endpoint",
      "persona": { /* persona object */ },
      "confidence_score": 0.85,
      "createdAt": "2024-12-07T10:30:00.000Z"
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pageSize": 10,
      "pageCount": 5,
      "total": 42
    }
  }
}
```

### 3. Get Specific Analysis

Retrieve a specific analysis by ID.

```http
GET /api-analysis/{id}
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "data": {
    "id": 42,
    "input": "GET /users/{id}/followers",
    "input_type": "endpoint",
    "ai_response": "Full AI analysis...",
    "persona": { /* persona object */ },
    "confidence_score": 0.85,
    "model_used": "llama2",
    "processing_time": 1500,
    "title": "User Followers API",
    "notes": "Analyzed for mobile app integration",
    "tags": ["social", "users", "followers"],
    "createdAt": "2024-12-07T10:30:00.000Z"
  }
}
```

### 4. Update Analysis

Update analysis metadata (title, notes, tags).

```http
PUT /api-analysis/{id}
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "Updated Analysis Title",
  "notes": "Additional notes about this analysis",
  "tags": ["api", "social-media", "users"]
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": 42,
    "title": "Updated Analysis Title",
    "notes": "Additional notes about this analysis",
    "tags": ["api", "social-media", "users"],
    "updatedAt": "2024-12-07T11:00:00.000Z"
  }
}
```

### 5. Delete Analysis

Delete a specific analysis.

```http
DELETE /api-analysis/{id}
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "data": { "id": 42 },
  "message": "Analysis deleted successfully"
}
```

### 6. Batch Analysis

Analyze multiple API endpoints in a single request (max 10).

```http
POST /api-analysis/batch
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "inputs": [
    {
      "input": "GET /users/{id}",
      "type": "endpoint"
    },
    {
      "input": "POST /users",
      "type": "endpoint"
    },
    {
      "input": "https://api.example.com/openapi.json",
      "type": "openapi_url"
    }
  ],
  "options": {
    "model": "llama2",
    "detailed": false
  }
}
```

**Response (200 OK):**
```json
{
  "data": [
    { /* analysis result 1 */ },
    { /* analysis result 2 */ },
    { /* analysis result 3 */ }
  ],
  "errors": [],
  "summary": {
    "total": 3,
    "successful": 3,
    "failed": 0
  }
}
```

### 7. Webhook Endpoint (N8n Integration)

Process analysis via webhook (used by N8n workflows).

```http
POST /api-analysis/webhook
Content-Type: application/json
```

**Request Body:**
```json
{
  "input": "GET /api/users/{id}",
  "type": "endpoint",
  "webhook_secret": "your_webhook_secret",
  "callback_url": "https://your-n8n-instance.com/webhook/callback"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "response": "AI analysis text...",
    "persona": { /* persona object */ },
    "confidence": 0.85,
    "processingTime": 1200
  },
  "message": "Webhook processed successfully"
}
```

###