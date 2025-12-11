# Deploy Firebase Functions NOW - CLI Commands

Copy and paste these commands one by one in your CLI:

## Step 1: Go to Project Directory
```powershell
cd C:\Desktop\login.github.io
```

## Step 2: Set Firebase Project
```powershell
firebase use customer-c538e
```

## Step 3: Install Dependencies
```powershell
cd functions
npm install
cd ..
```

## Step 4: Deploy the Function
```powershell
firebase deploy --only functions:sendOTP
```

**Wait for deployment to complete** - this may take 2-3 minutes.

When you see:
```
✔  functions[sendOTP(us-central1)] Successful create operation.
```

You're done! ✅

## Step 5: Test on Your Vivo V50

1. Run your app:
   ```powershell
   flutter run
   ```

2. Create a new account
3. Check your email!

## Need Help?

View logs:
```powershell
firebase functions:log --only sendOTP
```

Check if function is deployed:
```powershell
firebase functions:list
```

