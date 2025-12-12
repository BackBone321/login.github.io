# PowerShell Script to Deploy Firebase Functions
# Run: .\RUN_THIS.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Firebase Functions for OTP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set Firebase project
Write-Host "Step 1: Setting Firebase project..." -ForegroundColor Yellow
firebase use customer-c538e
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to set Firebase project" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Deploying sendOTP function..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray
Write-Host ""

# Deploy function
firebase deploy --only functions:sendOTP

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter run" -ForegroundColor White
    Write-Host "2. Create a new account on your Vivo V50" -ForegroundColor White
    Write-Host "3. Check your email inbox" -ForegroundColor White
    Write-Host ""
    Write-Host "To view logs: firebase functions:log --only sendOTP" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"


