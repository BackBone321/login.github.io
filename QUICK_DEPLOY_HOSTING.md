# Quick Deploy to agriguard.com

## Quick Start (3 Steps)

### 1. Install Firebase CLI (if needed)
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Deploy

**Windows (PowerShell):**
```powershell
.\deploy-hosting.ps1
```

**macOS/Linux:**
```bash
chmod +x deploy-hosting.sh
./deploy-hosting.sh
```

**Or manually:**
```bash
flutter clean
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

## Set Up Custom Domain

1. Go to: https://console.firebase.google.com/project/customer-c538e/hosting
2. Click "Add custom domain"
3. Enter: `agriguard.com`
4. Add the DNS records provided by Firebase to your domain registrar
5. Wait for DNS propagation (24-48 hours)

## Your App Will Be Live At:
- **Temporary**: `https://customer-c538e.web.app`
- **Custom Domain**: `https://agriguard.com` (after DNS setup)

---

For detailed instructions, see `HOSTING_SETUP.md`



