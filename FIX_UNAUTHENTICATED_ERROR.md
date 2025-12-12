# Fix "UNAUTHENTICATED" Error

The Firebase Function is requiring authentication, but during signup, users aren't authenticated yet. We need to allow unauthenticated invocations.

## Quick Fix via Firebase Console

1. **Go to Firebase Console:**
   https://console.firebase.google.com/project/customer-c538e/functions

2. **Find the `sendOTP` function**

3. **Click on it** to view details

4. **Go to "Permissions" or "IAM" tab**

5. **Add "allUsers" as an invoker:**
   - Click "Add Principal" or "Add Member"
   - Principal: `allUsers`
   - Role: `Cloud Functions Invoker`
   - Click "Save"

Alternatively, you can use this direct link:
https://console.cloud.google.com/functions/list?project=customer-c538e

## Alternative: Use Firebase CLI (if you have gcloud installed)

```powershell
# First, install gcloud CLI or use Firebase Console
# Or run this if gcloud is available:
gcloud functions add-iam-policy-binding sendOTP \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/cloudfunctions.invoker"
```

## After Fixing

Once you allow unauthenticated invocations:
1. Test your Flutter app again
2. Create a new account
3. OTP email should work! 📧


