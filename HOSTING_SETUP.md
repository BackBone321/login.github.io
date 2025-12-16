# AgriGuard Hosting Setup Guide

This guide will help you deploy your AgriGuard Flutter web app to Firebase Hosting with the custom domain **agriguard.com**.

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Node.js and npm** installed
3. **Firebase CLI** installed
4. **Firebase project** set up (already configured)
5. **Domain ownership** of agriguard.com

## Step 1: Install Firebase CLI (if not already installed)

### Windows (PowerShell):
```powershell
npm install -g firebase-tools
```

### macOS/Linux:
```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for authentication.

## Step 3: Initialize Firebase Hosting (if not already done)

```bash
firebase init hosting
```

When prompted:
- **What do you want to use as your public directory?** → `build/web`
- **Configure as a single-page app?** → `Yes`
- **Set up automatic builds and deploys with GitHub?** → `No` (or Yes if you want CI/CD)

## Step 4: Build Your Flutter Web App

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (release mode)
flutter build web --release
```

## Step 5: Deploy to Firebase Hosting

### Option A: Using the deployment script (Recommended)

**Windows:**
```powershell
.\deploy-hosting.ps1
```

**macOS/Linux:**
```bash
chmod +x deploy-hosting.sh
./deploy-hosting.sh
```

### Option B: Manual deployment

```bash
firebase deploy --only hosting
```

## Step 6: Set Up Custom Domain (agriguard.com)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Select your project: `customer-c538e`

2. **Navigate to Hosting**
   - Click on "Hosting" in the left sidebar
   - Click "Add custom domain"

3. **Add Your Domain**
   - Enter: `agriguard.com`
   - Click "Continue"

4. **Configure DNS Records**
   - Firebase will provide you with DNS records (A records or CNAME)
   - You need to add these records in your domain registrar's DNS settings

5. **DNS Configuration Options:**

   **Option 1: A Records (Recommended)**
   ```
   Type: A
   Name: @ (or leave blank)
   Value: [IP addresses provided by Firebase]
   TTL: 3600
   ```

   **Option 2: CNAME Record**
   ```
   Type: CNAME
   Name: @ (or www)
   Value: [Firebase hosting URL]
   TTL: 3600
   ```

6. **Wait for DNS Propagation**
   - DNS changes can take 24-48 hours to propagate
   - Firebase will automatically detect when DNS is configured correctly

7. **SSL Certificate**
   - Firebase automatically provisions SSL certificates via Let's Encrypt
   - This happens automatically once DNS is configured

## Step 7: Verify Deployment

After deployment, your app will be available at:
- **Firebase default URL**: `https://[your-project-id].web.app`
- **Custom domain** (after DNS setup): `https://agriguard.com`

## Troubleshooting

### Build Errors
- Ensure Flutter web is enabled: `flutter config --enable-web`
- Check that all dependencies are compatible with web platform

### Deployment Errors
- Verify you're logged in: `firebase login`
- Check project selection: `firebase use [project-id]`
- Ensure build/web directory exists after `flutter build web`

### DNS Issues
- Use online DNS checker tools to verify DNS propagation
- Ensure DNS records are correctly configured at your domain registrar
- Wait 24-48 hours for full DNS propagation

### SSL Certificate Issues
- Firebase automatically provisions SSL certificates
- If certificate fails, check DNS configuration
- Contact Firebase support if issues persist

## Continuous Deployment

To set up automatic deployments:

1. **Connect GitHub Repository**
   ```bash
   firebase init hosting
   # Select GitHub when prompted
   ```

2. **Configure GitHub Actions** (optional)
   - Create `.github/workflows/deploy.yml`
   - Set up automated builds on push to main branch

## Environment Variables

If you need environment-specific configurations:
- Create `.env` files for different environments
- Use `flutter build web --dart-define=ENV=production`

## Performance Optimization

The current configuration includes:
- ✅ Cache headers for static assets
- ✅ Single-page app routing
- ✅ Security headers (X-Frame-Options, X-XSS-Protection, etc.)

## Monitoring

Monitor your deployment:
- **Firebase Console**: https://console.firebase.google.com/project/customer-c538e/hosting
- **Analytics**: Available in Firebase Console
- **Performance**: Check browser DevTools Network tab

## Support

For issues:
1. Check Firebase Hosting documentation: https://firebase.google.com/docs/hosting
2. Flutter web documentation: https://flutter.dev/web
3. Firebase support: https://firebase.google.com/support

---

**Your app is now live at: https://agriguard.com** 🎉



