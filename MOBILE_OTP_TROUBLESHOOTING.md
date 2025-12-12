# Mobile OTP Troubleshooting Guide (Vivo V50)

If OTP emails are not working on your mobile phone, follow these steps:

## Step 1: Check Firebase Functions Deployment

First, verify that the Firebase Functions are deployed:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions:sendOTP
```

## Step 2: Check Function Logs

After attempting to send an OTP, check the Firebase Functions logs:

```bash
firebase functions:log --only sendOTP
```

Look for:
- ✅ Success messages
- ❌ Error messages
- EmailJS or Gmail delivery status

## Step 3: Verify Environment Variables

Make sure EmailJS credentials are set in Firebase Functions:

**Option A: Using Firebase CLI:**
```bash
firebase functions:config:set emailjs.service_id="service_yp8e8yv"
firebase functions:config:set emailjs.template_id="template_cp368bp"
firebase functions:config:set emailjs.public_key="ORSGxHfkgWz4A7WVd"
```

**Option B: Using .env file (for local testing):**
Create `functions/.env`:
```
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
```

Then redeploy:
```bash
firebase deploy --only functions:sendOTP
```

## Step 4: Check Network Connectivity

On your Vivo V50:
1. Make sure you have internet connection (Wi-Fi or mobile data)
2. Try switching between Wi-Fi and mobile data
3. Check if Firebase is accessible (try opening Firebase Console in browser)

## Step 5: Enable Debug Logging

The app now has detailed logging. When you try to sign up:
1. Check your Flutter console/logcat for messages like:
   - `📧 Attempting to send OTP via Firebase Functions...`
   - `📡 Calling Firebase Function sendOTP...`
   - `✅ Firebase Function OTP sent successfully`
   - `❌ Firebase Functions error: ...`

## Step 6: Verify Firebase Project Configuration

Check that your mobile app is connected to the correct Firebase project:
- Project ID should be: `customer-c538e`
- Check `lib/firebase_options.dart` has correct Android configuration

## Step 7: Test the Function Directly

You can test the Firebase Function directly using curl:

```bash
curl -X POST https://us-central1-customer-c538e.cloudfunctions.net/sendOTP \
  -H "Content-Type: application/json" \
  -d '{"data":{"email":"test@example.com","code":"123456","purpose":"signup_verification"}}'
```

## Step 8: Common Issues and Solutions

### Issue: "Function not found" or "Permission denied"
**Solution:** Make sure the function is deployed:
```bash
firebase deploy --only functions:sendOTP
```

### Issue: "Network error" or "Timeout"
**Solution:**
1. Check your internet connection
2. Make sure Firebase Functions are accessible from your region
3. Try using a VPN if Firebase is blocked in your region

### Issue: "EmailJS error" in logs
**Solution:**
1. Verify EmailJS credentials are correct
2. Check EmailJS dashboard for quota/limits
3. Verify EmailJS service is active

### Issue: No error but email not received
**Solution:**
1. Check spam/junk folder
2. Verify email address is correct
3. Check EmailJS dashboard for delivery status
4. Try a different email address

## Step 9: Fallback to Gmail

If EmailJS continues to fail, you can configure Gmail as fallback:

```bash
firebase functions:config:set gmail.email="your@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

The function will automatically use Gmail if EmailJS fails.

## Step 10: Check Android Permissions

Make sure your app has internet permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Still Not Working?

1. Check the full error message in Flutter console/logcat
2. Check Firebase Functions logs: `firebase functions:log`
3. Verify EmailJS account is active and has quota
4. Try testing with a different email service

## Quick Test Command

Run this to verify everything is set up:
```bash
cd functions
npm install axios
cd ..
firebase deploy --only functions:sendOTP
flutter run
```



