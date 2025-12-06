# Fix for Email Verification on Android

## Problem
EmailJS doesn't work on mobile apps (Android/iOS) - it only works on web browsers. The API returns a 403 error: "API calls are disabled for non-browser applications."

## Solution
The code has been updated to automatically detect the platform:
- **Web**: Uses EmailJS
- **Mobile (Android/iOS)**: Uses Firebase Cloud Functions

## Setup Steps

### 1. Configure Gmail App Password

To send emails from Firebase Cloud Functions, you need to set up Gmail credentials:

1. Go to your Google Account: https://myaccount.google.com/security
2. Enable 2-Step Verification if not already enabled
3. Go to "App passwords": https://myaccount.google.com/apppasswords
4. Generate a new app password for "Mail" on "Other (Custom name)"
5. Copy the 16-character password

### 2. Configure Firebase Functions

Open a terminal and run these commands:

```bash
# Navigate to your project
cd C:\Desktop\login

# Set your Gmail credentials
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-16-char-app-password"

# Example:
# firebase functions:config:set gmail.email="jweek967@gmail.com" gmail.password="abcd efgh ijkl mnop"
```

### 3. Deploy Firebase Cloud Functions

```bash
cd C:\Desktop\login\functions
npm install
cd ..
firebase deploy --only functions
```

### 4. Test on Android

After deployment completes:
1. Stop your current Flutter app
2. Run the app again: `flutter run`
3. Try to sign up with a new email
4. You should receive the OTP email via Firebase Cloud Functions

## What Changed

### Updated File: `lib/services/otp_service.dart`

- Added platform detection using `kIsWeb`
- Mobile apps now use Firebase Cloud Functions
- Web apps continue to use EmailJS
- Better error logging with platform information

## Troubleshooting

### If emails still don't send on mobile:

1. **Check Firebase Functions deployment:**
   ```bash
   firebase functions:list
   ```
   You should see `sendOTP` in the list.

2. **Check Firebase Functions logs:**
   ```bash
   firebase functions:log
   ```
   Look for any errors related to sendOTP.

3. **Verify Gmail credentials are set:**
   ```bash
   firebase functions:config:get
   ```
   Should show your gmail.email and gmail.password.

4. **Check if Gmail is blocking the app:**
   - Make sure you're using an App Password, not your regular Gmail password
   - Check your Gmail "Less secure app access" settings

### If you see "Email service is not configured" error:

This means the Gmail credentials weren't set properly. Re-run step 2 above.

## Testing Checklist

- [ ] Firebase Cloud Functions deployed
- [ ] Gmail credentials configured
- [ ] Test signup on Android - should receive OTP email
- [ ] Test signup on web - should still work with EmailJS
- [ ] Test resend OTP on Android
- [ ] Check Firebase Functions logs for any errors





