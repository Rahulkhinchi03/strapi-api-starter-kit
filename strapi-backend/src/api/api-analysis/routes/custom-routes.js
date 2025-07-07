module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/api-analysis/test',
      handler: 'api-analysis.test',
      config: {
        auth: false,
        description: 'Test endpoint for API analysis service',
        tags: ['API Analysis'],
      }
    },
    {
      method: 'POST',
      path: '/api-analysis/analyze',
      handler: 'api-analysis.analyze',
      config: {
        description: 'Analyze API endpoint or OpenAPI spec',
        tags: ['API Analysis'],
      }
    }
  ]
};
