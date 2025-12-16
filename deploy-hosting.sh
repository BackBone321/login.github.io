#!/bin/bash

# AgriGuard Deployment Script for Firebase Hosting
# Domain: agriguard.com

echo "🚀 Starting AgriGuard deployment to Firebase Hosting..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Installing..."
    npm install -g firebase-tools
fi

# Check if logged in to Firebase
echo "📋 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase..."
    firebase login
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️  Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo "❌ Build failed! build/web directory not found."
    exit 1
fi

# Deploy to Firebase Hosting
echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "✅ Deployment complete!"
echo "🌐 Your app should be live at: https://agriguard.com"
echo ""
echo "📝 To set up custom domain (agriguard.com):"
echo "   1. Go to Firebase Console: https://console.firebase.google.com"
echo "   2. Select your project"
echo "   3. Go to Hosting > Add custom domain"
echo "   4. Enter: agriguard.com"
echo "   5. Follow the DNS configuration instructions"



