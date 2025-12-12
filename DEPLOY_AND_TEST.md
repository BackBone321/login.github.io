# Quick Deploy and Test Guide for Mobile OTP

Follow these steps to get OTP emails working on your Vivo V50:

## Step 1: Install Dependencies

```bash
cd functions
npm install
cd ..
```

## Step 2: Configure EmailJS (Choose One Method)

### Method A: Using Environment Variables in Firebase Console

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: `customer-c538e`
3. Go to **Functions** → **Configuration** → **Runtime environment variables**
4. Add these variables:
   - `EMAILJS_SERVICE_ID` = `service_yp8e8yv`
   - `EMAILJS_TEMPLATE_ID` = `template_cp368bp`
   - `EMAILJS_PUBLIC_KEY` = `ORSGxHfkgWz4A7WVd`

### Method B: Using .env file (for local testing)

Create `functions/.env` file:
```env
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
```

## Step 3: Deploy Firebase Functions

```bash
firebase deploy --only functions:sendOTP
```

Wait for deployment to complete. You should see:
```
✔  functions[sendOTP(us-central1)] Successful create operation.
```

## Step 4: Test on Your Mobile Phone

1. Make sure your phone is connected to the same Firebase project
2. Run your Flutter app on your Vivo V50:
   ```bash
   flutter run
   ```
3. Try to create a new account
4. Check the console/logs for messages like:
   - `📧 Attempting to send OTP via Firebase Functions...`
   - `✅ Firebase Function OTP sent successfully`

## Step 5: Check Email

1. Check your email inbox
2. Also check spam/junk folder
3. The email should arrive within a few seconds

## If It Still Doesn't Work

### Check Function Logs:
```bash
firebase functions:log --only sendOTP
```

### Check Mobile Logs:
On your computer, run:
```bash
flutter logs
```

Or use Android Studio Logcat to see detailed error messages.

### Verify Function is Deployed:
```bash
firebase functions:list
```

You should see `sendOTP` in the list.

## Emergency Fallback: Use Gmail Directly

If EmailJS still doesn't work, configure Gmail fallback:

1. Get Gmail App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Generate app password for "Mail"
   
2. Set environment variables:
   ```bash
   firebase functions:config:set gmail.email="your@gmail.com" gmail.password="your-16-char-password"
   ```

3. Redeploy:
   ```bash
   firebase deploy --only functions:sendOTP
   ```

The function will automatically use Gmail if EmailJS fails.



