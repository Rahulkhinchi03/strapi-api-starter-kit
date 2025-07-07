module.exports = ({ env }) => ({
    auth: {
      secret: env('ADMIN_JWT_SECRET'),
    },
    apiToken: {
      salt: env('API_TOKEN_SALT'),
    },
    transfer: {
      token: {
        salt: env('TRANSFER_TOKEN_SALT'),
      },
    },
    
    // Security headers configuration
    helmet: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:', 'wss:'],
          'img-src': ["'self'", 'data:', 'blob:', 'https:'],
          'media-src': ["'self'", 'data:', 'blob:', 'https:'],
          'script-src': ["'self'", "'unsafe-inline'", 'https:'],
          'style-src': ["'self'", "'unsafe-inline'", 'https:'],
          'font-src': ["'self'", 'https:', 'data:'],
          upgradeInsecureRequests: env('NODE_ENV') === 'production' ? [] : null,
        },
      },
      crossOriginEmbedderPolicy: false,
      crossOriginResourcePolicy: {
        policy: 'cross-origin'
      },
      frameguard: {
        action: 'deny'
      },
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
      },
      noSniff: true,
      originAgentCluster: true,
      permittedCrossDomainPolicies: false,
      referrerPolicy: {
        policy: 'same-origin'
      },
      xssFilter: true,
    },
    
    // Rate limiting configuration
    rateLimit: {
      interval: env.int('RATE_LIMIT_WINDOW_MS', 900000), // 15 minutes
      max: env.int('RATE_LIMIT_MAX', 100),
      message: {
        error: 'Too many requests from this IP, please try again later.',
        statusCode: 429,
      },
      skipSuccessfulRequests: false,
      skipFailedRequests: false,
      standardHeaders: true,
      legacyHeaders: false,
    },
    
    // CORS configuration
    cors: {
      enabled: env.bool('ENABLE_CORS', true),
      origin: env('CORS_ORIGIN', 'http://localhost:3000').split(','),
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
      headers: ['Content-Type', 'Authorization', 'Origin', 'Accept', 'X-API-Key'],
      exposedHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
    },
    
    // Session configuration
    session: {
      enabled: true,
      client: 'cookie',
      key: 'strapi.sid',
      prefix: 'strapi:sess:',
      secretKeys: env.array('SESSION_KEYS', ['session-key-1', 'session-key-2']),
      httpOnly: true,
      maxAge: 86400000, // 1 day
      overwrite: true,
      signed: false,
      rolling: false,
      renew: false,
      secure: env('NODE_ENV') === 'production',
      sameSite: 'lax',
    },
  });