#!/bin/bash

# Flutter Build Script for ChapeChape Apps
# Usage: ./scripts/build-flutter.sh [app] [build_type]
# Example: ./scripts/build-flutter.sh client apk

set -e

APP=${1:-all}
BUILD_TYPE=${2:-apk}

echo "🔨 Building Flutter apps - App: $APP, Type: $BUILD_TYPE"

# Function to build specific Flutter app
build_flutter_app() {
    local app_name=$1
    local app_path="chapechape_$app_name"
    
    if [ ! -d "$app_path" ]; then
        echo "❌ App directory $app_path not found"
        exit 1
    fi
    
    echo "📱 Building $app_name..."
    cd "$app_path"
    
    # Clean previous builds
    flutter clean
    flutter pub get
    
    # Run tests
    echo "🧪 Running tests for $app_name..."
    flutter test
    
    # Build based on type
    case $BUILD_TYPE in
        "apk")
            echo "📦 Building APK for $app_name..."
            flutter build apk --release
            ;;
        "aab")
            echo "📦 Building AAB for $app_name..."
            flutter build appbundle --release
            ;;
        "both")
            echo "📦 Building both APK and AAB for $app_name..."
            flutter build apk --release
            flutter build appbundle --release
            ;;
        *)
            echo "❌ Unknown build type: $BUILD_TYPE"
            echo "Available types: apk, aab, both"
            exit 1
            ;;
    esac
    
    echo "✅ $app_name built successfully"
    cd ..
}

# Function to build all Flutter apps
build_all_apps() {
    build_flutter_app "client"
    build_flutter_app "partner"
}

# Main build logic
case $APP in
    "client")
        build_flutter_app "client"
        ;;
    "partner")
        build_flutter_app "partner"
        ;;
    "all")
        build_all_apps
        ;;
    *)
        echo "❌ Unknown app: $APP"
        echo "Available apps: client, partner, all"
        exit 1
        ;;
esac

echo "🎉 Flutter build completed successfully!"

# Show build artifacts
echo "📋 Build artifacts:"
find . -name "*.apk" -o -name "*.aab" | grep -E "(client|partner)" | head -10
