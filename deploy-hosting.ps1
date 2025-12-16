# AgriGuard Deployment Script for Firebase Hosting (PowerShell)
# Domain: agriguard.com

Write-Host "🚀 Starting AgriGuard deployment to Firebase Hosting..." -ForegroundColor Green

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "✅ Flutter found" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Host "✅ Firebase CLI found" -ForegroundColor Green
} catch {
    Write-Host "📦 Installing Firebase CLI..." -ForegroundColor Yellow
    npm install -g firebase-tools
}

# Check if logged in to Firebase
Write-Host "📋 Checking Firebase authentication..." -ForegroundColor Cyan
try {
    firebase projects:list | Out-Null
    Write-Host "✅ Firebase authenticated" -ForegroundColor Green
} catch {
    Write-Host "🔐 Please login to Firebase..." -ForegroundColor Yellow
    firebase login
}

# Clean previous build
Write-Host "🧹 Cleaning previous build..." -ForegroundColor Cyan
flutter clean

# Get dependencies
Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

# Build for web
Write-Host "🏗️  Building Flutter web app..." -ForegroundColor Cyan
flutter build web --release

# Check if build was successful
if (-Not (Test-Path "build/web")) {
    Write-Host "❌ Build failed! build/web directory not found." -ForegroundColor Red
    exit 1
}

# Deploy to Firebase Hosting
Write-Host "🚀 Deploying to Firebase Hosting..." -ForegroundColor Cyan
firebase deploy --only hosting

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app should be live at: https://agriguard.com" -ForegroundColor Green
Write-Host ""
Write-Host "📝 To set up custom domain (agriguard.com):" -ForegroundColor Yellow
Write-Host "   1. Go to Firebase Console: https://console.firebase.google.com"
Write-Host "   2. Select your project"
Write-Host "   3. Go to Hosting > Add custom domain"
Write-Host "   4. Enter: agriguard.com"
Write-Host "   5. Follow the DNS configuration instructions"



