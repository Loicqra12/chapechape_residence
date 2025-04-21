const swaggerJsdoc = require('swagger-jsdoc');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'ChapeChape Residences API',
            version: '1.0.0',
            description: 'API documentation for ChapeChape Residences',
            contact: {
                name: 'ChapeChape Support',
                email: 'support@chapechape.com'
            }
        },
        servers: [
            {
                url: 'http://localhost:4000',
                description: 'Development server'
            },
            {
                url: 'https://api.chapechape.com',
                description: 'Production server'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                },
                csrfToken: {
                    type: 'apiKey',
                    in: 'header',
                    name: 'X-CSRF-Token'
                }
            }
        },
        security: [{
            bearerAuth: []
        }]
    },
    apis: [
        './src/routes/*.js',
        './src/models/*.js',
        './src/swagger/schemas.js',
        './src/swagger/schemas/*.js',
        './src/swagger/routes/*.js'
    ]
};

const specs = swaggerJsdoc(options);

module.exports = specs;
