/**
 * Application bootstrap
 * This function runs when Strapi starts
 */

module.exports = async ({ strapi }) => {
  // Log startup information
  strapi.log.info('🚀 AI API Starter Kit is starting...');
  
  // Verify Treblle configuration
  if (!process.env.TREBLLE_API_KEY || !process.env.TREBLLE_PROJECT_ID) {
    strapi.log.warn('⚠️ Treblle not configured. Set TREBLLE_API_KEY and TREBLLE_PROJECT_ID');
  } else {
    strapi.log.info('✅ Treblle configuration found');
  }

  // Check AI service configuration
  if (process.env.OLLAMA_BASE_URL) {
    strapi.log.info('🤖 Using Ollama for AI analysis');
  } else if (process.env.OPENAI_API_KEY) {
    strapi.log.info('🤖 Using OpenAI for AI analysis');
  } else {
    strapi.log.warn('⚠️ No AI service configured. Set OLLAMA_BASE_URL or OPENAI_API_KEY');
  }

  strapi.log.info('🎉 AI API Starter Kit ready!');
  strapi.log.info(`📍 Admin Panel: http://localhost:${process.env.PORT || 1337}/admin`);
  strapi.log.info(`📍 API Docs: http://localhost:${process.env.PORT || 1337}/documentation`);
};