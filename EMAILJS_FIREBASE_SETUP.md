# EmailJS + Firebase Functions Setup Guide

This guide explains how to set up EmailJS with Firebase Cloud Functions to send OTP emails on both web and mobile platforms.

## Overview

The OTP service now uses Firebase Cloud Functions as the backend, which in turn uses EmailJS to send emails. This approach allows EmailJS to work on mobile devices through the Firebase backend.

## Prerequisites

1. Firebase project with Cloud Functions enabled
2. EmailJS account (free tier available at https://www.emailjs.com/)
3. Node.js installed (for deploying functions)

## Step 1: Configure EmailJS

1. Sign up/login at https://www.emailjs.com/
2. Create an Email Service (e.g., Gmail)
3. Create an Email Template with the following variables:
   - `{{to_email}}` - Recipient email
   - `{{otp}}` - OTP code
   - `{{purpose}}` - Purpose text
   - `{{expiry_time}}` - Expiry time

4. Get your EmailJS credentials:
   - Service ID: e.g., `service_yp8e8yv`
   - Template ID: e.g., `template_cp368bp`
   - Public Key: e.g., `ORSGxHfkgWz4A7WVd`

## Step 2: Configure Firebase Functions

### Option A: Using Environment Variables (Recommended)

1. Go to Firebase Console → Functions → Configuration
2. Add the following environment variables:
   ```
   EMAILJS_SERVICE_ID=service_yp8e8yv
   EMAILJS_TEMPLATE_ID=template_cp368bp
   EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
   ```

Or set them using Firebase CLI:
```bash
firebase functions:config:set emailjs.service_id="service_yp8e8yv"
firebase functions:config:set emailjs.template_id="template_cp368bp"
firebase functions:config:set emailjs.public_key="ORSGxHfkgWz4A7WVd"
```

### Option B: Using .env file (Local Development)

Create a `.env` file in the `functions/` directory:
```
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
```

## Step 3: Install Dependencies

In the `functions/` directory, install axios:
```bash
cd functions
npm install axios
```

## Step 4: Deploy Firebase Functions

```bash
firebase deploy --only functions:sendOTP
```

## Step 5: Test the Setup

1. Create a new account in your app
2. Check that the OTP email is received
3. Verify it works on both web and mobile

## Fallback to Gmail (Optional)

If EmailJS fails, the function will automatically fallback to Gmail (if configured):

```bash
firebase functions:config:set gmail.email="your@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

## Troubleshooting

### OTP emails not sending

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```

2. Verify EmailJS credentials are correct in Firebase Functions config

3. Check EmailJS dashboard for delivery status

4. Ensure your EmailJS service is active and not rate-limited

### Mobile app not receiving emails

1. Ensure Firebase Functions are deployed and accessible
2. Check that `cloud_functions` package is in `pubspec.yaml`
3. Verify Firebase project configuration in your mobile app

## How It Works

1. User creates account → `OTPService.sendSignupOtp()` is called
2. OTP is generated and stored in Firestore
3. `_sendOtpViaFirebaseFunctions()` calls Firebase Cloud Function `sendOTP`
4. Firebase Function uses EmailJS API to send the email
5. Email is delivered via EmailJS service (Gmail, etc.)

This architecture allows EmailJS to work on mobile because the API call is made from the Firebase backend (server-side), not from the mobile device.



