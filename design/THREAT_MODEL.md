# Threat Model

Comprehensive threat analysis and security mitigations for the homelab infrastructure.

## Table of Contents

1. [Overview](#overview)
2. [Assets and Data Classification](#assets-and-data-classification)
3. [Threat Actors](#threat-actors)
4. [Attack Surface Analysis](#attack-surface-analysis)
5. [Threat Scenarios](#threat-scenarios)
6. [Mitigations](#mitigations)
7. [Residual Risks](#residual-risks)
8. [Incident Response](#incident-response)

---

## Overview

### Purpose

This threat model identifies:
- What we're protecting (assets)
- Who might attack us (threat actors)
- How they might attack (attack vectors)
- What we're doing about it (mitigations)
- What risks remain (residual risks)

### Methodology

**STRIDE Framework:**
- **S**poofing: Impersonating users or systems
- **T**ampering: Modifying data or systems
- **R**epudiation: Denying actions taken
- **I**nformation Disclosure: Exposing sensitive data
- **D**enial of Service: Disrupting availability
- **E**levation of Privilege: Gaining unauthorized access

### Threat Model Scope

**In Scope:**
- External attacks from Internet
- Compromised VPN credentials
- Lab environment escape scenarios
- Insider threats (compromised devices)
- Service vulnerabilities

**Out of Scope:**
- Physical access attacks (home security)
- Supply chain attacks (hardware backdoors)
- Nation-state adversaries (not realistic threat)
- Social engineering of family members

---

## Assets and Data Classification

### Critical Assets

**Priority 1: High Value**

| Asset | Location | Value | Impact if Compromised |
|-------|----------|-------|----------------------|
| fw-edge01 | Home network | Critical | Full network compromise |
| Proxmox Host | Home network | Critical | Control of all VMs |
| VPN Private Keys | Client devices | High | Unauthorized network access |
| SSH Private Keys | Client devices | High | Server access |
| TrueNAS Data | Home network | High | Data loss/exposure |

**Priority 2: Medium Value**

| Asset | Location | Value | Impact if Compromised |
|-------|----------|-------|----------------------|
| fw-lab01 | Lab network | Medium | Lab control (already untrusted) |
| Jumphost | Home network | Medium | Lab access |
| Domain Controller | Lab network | Low | Lab AD compromise (expected) |
| Lab VMs | Lab network | Low | Expected to be compromised |

### Data Classification

**Confidential:**
- VPN configuration and keys
- SSH private keys
- Firewall configurations
- Personal files on TrueNAS
- Credentials and passwords

**Internal:**
- Network topology
- IP addressing scheme
- Service configurations
- Firewall rules (non-sensitive)

**Public:**
- General architecture design
- Technology choices
- Non-specific documentation

---

## Threat Actors

### External Opportunistic Attackers

**Profile:**
- Skill Level: Low to Medium
- Motivation: Opportunistic, scanning internet
- Resources: Automated tools, botnets
- Goals: Botnet recruitment, crypto mining, data theft

**Capabilities:**
- Port scanning and service enumeration
- Exploiting known vulnerabilities
- Brute force attacks
- DDoS attacks

**Likelihood:** HIGH (constant internet scanning)

**Target Assets:**
- Any exposed services
- WireGuard VPN endpoint
- Previously exposed services (if any)

---

### Targeted Attackers

**Profile:**
- Skill Level: Medium to High
- Motivation: Targeted attack, specific interest
- Resources: Custom tools, time investment
- Goals: Data theft, persistent access, espionage

**Capabilities:**
- Advanced reconnaissance
- Zero-day exploitation
- Social engineering
- Persistence mechanisms

**Likelihood:** LOW (homelab not high-value target)

**Target Assets:**
- VPN access
- High-value data on TrueNAS
- Persistent access to infrastructure

---

### Insider Threats (Compromised Devices)

**Profile:**
- Skill Level: Varies (malware capability)
- Motivation: Automated malware behavior
- Resources: Compromised home device
- Goals: Lateral movement, data theft

**Capabilities:**
- Already inside home network
- Potential access to shared resources
- Network scanning
- Credential theft

**Likelihood:** MEDIUM (realistic scenario)

**Target Assets:**
- Other home devices
- Shared network resources
- Credentials stored on compromised device

---

### Lab Environment Threats

**Profile:**
- Skill Level: Self (intentional)
- Motivation: Testing and learning
- Resources: Full lab control
- Goals: Escape lab to production

**Capabilities:**
- Full control of lab VMs
- Malware and attack tools
- Network exploitation
- Persistence mechanisms

**Likelihood:** HIGH (intentional testing)

**Target Assets:**
- Home network (via fw-lab01 escape)
- fw-edge01 (if reachable)
- Production services

---

## Attack Surface Analysis

### External Attack Surface (Internet-Facing)

**Exposed Services:**

| Service | Port | Protocol | Exposure | Risk Level |
|---------|------|----------|----------|-----------|
| WireGuard VPN | 51820 | UDP | Internet | LOW |

**Total Exposed Ports:** 1

**Attack Vectors:**
1. Exploit vulnerability in WireGuard
2. Brute force VPN handshake (ineffective with public key auth)
3. DDoS on UDP 51820
4. Zero-day in WireGuard implementation

**Risk Assessment:**
- Very small attack surface (single port)
- WireGuard cryptographically secure
- No password-based authentication
- Modern, audited codebase

**Mitigation Effectiveness:** HIGH

---

### VPN Attack Surface (Authenticated Users)

**Accessible Services via VPN:**

| Service | IP:Port | Authentication | Risk Level |
|---------|---------|----------------|-----------|
| Proxmox | 192.168.x.241:8006 | Username/Password | MEDIUM |
| TrueNAS | 192.168.x.240:443 | Username/Password | MEDIUM |
| TrueNAS SMB | 192.168.x.240:445 | Username/Password | MEDIUM |
| Jumphost | 192.168.x.67:2222 | SSH Key | LOW |

**Attack Vectors:**
1. Compromised VPN private key
2. Stolen service credentials
3. Vulnerability in Proxmox/TrueNAS
4. Man-in-the-middle (within VPN tunnel)

**Risk Assessment:**
- Limited to explicit services only
- Service-level authentication required
- No management interface access
- Cannot reach other home devices

**Mitigation Effectiveness:** MEDIUM-HIGH

---

### Home Network Attack Surface (Internal)

**Potential Insider Threats:**

| Source | Access | Risk Level |
|--------|--------|-----------|
| Compromised home device | Full LAN access | HIGH |
| Malware on personal computer | Shared resources | MEDIUM |
| Guest device | Home network (future guest VLAN) | LOW |

**Attack Vectors:**
1. Malware on trusted device
2. Network scanning from compromised device
3. Credential theft from home device
4. Lateral movement via shared resources

**Risk Assessment:**
- All home devices currently trusted
- No network segmentation (yet)
- Shared resources accessible
- No guest network isolation

**Mitigation Effectiveness:** MEDIUM (planned improvement)

---

### Lab Attack Surface (Isolated Environment)

**Intentional Exposure:**

| Source | Target | Allowed |
|--------|--------|---------|
| Lab VMs | Internet | YES (for tools/updates) |
| Lab VMs | Home network | NO (blocked by fw-lab01) |
| Jumphost | Lab VMs | YES (controlled access) |

**Attack Vectors:**
1. Lab malware attempting to escape
2. Misconfigured firewall rule
3. Vulnerability in fw-lab01
4. Routing misconfiguration

**Risk Assessment:**
- Lab assumed compromised at all times
- Dedicated isolation firewall (fw-lab01)
- Actively tested isolation
- Regular validation of rules

**Mitigation Effectiveness:** HIGH

---

## Threat Scenarios

### Scenario 1: External Port Scan and Exploitation Attempt

**Threat Actor:** External Opportunistic Attacker

**Attack Chain:**

    Step 1: Port Scan
    ├─ Attacker scans public IP
    ├─ Discovers UDP 51820 (WireGuard)
    └─ All other ports closed/filtered

    Step 2: Service Enumeration
    ├─ Attempts to identify service on 51820
    ├─ WireGuard doesn't respond to probes
    └─ No version information disclosed

    Step 3: Exploitation Attempt
    ├─ Attempts known WireGuard exploits (if any)
    ├─ Attempts handshake brute force (cryptographically infeasible)
    └─ No success

**Outcome:** Attack fails, no unauthorized access

**Mitigations in Place:**
- Single exposed port minimizes attack surface
- WireGuard uses public key authentication (no passwords to brute force)
- No service version disclosure
- Stateful firewall blocks all other ports
- Attack attempts logged

**Residual Risk:** LOW
- Zero-day vulnerability in WireGuard (unlikely)
- Monitor for WireGuard CVEs and update promptly

---

### Scenario 2: Compromised VPN Private Key

**Threat Actor:** External Attacker with Stolen Credentials

**Attack Chain:**

    Step 1: Key Compromise
    ├─ Attacker steals VPN private key from device
    ├─ Via malware, physical access, or backup theft
    └─ Has valid WireGuard credentials

    Step 2: VPN Connection
    ├─ Attacker establishes VPN tunnel
    ├─ Assigned IP: 10.6.0.x
    └─ Authenticated to VPN

    Step 3: Network Reconnaissance
    ├─ Attempts to scan home network
    ├─ Discovers no response from most hosts
    └─ Firewall blocks unauthorized destinations

    Step 4: Service Access Attempts
    ├─ Can access: Proxmox, TrueNAS, Jumphost (allowed services)
    ├─ Blocked from: fw-edge01 management, other devices
    └─ Limited blast radius

    Step 5: Service-Level Authentication
    ├─ Proxmox: Requires username/password (+ 2FA if enabled)
    ├─ TrueNAS: Requires username/password
    ├─ Jumphost: Requires SSH private key (different key)
    └─ Cannot access without additional credentials

**Outcome:** Limited access, additional authentication required

**Mitigations in Place:**
- Service-level access control (VPN ≠ full access)
- Explicit allow rules only
- No firewall management via VPN
- Service authentication required
- Connection logging for detection

**Detection:**
- Unusual VPN connection from new location
- Failed authentication attempts on services
- Access from unexpected source IP

**Response Actions:**
1. Revoke compromised VPN peer on fw-edge01
2. Review logs for accessed services
3. Check service logs for compromise indicators
4. Issue new VPN key to legitimate user
5. Enable 2FA on services if not already enabled

**Residual Risk:** MEDIUM
- If attacker also has service credentials: Can access specific services
- Mitigate with 2FA and strong passwords

---

### Scenario 3: Lab Malware Attempting Network Escape

**Threat Actor:** Lab Environment (Malware/Red Team Tools)

**Attack Chain:**

    Step 1: Lab VM Compromise
    ├─ Lab VM intentionally compromised during testing
    ├─ Malware or attacker tools active
    └─ Full control of lab VM (expected)

    Step 2: Network Reconnaissance
    ├─ Scans for other networks
    ├─ Discovers default gateway: 10.30.66.1 (fw-lab01)
    └─ Attempts to reach home network (192.168.x.0/24)

    Step 3: Escape Attempt
    ├─ Sends traffic to 192.168.x.241 (Proxmox)
    ├─ Reaches fw-lab01 LAN interface
    └─ Firewall evaluates rules

    Step 4: Firewall Blocks Traffic
    ├─ Rule: Block 10.30.0.0/16 → 192.168.x.0/24
    ├─ Match found: BLOCK
    ├─ Packet dropped
    └─ Attempt logged

    Step 5: Alternative Escape Attempts
    ├─ Attempts to reach fw-edge01 management
    ├─ Attempts to scan other home devices
    ├─ All blocked by fw-lab01
    └─ Cannot escape isolation

**Outcome:** Lab remains isolated, attack fails

**Mitigations in Place:**
- Dedicated isolation firewall (fw-lab01)
- Default deny lab → home network
- No routing path from lab to home
- Active firewall enforcement
- Regular isolation testing

**Validation:**
- Test regularly by attempting to reach home network from lab
- Should fail 100% of the time
- Alerts if successful (indicates firewall misconfiguration)

**Residual Risk:** LOW
- Firewall misconfiguration could allow escape
- Mitigate with validation scripts and regular testing

---

### Scenario 4: Proxmox Vulnerability Exploitation

**Threat Actor:** External Attacker via Compromised VPN

**Attack Chain:**

    Step 1: VPN Access
    ├─ Attacker has valid VPN credentials
    └─ Authenticated to VPN

    Step 2: Proxmox Access
    ├─ Accesses Proxmox GUI at 192.168.x.241:8006
    ├─ Has valid Proxmox credentials (compromised separately)
    └─ Logged into Proxmox interface

    Step 3: Exploitation
    ├─ Exploits vulnerability in Proxmox
    ├─ Gains shell access on Proxmox host
    └─ Has hypervisor-level access

    Step 4: Impact
    ├─ Can access all VMs (including production and lab)
    ├─ Can access TrueNAS storage
    ├─ Can modify firewall VMs (if hosted on Proxmox)
    └─ Critical compromise

**Outcome:** Critical infrastructure compromise

**Mitigations in Place:**
- Proxmox requires authentication (VPN ≠ automatic access)
- Regular patching and updates
- 2FA available (should be enabled)
- Access logging

**Detection:**
- Unusual Proxmox activity
- New VMs created
- Configuration changes
- Access from VPN IP

**Response Actions:**
1. Isolate Proxmox from network
2. Review all VMs for compromise
3. Check TrueNAS for unauthorized access
4. Restore from known-good backup
5. Patch vulnerability
6. Rotate all credentials

**Residual Risk:** HIGH (if compromised)
- Hypervisor compromise is critical
- Mitigate with prompt patching, 2FA, monitoring

---

### Scenario 5: Insider Threat - Compromised Home Device

**Threat Actor:** Malware on Home Network Device

**Attack Chain:**

    Step 1: Initial Compromise
    ├─ Home device infected with malware
    ├─ Device is on home network (192.168.x.0/24)
    └─ Has network access

    Step 2: Network Scanning
    ├─ Malware scans local network
    ├─ Discovers Proxmox, TrueNAS, fw-edge01, etc.
    └─ Full network visibility (flat network)

    Step 3: Lateral Movement Attempts
    ├─ Attempts to exploit Proxmox
    ├─ Attempts to access TrueNAS shares
    ├─ Attempts to access fw-edge01
    └─ Varies based on malware capability

    Step 4: Credential Theft
    ├─ Steals credentials stored on compromised device
    ├─ May include SSH keys, saved passwords
    └─ Can use for further access

**Outcome:** Potential compromise of accessible services

**Mitigations in Place:**
- Limited (currently on flat network)
- Service-level authentication required
- fw-edge01 management not accessible remotely
- Regular device updates

**Planned Mitigations:**
- VLAN segmentation (separate production from general use)
- Network monitoring/SIEM
- Guest network isolation
- Endpoint security tools

**Residual Risk:** MEDIUM-HIGH (current flat network)
- Will improve significantly with VLAN segmentation
- Priority for future implementation

---

## Mitigations

### Perimeter Defense

**Control:** Minimal Attack Surface

**Implementation:**
- Single exposed port (UDP 51820)
- All other ports blocked
- Stateful packet inspection
- No unnecessary services

**Effectiveness:** HIGH
- Dramatically reduces attack surface
- Limits attacker options
- Forces focus on single entry point

**Validation:**
- External port scan shows only UDP 51820
- Regular scanning to verify no other exposure

---

**Control:** Strong VPN Authentication

**Implementation:**
- WireGuard public key cryptography
- No password-based VPN access
- Modern encryption (Curve25519, ChaCha20)
- Per-device key pairs

**Effectiveness:** HIGH
- Brute force attacks ineffective
- No credential stuffing possible
- Strong cryptographic foundation

**Validation:**
- Monitor for WireGuard CVEs
- Update promptly when available
- Test key revocation process

---

### Access Control

**Control:** Zero Trust Network Access

**Implementation:**
- VPN authentication ≠ network access
- Service-level firewall rules
- Explicit allow-list only
- Default deny all

**Effectiveness:** HIGH
- Limits compromised VPN blast radius
- Prevents lateral movement via VPN
- No management interface exposure

**Validation:**
- Test VPN can only reach allowed services
- Verify management interfaces blocked
- Confirm no peer-to-peer VPN traffic

---

**Control:** Service Authentication

**Implementation:**
- Proxmox: Username/password (2FA capable)
- TrueNAS: Username/password (2FA capable)
- Jumphost: SSH public key only
- No shared credentials

**Effectiveness:** MEDIUM-HIGH
- Multiple authentication layers
- VPN + service authentication required
- 2FA adds additional protection

**Recommendations:**
- Enable 2FA on Proxmox and TrueNAS (HIGH PRIORITY)
- Use strong, unique passwords
- Regular password rotation
- Monitor failed authentication attempts

---

### Lab Isolation

**Control:** Dedicated Isolation Firewall

**Implementation:**
- fw-lab01 VM dedicated to isolation
- WAN: Connected to home network
- LAN: Lab segments
- Block lab → home network
- Allow lab → internet (filtered)

**Effectiveness:** HIGH
- Active enforcement (not just routing)
- Independent of edge firewall
- Cannot be bypassed from lab
- Regularly tested

**Validation:**
- Isolation test script (ping home network from lab)
- Should fail 100% of the time
- Run after any firewall change
- Automated testing recommended

---

**Control:** Jumphost as Single Entry Point

**Implementation:**
- Only Jumphost can access lab
- SSH public key authentication
- All lab access logged
- Jumphost hardened

**Effectiveness:** HIGH
- Single, controlled entry point
- No direct VPN to lab
- Forced authentication checkpoint
- Access auditing

**Recommendations:**
- Harden Jumphost (minimal packages)
- Regular security updates
- Strong SSH key protection
- Consider MFA for Jumphost (future)

---

### Monitoring and Detection

**Control:** Comprehensive Logging

**Implementation:**
- VPN connection logging
- Firewall decision logging
- Service access logging
- Failed authentication logging

**Effectiveness:** MEDIUM
- Enables detection and forensics
- Manual review required (currently)
- Historical data for investigation

**Improvements Needed:**
- Centralized logging (SIEM for home network)
- Automated alerting
- Correlation of events
- Real-time monitoring

---

**Control:** Lab SIEM (Wazuh)

**Implementation:**
- Wazuh deployed in lab
- Agents on all lab VMs
- Monitors attack activity
- Alerts on suspicious behavior

**Effectiveness:** MEDIUM-HIGH (for lab)
- Detects attacks in lab environment
- Practice blue team skills
- Real-time visibility

**Limitations:**
- Only monitors lab (not home network yet)
- Alert tuning required
- Manual response currently

---

### Patch Management

**Control:** Regular Updates

**Implementation:**
- fw-edge01: Monthly OPNsense updates
- fw-lab01: Monthly OPNsense updates
- Proxmox: Regular updates
- TrueNAS: Regular updates
- VMs: Varies by purpose

**Effectiveness:** MEDIUM
- Addresses known vulnerabilities
- Reduces exploit opportunities
- Manual process currently

**Improvements Needed:**
- Automated update scheduling
- Testing environment before production
- Vulnerability scanning
- Patch compliance monitoring

---

## Residual Risks

### High Residual Risks

**Risk 1: Flat Home Network**

**Description:** All home devices on same subnet

**Impact:** Compromised home device can reach all services

**Likelihood:** MEDIUM

**Mitigation Status:** Deferred (planned Q2 2026)

**Acceptance Rationale:**
- All home devices personally owned and trusted
- No guest access currently
- Service authentication provides layer
- VLAN segmentation planned

**Monitoring:**
- Watch for unusual network activity
- Keep devices updated
- Plan VLAN implementation

---

**Risk 2: No 2FA on Production Services**

**Description:** Proxmox and TrueNAS use password-only auth

**Impact:** Compromised credentials = full service access

**Likelihood:** LOW-MEDIUM

**Mitigation Status:** Available but not implemented

**Acceptance Rationale:**
- Service access requires VPN first
- Strong passwords in use
- Low likelihood of credential compromise

**Action Required:**
- **Enable 2FA on Proxmox (HIGH PRIORITY)**
- **Enable 2FA on TrueNAS (HIGH PRIORITY)**
- Test 2FA functionality
- Document recovery procedures

---

### Medium Residual Risks

**Risk 3: Single Proxmox Host**

**Description:** No redundancy for virtualization

**Impact:** Hardware failure = downtime for all VMs

**Likelihood:** LOW (reliable hardware)

**Mitigation Status:** Accepted (homelab tolerance)

**Acceptance Rationale:**
- Homelab can tolerate downtime
- Not production critical
- Cost of redundancy high
- Backups enable recovery

**Monitoring:**
- Regular backups
- Hardware health monitoring
- Spare parts availability

---

**Risk 4: Limited Intrusion Detection**

**Description:** No network-based IDS/IPS for home network

**Impact:** May not detect sophisticated attacks

**Likelihood:** LOW (minimal external exposure)

**Mitigation Status:** Planned (future)

**Acceptance Rationale:**
- Minimal attack surface (single port)
- Strong perimeter defense
- Logging provides some visibility
- SIEM planned for future

**Monitoring:**
- Manual log review
- Watch for anomalies
- Plan SIEM deployment

---

### Low Residual Risks

**Risk 5: WireGuard Zero-Day**

**Description:** Unknown vulnerability in WireGuard

**Impact:** Could bypass VPN security

**Likelihood:** VERY LOW (well-audited code)

**Mitigation Status:** Monitoring

**Acceptance Rationale:**
- Modern, audited codebase
- Active development and security research
- Small attack surface
- Prompt patching when CVEs found

**Monitoring:**
- Subscribe to WireGuard security advisories
- Apply updates promptly
- Monitor security news

---

## Incident Response

### Incident Classification

**Severity Levels:**

**Critical (P1):**
- fw-edge01 compromise
- Proxmox host compromise
- Lab escape to production
- Data exfiltration from TrueNAS

**High (P2):**
- Compromised VPN credentials in use
- Service account compromise
- Unauthorized access to production services
- Firewall rule misconfiguration

**Medium (P3):**
- Failed VPN connection attempts
- Failed authentication on services
- Lab VM compromise (expected)
- Suspicious network activity

**Low (P4):**
- Normal failed login attempts
- Expected lab activity
- Non-security events

---

### Response Procedures

**P1: Critical Incident**

**Immediate Actions (0-15 minutes):**
1. Isolate affected system from network (disconnect interface)
2. Preserve evidence (don't reboot if possible)
3. Document timeline of events
4. Review recent firewall logs

**Investigation (15-60 minutes):**
1. Determine scope of compromise
2. Identify indicators of compromise (IOCs)
3. Check other systems for IOCs
4. Review access logs for unauthorized activity

**Containment (1-4 hours):**
1. Revoke compromised credentials
2. Block attacker IP addresses
3. Patch exploited vulnerabilities
4. Restore from known-good backups if needed

**Recovery (4+ hours):**
1. Rebuild compromised systems
2. Validate clean state
3. Restore services
4. Monitor for reinfection

**Post-Incident (1-7 days):**
1. Document lessons learned
2. Update threat model
3. Implement additional controls
4. Test improvements

---

**P2: High Incident**

**Immediate Actions (0-30 minutes):**
1. Disable compromised account/key
2. Review logs for unauthorized access
3. Document suspicious activity
4. Assess scope

**Investigation (30-120 minutes):**
1. Identify what was accessed
2. Check for privilege escalation
3. Review firewall logs
4. Determine if data was exfiltrated

**Containment (2-8 hours):**
1. Rotate affected credentials
2. Update firewall rules if needed
3. Patch vulnerabilities
4. Enhance monitoring

**Recovery (8+ hours):**
1. Issue new credentials
2. Verify system integrity
3. Resume normal operations
4. Increase monitoring

**Post-Incident (1-3 days):**
1. Document incident
2. Update procedures
3. Improve controls

---

**P3: Medium Incident**

**Actions:**
1. Investigate suspicious activity
2. Document findings
3. No immediate isolation needed
4. Monitor for escalation

---

**P4: Low Incident**

**Actions:**
1. Log for awareness
2. No immediate action
3. Routine monitoring

---

### Contact Information

**Primary Administrator:**
- Name: [Your Name]
- Role: Homelab Administrator
- Contact: [Your Contact Method]

**Escalation Path:**
- Level 1: Self (homelab owner)
- Level 2: N/A (personal homelab)

**External Resources:**
- OPNsense Forum: https://forum.opnsense.org/
- Proxmox Forum: https://forum.proxmox.com/
- WireGuard Support: https://lists.zx2c4.com/mailman/listinfo/wireguard
- Security Advisories: Monitor vendor sites

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture
- [SECURITY_ZONES.md](SECURITY_ZONES.md) - Security controls
- [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) - Why choices were made
- [TRAFFIC_FLOWS.md](TRAFFIC_FLOWS.md) - How packets move
- [../security/incident-response/](../security/incident-response/) - IR playbooks

---

Last Updated: February 2026
