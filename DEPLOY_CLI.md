# CLI Deployment Guide for Firebase Functions + EmailJS

Follow these commands step-by-step using your CLI (PowerShell/Command Prompt):

## Step 1: Navigate to Project Directory

```powershell
cd C:\Desktop\login.github.io
```

## Step 2: Set Firebase Project

```powershell
firebase use customer-c538e
```

Verify it's set:
```powershell
firebase use
```

You should see: `Now using project customer-c538e`

## Step 3: Install Dependencies

```powershell
cd functions
npm install
cd ..
```

## Step 4: Configure EmailJS (Option A: Using .env file - Recommended)

Create a file `functions\.env` with this content:

```env
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
```

**Using PowerShell:**
```powershell
@"
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
"@ | Out-File -FilePath "functions\.env" -Encoding utf8
```

## Step 5: Deploy Firebase Functions

```powershell
firebase deploy --only functions:sendOTP
```

Wait for deployment to complete. You should see:
```
✔  functions[sendOTP(us-central1)] Successful create operation.
```

## Step 6: Verify Deployment

Check that the function is deployed:
```powershell
firebase functions:list
```

You should see `sendOTP` in the list.

## Step 7: Test on Your Vivo V50

1. Run your Flutter app:
   ```powershell
   flutter run
   ```

2. Create a new account
3. Check the console for logs like:
   - `📧 Attempting to send OTP via Firebase Functions...`
   - `✅ Firebase Function OTP sent successfully`

4. Check your email inbox (and spam folder)

## Quick Script Method

You can also use the provided PowerShell script:

```powershell
.\deploy-functions.ps1
```

This script will:
- Install dependencies
- Create .env file
- Deploy the function
- Show you the results

## View Logs

To see what's happening in real-time:

```powershell
firebase functions:log --only sendOTP
```

Or view logs in the Firebase Console:
https://console.firebase.google.com/project/customer-c538e/functions/logs

## Troubleshooting

### If deployment fails:

1. **Check Firebase CLI is logged in:**
   ```powershell
   firebase login
   ```

2. **Check you have the right project:**
   ```powershell
   firebase use
   ```

3. **Check function code for errors:**
   ```powershell
   cd functions
   node -c index.js
   cd ..
   ```

### If function deploys but emails don't send:

1. **Check function logs:**
   ```powershell
   firebase functions:log --only sendOTP
   ```

2. **Verify EmailJS credentials** in `functions\.env` file

3. **Test function directly** (optional):
   ```powershell
   curl -X POST https://us-central1-customer-c538e.cloudfunctions.net/sendOTP -H "Content-Type: application/json" -d "{\"data\":{\"email\":\"test@example.com\",\"code\":\"123456\",\"purpose\":\"signup_verification\"}}"
   ```

## Alternative: Configure via Firebase Console

If you prefer using the web interface:

1. Go to: https://console.firebase.google.com/project/customer-c538e/functions/config
2. Add Runtime environment variables:
   - `EMAILJS_SERVICE_ID` = `service_yp8e8yv`
   - `EMAILJS_TEMPLATE_ID` = `template_cp368bp`
   - `EMAILJS_PUBLIC_KEY` = `ORSGxHfkgWz4A7WVd`

Then redeploy:
```powershell
firebase deploy --only functions:sendOTP
```


