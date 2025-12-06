# 🗄️ Oracle Audit Trail Setup Guide

This guide helps you connect your AGRI GUARD audit logs to Oracle Database.

## ✅ What's Been Set Up

1. **Firebase Cloud Function** - Automatically syncs new audit logs to Oracle
2. **Oracle Schema** - Table structure for storing audit logs
3. **Environment Template** - Configuration for Oracle credentials

---

## 📋 Setup Steps

### Step 1: Create Oracle Table

Run this SQL in your Oracle database (SQL Developer, SQLcl, or Oracle Cloud Console):

```sql
-- File: functions/oracle_schema.sql

CREATE TABLE AUDIT_LOGS (
    ID VARCHAR2(100) PRIMARY KEY,
    ACTION VARCHAR2(100) NOT NULL,
    ENTITY_TYPE VARCHAR2(50) NOT NULL,
    ENTITY_ID VARCHAR2(100),
    SEVERITY VARCHAR2(20) DEFAULT 'info',
    ACTOR_ID VARCHAR2(100),
    ACTOR_EMAIL VARCHAR2(255),
    ACTOR_NAME VARCHAR2(255),
    TARGET_USER_ID VARCHAR2(100),
    DESCRIPTION VARCHAR2(1000),
    TIMESTAMP TIMESTAMP WITH TIME ZONE,
    METADATA CLOB,
    SYNCED_AT TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CHK_SEVERITY CHECK (SEVERITY IN ('info', 'warning', 'critical'))
);

-- Create indexes
CREATE INDEX IDX_AUDIT_TIMESTAMP ON AUDIT_LOGS (TIMESTAMP DESC);
CREATE INDEX IDX_AUDIT_ACTION ON AUDIT_LOGS (ACTION);
CREATE INDEX IDX_AUDIT_SEVERITY ON AUDIT_LOGS (SEVERITY);
```

---

### Step 2: Get Your Oracle Connection Details

You need these values from your Oracle setup:

| Setting | Example | Where to Find |
|---------|---------|---------------|
| **ORACLE_USER** | `AUDIT_USER` | Your Oracle username/schema |
| **ORACLE_PASSWORD** | `SecurePass123` | Your Oracle password |
| **ORACLE_CONNECTION_STRING** | See below | Depends on Oracle type |

#### Connection String Examples:

**Local Oracle XE/EE:**
```
localhost:1521/XEPDB1
```

**Remote Server:**
```
192.168.1.100:1521/ORCL
```

**Oracle Cloud Autonomous Database:**
```
(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.us-ashburn-1.oraclecloud.com))(connect_data=(service_name=abc123xyz_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))
```

---

### Step 3: Configure Environment Variables

1. Copy the template:
```powershell
cd functions
copy env.template .env
```

2. Edit `.env` with your Oracle credentials:
```env
# Existing Gmail config
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-password

# Oracle Database
ORACLE_USER=AUDIT_USER
ORACLE_PASSWORD=YourSecurePassword
ORACLE_CONNECTION_STRING=hostname:1521/XEPDB1
```

---

### Step 4: Install Dependencies

```powershell
cd functions
npm install
```

---

### Step 5: Deploy to Firebase

```powershell
# Set environment variables in Firebase (for production)
firebase functions:secrets:set ORACLE_USER
firebase functions:secrets:set ORACLE_PASSWORD
firebase functions:secrets:set ORACLE_CONNECTION_STRING

# Deploy
firebase deploy --only functions
```

---

## 🔧 Oracle Cloud Autonomous Database Setup

If using Oracle Cloud (recommended for production):

### 1. Download Wallet
- Go to Oracle Cloud Console → Autonomous Database → Your DB
- Click "Database connection"
- Download "Instance Wallet"
- Extract to a secure location

### 2. Configure Wallet Path
Add to your `.env`:
```env
ORACLE_WALLET_DIR=/path/to/wallet
```

### 3. Use Wallet Connection String
The connection string is in the wallet's `tnsnames.ora` file.

---

## 🔄 How It Works

```
┌─────────────────┐
│  Flutter App    │ 
│  (Your App)     │
└────────┬────────┘
         │ Writes audit log
         ▼
┌─────────────────┐
│ Firebase        │
│ Firestore       │ ← audit_logs collection
└────────┬────────┘
         │ Triggers Cloud Function
         ▼
┌─────────────────┐
│ syncAuditLog    │
│ ToOracle()      │ ← Firebase Function
└────────┬────────┘
         │ INSERT INTO AUDIT_LOGS
         ▼
┌─────────────────┐
│ Oracle Database │ ← Permanent audit storage
│ (AUDIT_LOGS)    │
└─────────────────┘
```

Every time your app creates an audit log in Firestore:
1. ✅ Log is saved to Firestore (real-time access)
2. ✅ Cloud Function triggers automatically
3. ✅ Log is synced to Oracle (enterprise storage)
4. ✅ Firestore document marked with `oracleSynced: true`

---

## 📊 Query Your Audit Logs in Oracle

### Recent Logs
```sql
SELECT * FROM AUDIT_LOGS 
ORDER BY TIMESTAMP DESC 
FETCH FIRST 100 ROWS ONLY;
```

### Critical Events
```sql
SELECT * FROM AUDIT_LOGS 
WHERE SEVERITY = 'critical' 
ORDER BY TIMESTAMP DESC;
```

### User Activity Report
```sql
SELECT ACTOR_EMAIL, ACTION, COUNT(*) as COUNT
FROM AUDIT_LOGS
WHERE TIMESTAMP > SYSDATE - 7  -- Last 7 days
GROUP BY ACTOR_EMAIL, ACTION
ORDER BY COUNT DESC;
```

### Daily Summary
```sql
SELECT 
    TRUNC(TIMESTAMP) as DAY,
    COUNT(*) as TOTAL_LOGS,
    SUM(CASE WHEN SEVERITY = 'critical' THEN 1 ELSE 0 END) as CRITICAL,
    SUM(CASE WHEN SEVERITY = 'warning' THEN 1 ELSE 0 END) as WARNINGS
FROM AUDIT_LOGS
GROUP BY TRUNC(TIMESTAMP)
ORDER BY DAY DESC;
```

---

## 🔧 Manual Sync & Backfill

To sync existing audit logs that weren't synced (or retry failed ones):

### From Flutter (call the Cloud Function):
```dart
final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
final result = await functions.httpsCallable('manualSyncAuditLogs').call({
  'limit': 500,        // Max logs to sync
  'onlyFailed': true,  // Only retry failed syncs
});
print('Synced: ${result.data['synced']}, Failed: ${result.data['failed']}');
```

---

## 🐛 Troubleshooting

### "Oracle not configured"
- Check your `.env` file has all 3 Oracle variables
- Ensure Firebase secrets are set for production

### "ORA-12170: TNS:Connect timeout"
- Verify your connection string
- Check firewall allows port 1521 (or 1522 for Cloud)
- For Oracle Cloud, ensure wallet is configured

### "ORA-01017: invalid username/password"
- Double-check ORACLE_USER and ORACLE_PASSWORD
- Ensure the user has INSERT privilege on AUDIT_LOGS table

### View Logs
```powershell
firebase functions:log
```

---

## 🔒 Security Best Practices

1. **Never commit `.env` to git** - Already in `.gitignore`
2. **Use Firebase Secrets** for production credentials
3. **Limit Oracle user permissions** - Only INSERT on AUDIT_LOGS
4. **Enable Oracle Audit** on the AUDIT_LOGS table itself

### Grant Minimum Permissions
```sql
-- Create a dedicated user for the app
CREATE USER agriguard_app IDENTIFIED BY "SecurePassword";
GRANT CONNECT TO agriguard_app;
GRANT INSERT ON your_schema.AUDIT_LOGS TO agriguard_app;
GRANT SELECT ON your_schema.AUDIT_LOGS TO agriguard_app;
```

---

## ✨ You're Done!

Your audit logs now sync automatically to Oracle! 

- **Firebase Firestore** = Real-time access in your app
- **Oracle Database** = Enterprise-grade permanent storage for compliance

Questions? Check the Firebase Functions logs or Oracle alert logs for debugging.




