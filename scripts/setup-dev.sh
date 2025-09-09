#!/bin/bash

# ChapeChape Development Environment Setup
# Usage: ./scripts/setup-dev.sh

set -e

echo "🔧 Setting up ChapeChape development environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p nginx/ssl
mkdir -p backup_all

# Copy environment files
echo "📄 Setting up environment files..."
if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env
    echo "✅ Backend .env created from example"
fi

if [ ! -f chapechape_dashboard/.env ]; then
    cp chapechape_dashboard/.env.example chapechape_dashboard/.env
    echo "✅ Dashboard .env created from example"
fi

if [ ! -f chapechape_sitepresentation/.env ]; then
    cp chapechape_sitepresentation/.env.example chapechape_sitepresentation/.env
    echo "✅ Site presentation .env created from example"
fi

# Build and start development environment
echo "🚀 Building development containers..."
docker-compose -f docker-compose.dev.yml build

echo "🔄 Starting development services..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Check service health
echo "🔍 Checking service health..."

# Check MongoDB
if docker-compose -f docker-compose.dev.yml exec mongo mongosh --eval "db.runCommand('ping')" > /dev/null 2>&1; then
    echo "✅ MongoDB is ready"
else
    echo "⚠️  MongoDB might still be starting..."
fi

# Check Redis
if docker-compose -f docker-compose.dev.yml exec redis redis-cli -a dev123 ping > /dev/null 2>&1; then
    echo "✅ Redis is ready"
else
    echo "⚠️  Redis might still be starting..."
fi

echo "🎉 Development environment setup completed!"
echo ""
echo "📋 Available services:"
echo "  - Backend API: http://localhost:5000"
echo "  - Dashboard: http://localhost:3001"
echo "  - Site Presentation: http://localhost:3002"
echo "  - MongoDB Express: http://localhost:8081"
echo "  - Redis Commander: http://localhost:8082"
echo ""
echo "🔧 Useful commands:"
echo "  - View logs: docker-compose -f docker-compose.dev.yml logs -f [service]"
echo "  - Stop services: docker-compose -f docker-compose.dev.yml down"
echo "  - Restart service: docker-compose -f docker-compose.dev.yml restart [service]"
echo ""
echo "📱 For Flutter apps:"
echo "  - Build client: ./scripts/build-flutter.sh client apk"
echo "  - Build partner: ./scripts/build-flutter.sh partner aab"
