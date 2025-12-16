# Quick DNS Setup for agriguard.com

## Add These 3 DNS Records

### 1. CAA Record (Allows SSL Certificate)
```
Type: CAA
Name: @
Value: 0 issue "letsencrypt.org"
TTL: 3600
```

### 2. A Record (Points to Firebase)
```
Type: A
Name: @
Value: 199.36.158.100
TTL: 3600
```

### 3. TXT Record (Verification)
```
Type: TXT
Name: @
Value: hosting-site=customer-c538e
TTL: 3600
```

## Steps

1. **Go to your domain registrar** (where you bought agriguard.com)
2. **Find DNS Management** section
3. **Add all 3 records** above
4. **Wait 1-2 hours** for DNS to propagate
5. **Go back to Firebase Console** and click "Verify"

## Check Your DNS Provider

- **Cloudflare**: DNS → Records → Add Record
- **GoDaddy**: DNS Management → Add
- **Namecheap**: Advanced DNS → Add New Record
- **Google Domains**: DNS → Custom records

## Verify It's Working

After 1-2 hours, check:
- https://dnschecker.org/#CAA/agriguard.com (should show letsencrypt.org)
- https://dnschecker.org/#A/agriguard.com (should show 199.36.158.100)

Then click "Verify" in Firebase Console!



