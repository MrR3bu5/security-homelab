# SIEM & RBAC Troubleshooting

## Context

This document captures issues encountered while deploying Wazuh and implementing least-privileged SOC access using OpenSearch RBAC.

The focus was on **correct authorization**, not just authentication.

---

## Issues Encountered

### 1. User Could Authenticate but Not Access Dashboards

**Symptoms**
- Login succeeded
- Web UI displayed "Application Not Found" or permission errors

**Root Cause**
- User lacked tenant access
- Backend role not mapped to required dashboard roles

**Resolution**
- Assigned backend role to appropriate read-only roles
- Granted read access to the global tenant
- Restarted dashboard service to clear stale authorization cache

**Lesson Learned**
> Authentication without authorization is a common SIEM failure mode.

---

### 2. Index Permission Errors for Read-Only User

**Symptoms**
- Errors related to `indices:data/read/search`
- No data visible despite successful login

**Root Cause**
- Read-only role lacked index-level permissions for Wazuh indices

**Resolution**
- Mapped backend role to multiple read-focused roles
- Verified index permissions for alerts and archives

**Lesson Learned**
> SIEM RBAC is layered — missing any layer breaks visibility.

---

### 3. Accidental Lockout During Role Configuration

**Symptoms**
- "Forbidden" errors while editing roles
- Inability to modify security settings

**Root Cause**
- Admin user not operating within correct tenant
- Insufficient privileges applied during role editing

**Resolution**
- Ensured admin access under global tenant
- Avoided modifying built-in roles directly

**Lesson Learned**
> RBAC misconfiguration can block even administrators if context is wrong.

---

## Key Takeaways

- SIEM RBAC must be designed intentionally
- Least privilege requires more configuration, not less
- Troubleshooting authorization is as important as ingesting logs
