@echo off
echo ========================================
echo Deploying Firebase Functions for OTP
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Setting Firebase project...
call firebase use customer-c538e
if errorlevel 1 (
    echo ERROR: Failed to set Firebase project
    pause
    exit /b 1
)

echo.
echo Step 2: Deploying sendOTP function...
echo This may take 2-3 minutes...
echo.

call firebase deploy --only functions:sendOTP

if errorlevel 1 (
    echo.
    echo ERROR: Deployment failed!
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo Deployment Successful!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Run: flutter run
    echo 2. Create a new account on your Vivo V50
    echo 3. Check your email inbox
    echo.
    echo To view logs: firebase functions:log --only sendOTP
    echo.
)

pause

