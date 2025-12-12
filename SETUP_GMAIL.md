# Setup Gmail for OTP Emails

The Firebase Function is deployed, but it needs Gmail credentials to send emails. EmailJS doesn't work reliably from server-side, so we'll use Gmail as the primary method.

## Step 1: Get Gmail App Password

1. **Go to your Google Account:**
   https://myaccount.google.com/

2. **Enable 2-Step Verification** (if not already enabled):
   - Go to: https://myaccount.google.com/security
   - Turn on "2-Step Verification"

3. **Create an App Password:**
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Enter name: "Firebase Functions"
   - Click "Generate"
   - **Copy the 16-character password** (it looks like: `abcd efgh ijkl mnop`)

## Step 2: Set Gmail Credentials in Firebase Functions

Run these commands (replace with your actual Gmail and app password):

```powershell
# Set Gmail email
firebase functions:secrets:set GMAIL_EMAIL

# When prompted, enter your Gmail address (e.g., jweek967@gmail.com)

# Set Gmail app password
firebase functions:secrets:set GMAIL_APP_PASSWORD

# When prompted, enter the 16-character app password (remove spaces)
```

**OR** set them directly:

```powershell
echo "your-email@gmail.com" | firebase functions:secrets:set GMAIL_EMAIL
echo "your-16-char-app-password" | firebase functions:secrets:set GMAIL_APP_PASSWORD
```

## Step 3: Update Function to Use Secrets

The function code already supports environment variables. We need to update it to use Firebase Secrets. Let me update the code for you.

## Step 4: Redeploy Function

After setting secrets:

```powershell
firebase deploy --only functions:sendOTP
```

## Alternative: Use Environment Variables (Easier)

Instead of secrets, we can use Firebase Functions environment variables:

```powershell
# Set environment variables
firebase functions:config:set gmail.email="jweek967@gmail.com" gmail.password="your-16-char-app-password"

# Redeploy
firebase deploy --only functions:sendOTP
```

**Note:** The `functions.config()` API is deprecated but still works until March 2026.

## Quick Setup Script

I'll create a script to help you set this up easily. For now, run:

```powershell
firebase functions:config:set gmail.email="YOUR_GMAIL@gmail.com" gmail.password="YOUR_APP_PASSWORD"
firebase deploy --only functions:sendOTP
```

Replace:
- `YOUR_GMAIL@gmail.com` with your Gmail address
- `YOUR_APP_PASSWORD` with the 16-character app password (no spaces)


