const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');

/**
 * Rate limiting middleware following Treblle's performance best practices
 * Implements both rate limiting and speed limiting for DDoS protection
 */

// General API rate limiter
const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100, // Limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    statusCode: 429,
    details: 'Rate limit exceeded. Please wait before making more requests.',
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  skipSuccessfulRequests: false,
  skipFailedRequests: false,
  keyGenerator: (req) => {
    // Use both IP and user ID for authenticated requests
    return req.user?.id ? `${req.ip}-${req.user.id}` : req.ip;
  },
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many requests',
      message: 'Rate limit exceeded. Please wait before making more requests.',
      retryAfter: Math.round(req.rateLimit.resetTime / 1000),
    });
  },
});

// Strict rate limiter for sensitive endpoints
const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  message: {
    error: 'Too many requests to sensitive endpoint',
    statusCode: 429,
  },
  skipSuccessfulRequests: true,
});

// Authentication rate limiter
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 auth attempts per windowMs
  message: {
    error: 'Too many authentication attempts',
    statusCode: 429,
  },
  skipSuccessfulRequests: true,
});

// Speed limiter for gradual slowdown
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // Allow 50 requests per 15 minutes at full speed
  delayMs: 500, // Add 500ms delay per request after delayAfter
  maxDelayMs: 20000, // Maximum delay of 20 seconds
});

/**
 * Main rate limiting middleware
 */
module.exports = (config, { strapi }) => {
  return async (ctx, next) => {
    const { path, method } = ctx.request;
    
    // Skip rate limiting for certain paths
    const skipPaths = [
      '/health',
      '/favicon.ico',
      '/documentation',
      '/_health'
    ];
    
    if (skipPaths.some(skipPath => path.startsWith(skipPath))) {
      return next();
    }
    
    // Apply different rate limits based on path
    let limiterToUse = apiLimiter;
    
    // Strict limiting for sensitive endpoints
    if (path.includes('/auth/') || 
        path.includes('/users-permissions/') ||
        path.includes('/webhook/')) {
      limiterToUse = strictLimiter;
    }
    
    // Special handling for auth endpoints
    if (path.includes('/auth/local') || 
        path.includes('/auth/register')) {
      limiterToUse = authLimiter;
    }
    
    // Convert Koa context to Express-like request/response for rate limiter
    const req = {
      ip: ctx.ip,
      method: ctx.method,
      url: ctx.url,
      path: ctx.path,
      user: ctx.state.user,
      headers: ctx.headers,
      get: (header) => ctx.get(header),
    };
    
    const res = {
      status: (code) => {
        ctx.status = code;
        return res;
      },
      json: (data) => {
        ctx.body = data;
        return res;
      },
      set: (header, value) => {
        ctx.set(header, value);
        return res;
      },
      header: (header, value) => {
        ctx.set(header, value);
        return res;
      },
    };
    
    // Apply rate limiting
    return new Promise((resolve, reject) => {
      limiterToUse(req, res, (err) => {
        if (err) {
          reject(err);
        } else if (ctx.status === 429) {
          // Rate limit was triggered
          resolve();
        } else {
          // Apply speed limiting for additional protection
          speedLimiter(req, res, (speedErr) => {
            if (speedErr) {
              reject(speedErr);
            } else {
              resolve(next());
            }
          });
        }
      });
    });
  };
};