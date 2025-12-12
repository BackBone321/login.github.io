# Quick Gmail Setup for OTP Emails

## Step 1: Get Gmail App Password

1. **Go to Google App Passwords:**
   https://myaccount.google.com/apppasswords

2. **If 2-Step Verification is not enabled:**
   - Enable it first at: https://myaccount.google.com/security

3. **Create App Password:**
   - Select "Mail" 
   - Select "Other (Custom name)"
   - Enter: `Firebase Functions`
   - Click "Generate"
   - **Copy the 16-character password** (like: `abcd efgh ijkl mnop`)

## Step 2: Set Gmail Credentials

Run this command (replace `YOUR_APP_PASSWORD` with the password you just copied):

```powershell
firebase functions:config:set gmail.email="jweek967@gmail.com" gmail.password="YOUR_APP_PASSWORD"
```

**Important:** Remove spaces from the app password if it has any!

## Step 3: Redeploy Function

```powershell
firebase deploy --only functions:sendOTP
```

## Step 4: Test

Run your Flutter app and try creating a new account. You should receive the OTP email! 📧

---

**Note:** After setting config, the function will use Gmail as the primary email service (more reliable than EmailJS for server-side).


