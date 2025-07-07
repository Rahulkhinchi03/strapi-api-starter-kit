/**
 * is-authenticated policy
 * Ensures user is properly authenticated via JWT token
 */

module.exports = async (policyContext, config, { strapi }) => {
    const { ctx } = policyContext;
  
    // Check if user is already authenticated (from previous middleware)
    if (ctx.state.user) {
      return true;
    }
  
    // Check for JWT token in Authorization header
    const authHeader = ctx.request.header.authorization;
    
    if (!authHeader) {
      strapi.log.warn('Authentication failed: No authorization header', {
        path: ctx.path,
        ip: ctx.ip,
        userAgent: ctx.request.header['user-agent']
      });
      return false;
    }
  
    if (!authHeader.startsWith('Bearer ')) {
      strapi.log.warn('Authentication failed: Invalid authorization header format', {
        path: ctx.path,
        ip: ctx.ip
      });
      return false;
    }
  
    const token = authHeader.substring(7);
  
    try {
      // Verify JWT token
      const jwt = require('jsonwebtoken');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
  
      // Fetch user from database
      const user = await strapi.entityService.findOne('plugin::users-permissions.user', decoded.id, {
        populate: ['role']
      });
  
      if (!user) {
        strapi.log.warn('Authentication failed: User not found', {
          userId: decoded.id,
          path: ctx.path,
          ip: ctx.ip
        });
        return false;
      }
  
      // Check if user is blocked
      if (user.blocked) {
        strapi.log.warn('Authentication failed: User is blocked', {
          userId: user.id,
          email: user.email,
          path: ctx.path,
          ip: ctx.ip
        });
        return false;
      }
  
      // Add user to context
      ctx.state.user = user;
      
      strapi.log.info('User authenticated successfully', {
        userId: user.id,
        email: user.email,
        role: user.role?.name,
        path: ctx.path
      });
  
      return true;
  
    } catch (error) {
      strapi.log.warn('Authentication failed: Invalid or expired token', {
        error: error.message,
        path: ctx.path,
        ip: ctx.ip
      });
      return false;
    }
  };