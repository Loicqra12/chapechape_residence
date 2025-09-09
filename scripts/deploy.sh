#!/bin/bash

# ChapeChape Deployment Script
# Usage: ./scripts/deploy.sh [environment] [service]
# Example: ./scripts/deploy.sh production all

set -e

ENVIRONMENT=${1:-development}
SERVICE=${2:-all}
DOCKER_COMPOSE_FILE="docker-compose.yml"

if [ "$ENVIRONMENT" = "development" ]; then
    DOCKER_COMPOSE_FILE="docker-compose.dev.yml"
fi

echo "🚀 Deploying ChapeChape - Environment: $ENVIRONMENT, Service: $SERVICE"

# Function to deploy specific service
deploy_service() {
    local service_name=$1
    echo "📦 Building and deploying $service_name..."
    
    if [ "$ENVIRONMENT" = "production" ]; then
        docker-compose -f $DOCKER_COMPOSE_FILE build $service_name
        docker-compose -f $DOCKER_COMPOSE_FILE up -d $service_name
    else
        docker-compose -f $DOCKER_COMPOSE_FILE build $service_name
        docker-compose -f $DOCKER_COMPOSE_FILE up -d $service_name
    fi
    
    echo "✅ $service_name deployed successfully"
}

# Function to deploy all services
deploy_all() {
    echo "📦 Building all services..."
    docker-compose -f $DOCKER_COMPOSE_FILE build
    
    echo "🔄 Starting all services..."
    docker-compose -f $DOCKER_COMPOSE_FILE up -d
    
    echo "✅ All services deployed successfully"
}

# Function to run health checks
health_check() {
    echo "🔍 Running health checks..."
    
    # Wait for services to start
    sleep 10
    
    # Check backend health
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "✅ Backend is healthy"
    else
        echo "❌ Backend health check failed"
        exit 1
    fi
    
    # Check dashboard
    if curl -f http://localhost:3001 > /dev/null 2>&1; then
        echo "✅ Dashboard is healthy"
    else
        echo "❌ Dashboard health check failed"
        exit 1
    fi
    
    echo "✅ All health checks passed"
}

# Main deployment logic
case $SERVICE in
    "backend")
        deploy_service "backend"
        ;;
    "dashboard")
        deploy_service "dashboard"
        ;;
    "sitepresentation")
        deploy_service "sitepresentation"
        ;;
    "all")
        deploy_all
        ;;
    *)
        echo "❌ Unknown service: $SERVICE"
        echo "Available services: backend, dashboard, sitepresentation, all"
        exit 1
        ;;
esac

# Run health checks for production
if [ "$ENVIRONMENT" = "production" ]; then
    health_check
fi

echo "🎉 Deployment completed successfully!"

# Show running containers
echo "📋 Running containers:"
docker-compose -f $DOCKER_COMPOSE_FILE ps
