# Quick CLI Deployment Commands

Run these commands in order using PowerShell/CLI:

## 1. Navigate to Project

```powershell
cd C:\Desktop\login.github.io
```

## 2. Set Firebase Project

```powershell
firebase use customer-c538e
```

## 3. Install Dependencies (if not done)

```powershell
cd functions
npm install
cd ..
```

## 4. Deploy Firebase Functions

```powershell
firebase deploy --only functions:sendOTP
```

**That's it!** The function already has EmailJS credentials hardcoded as defaults, so it should work immediately.

## 5. Test on Your Vivo V50

After deployment completes:

1. Run your Flutter app:
   ```powershell
   flutter run
   ```

2. Create a new account
3. Check email inbox

## View Logs (to see what's happening)

```powershell
firebase functions:log --only sendOTP
```

## If You Want to Use Custom EmailJS Credentials

Create `functions\.env` file manually (this file is gitignored for security):

```powershell
cd functions
@"
EMAILJS_SERVICE_ID=service_yp8e8yv
EMAILJS_TEMPLATE_ID=template_cp368bp
EMAILJS_PUBLIC_KEY=ORSGxHfkgWz4A7WVd
"@ | Out-File -FilePath ".env" -Encoding utf8
cd ..
```

Then redeploy:
```powershell
firebase deploy --only functions:sendOTP
```

## Verify Deployment

```powershell
firebase functions:list
```

You should see `sendOTP` function listed.


