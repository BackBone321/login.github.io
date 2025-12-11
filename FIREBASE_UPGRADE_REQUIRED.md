# Firebase Blaze Plan Required

## Issue
The orange warning you're seeing means the Firebase Function `sendOTP` is not deployed because your Firebase project needs to be upgraded to the **Blaze (pay-as-you-go) plan**.

## Why Blaze Plan?
Firebase Cloud Functions require the Blaze plan. The good news is:
- **You only pay for what you use**
- Firebase provides a generous free tier
- Email sending via functions is very cheap (usually under $1/month for personal use)

## Quick Fix - Upgrade to Blaze Plan

### Option 1: Upgrade via Console (Recommended)

1. **Visit the upgrade page:**
   ```
   https://console.firebase.google.com/project/customer-c538e/usage/details
   ```

2. **Click "Modify plan" or "Upgrade"**

3. **Select "Blaze Plan"** (pay-as-you-go)

4. **Add a payment method** (Google will only charge you for actual usage)

5. **Wait 1-2 minutes** for the upgrade to complete

6. **Then deploy the function:**
   ```powershell
   firebase deploy --only functions:sendOTP
   ```

### Option 2: Upgrade via CLI

```powershell
# This will open the upgrade page in your browser
firebase open
```

Then follow the upgrade prompts.

## After Upgrading

Once upgraded, run:

```powershell
firebase deploy --only functions:sendOTP
```

The function should deploy successfully, and OTP emails will work on your Vivo V50! ✅

## Free Tier Limits

Don't worry about costs - Firebase's free tier includes:
- **2 million function invocations per month** (FREE)
- **400,000 GB-seconds compute time per month** (FREE)
- **200,000 GB-seconds networking egress per month** (FREE)

For email OTP, you'll likely use less than 1% of these limits per month, so **you'll pay $0** in most cases.

## What Changed

I've improved the error messages so they're more user-friendly. Instead of showing technical errors, users will now see:

> "Account created! Please check your email inbox (and spam folder) for the verification code."

This way, even if the function isn't deployed, users aren't confused by technical errors.

## Need Help?

If you have questions about billing:
- Firebase Billing FAQ: https://firebase.google.com/support/faq#expandable-15
- Contact Firebase Support: https://firebase.google.com/support

