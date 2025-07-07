/**
 * is-owner-or-admin policy
 * Ensures user can only access their own resources or is an admin
 */

module.exports = async (policyContext, config, { strapi }) => {
    const { ctx } = policyContext;
    const user = ctx.state.user;
  
    if (!user) {
      strapi.log.warn('Access denied: User not authenticated', {
        path: ctx.path,
        ip: ctx.ip
      });
      return false;
    }
  
    // Admin users can access everything
    if (user.role?.type === 'admin' || user.role?.name === 'Admin') {
      strapi.log.info('Access granted: Admin user', {
        userId: user.id,
        role: user.role?.name,
        path: ctx.path
      });
      return true;
    }
  
    // For resource-specific access, check if user owns the resource
    const resourceId = ctx.params.id;
    
    if (!resourceId) {
      // If no specific resource ID, allow access (will be filtered by user in controller)
      return true;
    }
  
    try {
      // Determine the content type from the path
      let contentType = 'api::api-analysis.api-analysis';
      
      // Map paths to content types
      if (ctx.path.includes('/api-analysis')) {
        contentType = 'api::api-analysis.api-analysis';
      }
      // Add more content types as needed
  
      // Fetch the resource to check ownership
      const resource = await strapi.entityService.findOne(contentType, resourceId, {
        populate: ['user']
      });
  
      if (!resource) {
        strapi.log.warn('Access denied: Resource not found', {
          resourceId,
          contentType,
          userId: user.id,
          path: ctx.path
        });
        return false;
      }
  
      // Check if user owns the resource
      const isOwner = resource.user?.id === user.id;
      
      if (isOwner) {
        strapi.log.info('Access granted: Resource owner', {
          resourceId,
          userId: user.id,
          path: ctx.path
        });
        return true;
      }
  
      strapi.log.warn('Access denied: User does not own resource', {
        resourceId,
        resourceOwnerId: resource.user?.id,
        userId: user.id,
        path: ctx.path
      });
  
      return false;
  
    } catch (error) {
      strapi.log.error('Error checking resource ownership:', {
        error: error.message,
        resourceId,
        userId: user.id,
        path: ctx.path
      });
      return false;
    }
  };