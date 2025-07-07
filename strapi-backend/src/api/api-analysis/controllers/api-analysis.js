'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const axios = require('axios');

module.exports = createCoreController('api::api-analysis.api-analysis', ({ strapi }) => ({
  
  async test(ctx) {
    // Check if Ollama is available
    let ollamaStatus = 'unavailable';
    let models = [];
    
    try {
      strapi.log.info('Checking Ollama connectivity...');
      const response = await axios.get('http://localhost:11434/api/tags', { timeout: 5000 });
      ollamaStatus = 'available';
      models = response.data.models?.map(m => m.name) || [];
      strapi.log.info(`Ollama connected with ${models.length} models`);
    } catch (error) {
      strapi.log.warn('Ollama not available:', error.message);
      ollamaStatus = 'unavailable';
    }

    ctx.send({
      message: 'AI API Analysis is working!',
      timestamp: new Date().toISOString(),
      treblle_configured: !!(process.env.TREBLLE_API_KEY && process.env.TREBLLE_PROJECT_ID),
      ollama_status: ollamaStatus,
      available_models: models,
      environment: process.env.NODE_ENV || 'development'
    });
  },

  async analyze(ctx) {
    try {
      const { input, type, options = {} } = ctx.request.body;
      
      strapi.log.info(`Starting analysis for ${type}: ${input}`);
      
      if (!input || !type) {
        strapi.log.warn('Missing required fields');
        return ctx.badRequest('Missing required fields: input and type');
      }

      const validTypes = ['endpoint', 'openapi_url', 'openapi_spec'];
      if (!validTypes.includes(type)) {
        strapi.log.warn(`Invalid type: ${type}`);
        return ctx.badRequest(`Invalid type. Must be one of: ${validTypes.join(', ')}`);
      }

      const startTime = Date.now();
      
      // Try real AI analysis first
      let aiResponse;
      let modelUsed = 'mock';
      let confidence = 0.7;
      
      try {
        strapi.log.info('Attempting AI analysis...');
        aiResponse = await generateAIAnalysis(input, type, options);
        modelUsed = 'llama2';
        confidence = 0.85;
        strapi.log.info('AI analysis completed successfully with llama2');
      } catch (aiError) {
        strapi.log.error('AI analysis failed:', aiError.message);
        strapi.log.info('Using enhanced mock analysis');
        aiResponse = generateEnhancedMock(input, type);
        modelUsed = 'mock';
        confidence = 0.7;
      }

      const persona = parsePersonaFromResponse(aiResponse, input, type);
      const processingTime = Date.now() - startTime;

      const analysis = {
        id: Date.now(),
        input: input,
        input_type: type,
        ai_response: aiResponse,
        persona: persona,
        confidence_score: confidence,
        model_used: modelUsed,
        processing_time: processingTime,
        createdAt: new Date().toISOString()
      };

      strapi.log.info(`Analysis completed with ${modelUsed}, confidence: ${confidence}`);

      ctx.send({
        data: analysis,
        message: `Analysis completed successfully using ${modelUsed}`,
        cached: false
      });

    } catch (error) {
      strapi.log.error('Analysis controller error:', error);
      ctx.internalServerError('Failed to analyze API', { 
        error: error.message,
        stack: error.stack 
      });
    }
  }

}));

// Generate AI analysis using Ollama
async function generateAIAnalysis(input, type, options = {}) {
  const model = options.model || 'llama2';
  
  console.log('Calling Ollama API with model:', model);
  
  const prompt = `You are an experienced API analyst. Analyze this ${type} and provide insights:

Input: ${input}

Provide analysis in this format:
**Purpose**: [What this API does]
**Audience**: [Who would use this]
**Data Sensitivity**: [low/medium/high]
**Authentication Friction**: [low/medium/high]
**Business Model**: [Internal/SaaS/Open API/Monetized]
**Example Use Case**: [Real-world usage example]

Be specific and practical.`;

  try {
    const response = await axios.post('http://localhost:11434/api/generate', {
      model: model,
      prompt: prompt,
      stream: false,
      options: {
        temperature: 0.7,
        max_tokens: 800
      }
    }, {
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (!response.data || !response.data.response) {
      throw new Error('Invalid response from Ollama API');
    }

    console.log('Ollama response received successfully');
    return response.data.response;
  } catch (error) {
    console.error('Ollama API error details:', {
      message: error.message,
      code: error.code,
      response: error.response?.data
    });
    throw new Error(`Ollama API failed: ${error.message}`);
  }
}

// Enhanced mock analysis
function generateEnhancedMock(input, type) {
  console.log('Generating enhanced mock analysis for:', input);
  
  if (type === 'endpoint') {
    if (input.includes('/users') && input.includes('follow')) {
      return `**Purpose**: Social following functionality - allows users to follow/unfollow other users
**Audience**: Social media and creator platform developers
**Data Sensitivity**: medium — involves user relationships and social connections
**Authentication Friction**: high — requires authenticated user to perform social actions
**Business Model**: SaaS — typical social platform feature
**Example Use Case**: Instagram-like app where users can follow content creators`;
    } else if (input.includes('/users')) {
      return `**Purpose**: User profile management - retrieves or updates user profile information
**Audience**: Frontend developers building user account features
**Data Sensitivity**: medium — contains personal user information
**Authentication Friction**: medium — user must be authenticated to access profiles
**Business Model**: SaaS — core user management functionality
**Example Use Case**: Profile pages in social apps, account settings in web applications`;
    } else if (input.includes('/auth') || input.includes('/login')) {
      return `**Purpose**: User authentication and authorization services
**Audience**: Application developers implementing login systems
**Data Sensitivity**: high — handles sensitive authentication credentials
**Authentication Friction**: low — this IS the authentication endpoint
**Business Model**: Internal — core authentication infrastructure
**Example Use Case**: Login flows for web and mobile applications`;
    } else if (input.includes('/products') || input.includes('/reviews')) {
      return `**Purpose**: E-commerce product and review management
**Audience**: E-commerce platform developers and retailers
**Data Sensitivity**: low — public product information and reviews
**Authentication Friction**: low — product data typically public, reviews may require auth
**Business Model**: SaaS — e-commerce platform service
**Example Use Case**: Online stores, marketplace platforms, review systems`;
    }
  }
  
  return `**Purpose**: API functionality for ${input}
**Audience**: Application developers and system integrators
**Data Sensitivity**: medium — standard API data handling
**Authentication Friction**: medium — likely requires authentication
**Business Model**: SaaS — business API service
**Example Use Case**: Integration with business applications and workflows`;
}

// Parse persona from response
function parsePersonaFromResponse(response, input, type) {
  console.log('Parsing persona from response...');
  
  const persona = {
    purpose: '',
    audience: '',
    dataSensitivity: 'medium',
    authenticationFriction: 'medium',
    businessModel: 'SaaS',
    exampleUseCase: ''
  };

  try {
    if (!response) {
      throw new Error('No response to parse');
    }

    // Extract from structured response
    const purposeMatch = response.match(/\*\*Purpose\*\*:\s*(.+?)(?=\*\*|$)/is);
    if (purposeMatch) {
      persona.purpose = purposeMatch[1].trim().replace(/\n.*$/, '');
    }

    const audienceMatch = response.match(/\*\*Audience\*\*:\s*(.+?)(?=\*\*|$)/is);
    if (audienceMatch) {
      persona.audience = audienceMatch[1].trim().replace(/\n.*$/, '');
    }

    const sensitivityMatch = response.match(/\*\*Data Sensitivity\*\*:\s*(\w+)/i);
    if (sensitivityMatch) {
      const sensitivity = sensitivityMatch[1].toLowerCase();
      if (['low', 'medium', 'high'].includes(sensitivity)) {
        persona.dataSensitivity = sensitivity;
      }
    }

    const frictionMatch = response.match(/\*\*Authentication Friction\*\*:\s*(\w+)/i);
    if (frictionMatch) {
      const friction = frictionMatch[1].toLowerCase();
      if (['low', 'medium', 'high'].includes(friction)) {
        persona.authenticationFriction = friction;
      }
    }

    const businessMatch = response.match(/\*\*Business Model\*\*:\s*(.+?)(?=\*\*|$)/is);
    if (businessMatch) {
      const business = businessMatch[1].trim().replace(/\n.*$/, '');
      const validModels = ['Internal', 'SaaS', 'Open API', 'Monetized'];
      const found = validModels.find(model => business.toLowerCase().includes(model.toLowerCase()));
      if (found) persona.businessModel = found;
    }

    const useCaseMatch = response.match(/\*\*Example Use Case\*\*:\s*(.+?)(?=\*\*|$)/is);
    if (useCaseMatch) {
      persona.exampleUseCase = useCaseMatch[1].trim().replace(/\n.*$/, '');
    }

    // Fallback if no purpose extracted
    if (!persona.purpose) {
      if (input.includes('user')) {
        persona.purpose = 'User management and data operations';
        persona.audience = 'Frontend and mobile developers';
      } else if (input.includes('auth')) {
        persona.purpose = 'Authentication and authorization services';
        persona.audience = 'Application developers';
        persona.dataSensitivity = 'high';
      } else {
        persona.purpose = `API functionality for ${input.split(' ')[1] || input}`;
        persona.audience = 'Application developers';
      }
    }

    console.log('Persona parsed successfully:', persona);

  } catch (error) {
    console.error('Error parsing persona response:', error.message);
    
    // Return fallback persona
    persona.purpose = `Analysis of ${type}: ${input}`;
    persona.audience = 'Application developers';
    persona.exampleUseCase = `Integration with ${input.includes('user') ? 'user management' : 'business'} systems`;
  }

  return persona;
}
