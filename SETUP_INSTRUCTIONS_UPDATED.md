# Fix for Email Verification on Android - UPDATED

## Problem
EmailJS doesn't work on mobile apps (Android/iOS) - it only works on web browsers. The API returns a 403 error: "API calls are disabled for non-browser applications."

## Solution
The code has been updated to automatically detect the platform:
- **Web**: Uses EmailJS
- **Mobile (Android/iOS)**: Uses Firebase Cloud Functions

The Firebase Cloud Functions have been updated to use modern `.env` files instead of the deprecated `functions.config()` API.

## Quick Setup (3 Steps)

### Step 1: Get Gmail App Password

1. Go to: https://myaccount.google.com/apppasswords
2. Sign in with your Gmail account (jweek967@gmail.com)
3. Create an app password for "Mail"
4. Copy the 16-character password (remove spaces)

### Step 2: Configure Environment Variables

**Option A - Automated (Recommended):**
```powershell
cd C:\Desktop\login\functions
.\setup-env.ps1
```
Then follow the prompts to enter your Gmail and App Password.

**Option B - Manual:**
Create a file `C:\Desktop\login\functions\.env` with this content:
```
GMAIL_EMAIL=jweek967@gmail.com
GMAIL_APP_PASSWORD=your-16-char-app-password-here
```

### Step 3: Deploy Firebase Cloud Functions

```powershell
cd C:\Desktop\login\functions
npm install
cd ..
firebase deploy --only functions
```

### Step 4: Test on Android

After deployment completes:
1. Stop your current Flutter app
2. Run: `flutter run`
3. Try to sign up with a new email
4. You should receive the OTP email! ✅

## What Was Updated

### 1. `lib/services/otp_service.dart`
- Added platform detection using `kIsWeb`
- Mobile apps now use Firebase Cloud Functions
- Web apps continue to use EmailJS

### 2. `functions/index.js`
- Migrated from deprecated `functions.config()` to `.env` variables
- Uses `dotenv` package for environment variables
- More secure and future-proof

### 3. `functions/package.json`
- Added `dotenv` dependency

## Troubleshooting

### Error: "Email service is not configured"

**Solution:** Make sure your `.env` file exists in the `functions` folder with correct credentials.

Check your .env file:
```powershell
cd C:\Desktop\login\functions
cat .env
```

### Error: "Invalid login" when deploying

**Solution:** Make sure you're using a Gmail **App Password**, not your regular Gmail password.
- Regular password: ❌ Won't work
- App password (16 chars): ✅ Required

### Check if functions are deployed:

```powershell
firebase functions:list
```

You should see `sendOTP` and `sendInvitation` in the list.

### Check function logs:

```powershell
firebase functions:log
```

Look for any errors related to sendOTP.

### Still not working?

1. Make sure you're connected to the correct Firebase project:
   ```powershell
   firebase use
   ```

2. Try redeploying:
   ```powershell
   firebase deploy --only functions --force
   ```

3. Check the Flutter app logs when signing up

## Testing Checklist

- [ ] Created `.env` file with Gmail credentials
- [ ] Installed dependencies: `npm install`
- [ ] Deployed Firebase Cloud Functions
- [ ] Test signup on Android - should receive OTP email
- [ ] Test signup on web - should still work with EmailJS
- [ ] Test resend OTP on Android
- [ ] No errors in Firebase Functions logs

## Security Note

⚠️ **IMPORTANT:** Never commit your `.env` file to Git! 

The `.gitignore` file has been updated to exclude `.env` files automatically.






