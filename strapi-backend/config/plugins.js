module.exports = {
  // Auto-generated API documentation
  documentation: {
    enabled: true,
    config: {
      openapi: '3.0.0',
      info: {
        version: '1.0.0',
        title: 'AI API Analyzer - Treblle Starter Kit',
        description: 'API for analyzing and generating API personas using AI',
        contact: {
          name: 'Treblle DevRel Team',
          email: 'devrel@treblle.com',
          url: 'https://treblle.com'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      'x-strapi-config': {
        plugins: ['users-permissions', 'upload', 'i18n'],
        path: '/documentation',
      },
      servers: [
        {
          url: process.env.NODE_ENV === 'production' 
            ? 'https://your-api-domain.com/api' 
            : 'http://localhost:1337/api',
          description: process.env.NODE_ENV === 'production' ? 'Production' : 'Development'
        }
      ],
      security: [
        {
          bearerAuth: []
        }
      ]
    }
  },
  
  // User permissions and JWT authentication
  'users-permissions': {
    config: {
      jwt: {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      },
      register: {
        allowedFields: ['username', 'email', 'password', 'firstName', 'lastName'],
      },
      ratelimit: {
        interval: 60000,
        max: 5, // 5 registration attempts per minute
      }
    },
  },
  
  // File upload configuration
  upload: {
    config: {
      sizeLimit: parseInt(process.env.MAX_FILE_SIZE) || 10485760, // 10MB
      allowedFileTypes: process.env.ALLOWED_FILE_TYPES?.split(',') || [
        'application/json',
        'text/yaml',
        'text/plain'
      ],
    },
  },
  
  // Internationalization
  i18n: {
    enabled: true,
    config: {
      locales: ['en'],
      defaultLocale: 'en',
    }
  },
};