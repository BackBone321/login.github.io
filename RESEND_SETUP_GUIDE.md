# 📧 Resend Setup Guide - Super Simple!

## ✅ What's Done
- Code updated to use **Resend** for mobile (Android/iOS)
- Web still uses **EmailJS** (already working)
- No extra packages needed!

---

## 🚀 Setup (3 Easy Steps!)

### Step 1: Sign Up for Resend (1 minute)

1. Go to: **https://resend.com/signup**
2. Sign up with your email
3. Verify your email

**Free Plan:**
- ✅ 100 emails/day (3,000/month)
- ✅ Works on mobile apps
- ✅ No credit card required

---

### Step 2: Get Your API Key (30 seconds)

1. Go to: **https://resend.com/api-keys**
2. Click **"Create API Key"**
3. Give it a name: `AGRI GUARD`
4. Copy the API key (starts with `re_...`)

⚠️ **Save this key!** You can only see it once!

---

### Step 3: Update Config File (30 seconds)

Open: `lib/config/resend_config.dart`

```dart
class ResendConfig {
  // Paste your API key here
  static const String apiKey = 're_YOUR_API_KEY_HERE';
  
  // For testing, use Resend's default:
  static const String fromEmail = 'AGRI GUARD <onboarding@resend.dev>';
  
  // API URL (don't change)
  static const String apiUrl = 'https://api.resend.com/emails';
}
```

**Example:**
```dart
static const String apiKey = 're_abc123XYZ789...';
```

---

## ✅ That's It! Test Now!

```powershell
flutter run
```

Try signing up on your Android device - you'll receive the OTP email! 🎉

---

## 📱 How It Works

```
ANDROID/iOS → Resend API → Email Sent ✅
WEB         → EmailJS    → Email Sent ✅
```

---

## 🔧 Troubleshooting

### Error: "401 Unauthorized"
→ Check your API key in `resend_config.dart`

### Error: "validation_error"
→ Make sure `fromEmail` includes `<email@domain>`

### Email not received?
1. Check spam folder
2. Check Resend dashboard: https://resend.com/emails

---

## 🎯 For Production (Later)

To use your own domain:
1. Go to https://resend.com/domains
2. Add your domain
3. Add DNS records
4. Update `fromEmail` to `noreply@yourdomain.com`

---

## ✅ Checklist

- [ ] Sign up at resend.com
- [ ] Create API key
- [ ] Update `lib/config/resend_config.dart`
- [ ] Test on Android
- [ ] Email received! 🎉



