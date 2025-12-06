-- ============================================
-- AGRI GUARD - Oracle Audit Logs Table Schema
-- ============================================
-- Run this SQL script in your Oracle database to create the audit_logs table

-- Create the AUDIT_LOGS table
CREATE TABLE AUDIT_LOGS (
    -- Primary key - matches Firestore document ID
    ID VARCHAR2(100) PRIMARY KEY,
    
    -- Action performed (e.g., 'user.create', 'detection.create', 'announcement.create')
    ACTION VARCHAR2(100) NOT NULL,
    
    -- Entity type (e.g., 'user', 'detection', 'announcement')
    ENTITY_TYPE VARCHAR2(50) NOT NULL,
    
    -- Entity ID (the ID of the affected entity)
    ENTITY_ID VARCHAR2(100),
    
    -- Severity level: 'info', 'warning', 'critical'
    SEVERITY VARCHAR2(20) DEFAULT 'info',
    
    -- Actor information (who performed the action)
    ACTOR_ID VARCHAR2(100),
    ACTOR_EMAIL VARCHAR2(255),
    ACTOR_NAME VARCHAR2(255),
    
    -- Target user (if action affects another user)
    TARGET_USER_ID VARCHAR2(100),
    
    -- Human-readable description
    DESCRIPTION VARCHAR2(1000),
    
    -- When the action occurred (from Firestore)
    TIMESTAMP TIMESTAMP WITH TIME ZONE,
    
    -- Additional metadata as JSON
    METADATA CLOB,
    
    -- When this record was synced to Oracle
    SYNCED_AT TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT CHK_SEVERITY CHECK (SEVERITY IN ('info', 'warning', 'critical')),
    CONSTRAINT CHK_METADATA_JSON CHECK (METADATA IS JSON OR METADATA IS NULL)
);

-- Create indexes for common queries
CREATE INDEX IDX_AUDIT_TIMESTAMP ON AUDIT_LOGS (TIMESTAMP DESC);
CREATE INDEX IDX_AUDIT_ACTION ON AUDIT_LOGS (ACTION);
CREATE INDEX IDX_AUDIT_ENTITY_TYPE ON AUDIT_LOGS (ENTITY_TYPE);
CREATE INDEX IDX_AUDIT_SEVERITY ON AUDIT_LOGS (SEVERITY);
CREATE INDEX IDX_AUDIT_ACTOR_ID ON AUDIT_LOGS (ACTOR_ID);
CREATE INDEX IDX_AUDIT_TARGET_USER ON AUDIT_LOGS (TARGET_USER_ID);

-- Create a composite index for filtered queries
CREATE INDEX IDX_AUDIT_TYPE_TIME ON AUDIT_LOGS (ENTITY_TYPE, TIMESTAMP DESC);

-- Add comments for documentation
COMMENT ON TABLE AUDIT_LOGS IS 'Audit trail synced from Firebase Firestore - AGRI GUARD application';
COMMENT ON COLUMN AUDIT_LOGS.ID IS 'Firestore document ID';
COMMENT ON COLUMN AUDIT_LOGS.ACTION IS 'Action type: user.create, detection.create, etc.';
COMMENT ON COLUMN AUDIT_LOGS.ENTITY_TYPE IS 'Type of entity affected: user, detection, announcement';
COMMENT ON COLUMN AUDIT_LOGS.SEVERITY IS 'Log severity: info, warning, critical';
COMMENT ON COLUMN AUDIT_LOGS.METADATA IS 'Additional context as JSON';
COMMENT ON COLUMN AUDIT_LOGS.SYNCED_AT IS 'When this record was synced from Firestore to Oracle';

-- ============================================
-- USEFUL QUERIES
-- ============================================

-- View recent audit logs
-- SELECT * FROM AUDIT_LOGS ORDER BY TIMESTAMP DESC FETCH FIRST 100 ROWS ONLY;

-- Count logs by action type
-- SELECT ACTION, COUNT(*) as COUNT FROM AUDIT_LOGS GROUP BY ACTION ORDER BY COUNT DESC;

-- Get critical events
-- SELECT * FROM AUDIT_LOGS WHERE SEVERITY = 'critical' ORDER BY TIMESTAMP DESC;

-- Get user activity
-- SELECT * FROM AUDIT_LOGS WHERE ACTOR_ID = 'user_uid_here' ORDER BY TIMESTAMP DESC;

-- Daily audit summary
-- SELECT TRUNC(TIMESTAMP) as DAY, COUNT(*) as TOTAL,
--        SUM(CASE WHEN SEVERITY = 'critical' THEN 1 ELSE 0 END) as CRITICAL,
--        SUM(CASE WHEN SEVERITY = 'warning' THEN 1 ELSE 0 END) as WARNINGS
-- FROM AUDIT_LOGS
-- GROUP BY TRUNC(TIMESTAMP)
-- ORDER BY DAY DESC;

-- ============================================
-- OPTIONAL: Partitioning for large datasets
-- ============================================
-- If you expect millions of records, consider range partitioning by timestamp:
--
-- CREATE TABLE AUDIT_LOGS_PARTITIONED (
--     ... same columns ...
-- ) PARTITION BY RANGE (TIMESTAMP) (
--     PARTITION p2024_q1 VALUES LESS THAN (TIMESTAMP '2024-04-01 00:00:00'),
--     PARTITION p2024_q2 VALUES LESS THAN (TIMESTAMP '2024-07-01 00:00:00'),
--     PARTITION p2024_q3 VALUES LESS THAN (TIMESTAMP '2024-10-01 00:00:00'),
--     PARTITION p2024_q4 VALUES LESS THAN (TIMESTAMP '2025-01-01 00:00:00'),
--     PARTITION p_future VALUES LESS THAN (MAXVALUE)
-- );




