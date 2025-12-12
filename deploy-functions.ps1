# PowerShell Script to Deploy Firebase Functions with EmailJS
# Run this script: .\deploy-functions.ps1

Write-Host "🚀 Deploying Firebase Functions with EmailJS Configuration" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "functions")) {
    Write-Host "❌ Error: 'functions' directory not found. Please run this script from the project root." -ForegroundColor Red
    exit 1
}

# Navigate to functions directory
Set-Location functions

# Install dependencies
Write-Host "📦 Installing npm dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm install failed!" -ForegroundColor Red
    exit 1
}

# Go back to project root
Set-Location ..

# Set EmailJS environment variables (using new Firebase CLI method)
Write-Host ""
Write-Host "⚙️  Setting EmailJS environment variables..." -ForegroundColor Yellow

# Note: Firebase Functions v2 uses secrets instead of config
# But for now, we'll use .env file which dotenv will load
Write-Host "Creating .env file in functions directory..." -ForegroundColor Yellow

$envContent = @"
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
"@

$envPath = "functions\.env"
$envContent | Out-File -FilePath $envPath -Encoding utf8
Write-Host "✅ Created functions\.env file" -ForegroundColor Green

# Verify Firebase project
Write-Host ""
Write-Host "🔍 Current Firebase project:" -ForegroundColor Yellow
firebase use

Write-Host ""
Write-Host "🚀 Deploying Firebase Functions..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

# Deploy only the sendOTP function
firebase deploy --only functions:sendOTP

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📧 Test the OTP function:" -ForegroundColor Cyan
    Write-Host "   1. Run your Flutter app on your Vivo V50" -ForegroundColor White
    Write-Host "   2. Try creating a new account" -ForegroundColor White
    Write-Host "   3. Check your email inbox" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 View logs:" -ForegroundColor Cyan
    Write-Host "   firebase functions:log --only sendOTP" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed. Check the error messages above." -ForegroundColor Red
    exit 1
}


