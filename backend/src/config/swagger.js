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
        './src/swagger/routes/auth.routes.js',
        './src/swagger/routes/messages.routes.js',
        './src/swagger/routes/payment.routes.js',
        './src/swagger/routes/reservation.routes.js',
        './src/swagger/routes/residence.routes.js',
        './src/swagger/routes/partner.routes.js',
        './src/swagger/routes/admin.routes.js',
        './src/swagger/routes/availability.routes.js',
        './src/swagger/routes/cancellation-policy.routes.js',
        './src/swagger/routes/device.routes.js',
        './src/swagger/routes/favorite.routes.js',
        './src/swagger/routes/maps.routes.js',
        './src/swagger/routes/notification.routes.js',
        './src/swagger/routes/partner-dashboard.routes.js',
        './src/swagger/routes/role.routes.js',
        './src/swagger/routes/sms.routes.js',
        './src/swagger/routes/user.routes.js',
        './src/swagger/routes/payout.routes.js',
        './src/swagger/routes/blog.routes.js',
        './src/swagger/routes/country-management.routes.js',
        './src/swagger/routes/partner-verification.routes.js',
        './src/swagger/routes/pricing.routes.js',
        './src/swagger/routes/superadmin.routes.js',
        './src/swagger/routes/support.routes.js',
        './src/swagger/routes/maintenance.routes.js'
    ]
};

const specs = swaggerJsdoc(options);

module.exports = specs;
