# Setup script for Firebase Functions environment variables
Write-Host "=== Firebase Functions Environment Setup ===" -ForegroundColor Green
Write-Host ""

# Check if .env already exists
if (Test-Path ".env") {
    Write-Host ".env file already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Setup cancelled." -ForegroundColor Red
        exit
    }
}

Write-Host "This script will create a .env file with your Gmail credentials." -ForegroundColor Cyan
Write-Host ""
Write-Host "To get a Gmail App Password:" -ForegroundColor Yellow
Write-Host "1. Go to: https://myaccount.google.com/apppasswords"
Write-Host "2. Sign in with your Gmail account"
Write-Host "3. Create an app password for 'Mail'"
Write-Host "4. Copy the 16-character password (ignore spaces)"
Write-Host ""

$email = Read-Host "Enter your Gmail address (e.g., jweek967@gmail.com)"
$password = Read-Host "Enter your Gmail App Password (16 characters, no spaces)" -AsSecureString
$passwordPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Create .env file
$envContent = @"
# Gmail credentials for sending OTP emails
GMAIL_EMAIL=$email
GMAIL_APP_PASSWORD=$passwordPlainText
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "✓ .env file created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: npm install"
Write-Host "2. Deploy: firebase deploy --only functions"
Write-Host ""





