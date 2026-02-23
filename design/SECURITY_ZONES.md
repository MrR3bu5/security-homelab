# Security Zones

Comprehensive documentation of trust boundaries, security zones, and access controls in the homelab infrastructure.

## Table of Contents

1. [Overview](#overview)
2. [Zone Definitions](#zone-definitions)
3. [Trust Boundaries](#trust-boundaries)
4. [Access Control Matrix](#access-control-matrix)
5. [Firewall Rules](#firewall-rules)
6. [Isolation Enforcement](#isolation-enforcement)
7. [Threat Model](#threat-model)
8. [Security Controls](#security-controls)

---

## Overview

### Security Zone Model

The homelab implements a four-zone security architecture based on trust levels and threat exposure:

**Zone Colors:**
- 🔴 **Red Zone**: Untrusted (Internet/WAN)
- 🟡 **Yellow Zone**: Semi-Trusted (VPN Tunnel)
- 🟢 **Green Zone**: Trusted (Home Network)
- 🔵 **Blue Zone**: Isolated (Lab Environment)

### Trust Model

**Zero Trust Principles:**
- No implicit trust based on network location
- Authentication required at multiple layers
- Service-level access control
- Continuous verification and monitoring

**Defense in Depth:**
Multiple independent security layers protect each zone.

---

## Zone Definitions

### 🔴 Red Zone: Internet/WAN

**Network:** Public Internet  
**Trust Level:** NONE  
**Threat Level:** HIGH  
**Access:** Outbound only (with exceptions)

**Characteristics:**
- Completely untrusted environment
- Hostile actors assumed
- No control over traffic
- Default deny all inbound

**Connected To:**
- fw-edge01 WAN interface

**Purpose:**
- Internet connectivity
- External service access
- VPN endpoint exposure

**Security Posture:**
- Single exposed port: UDP 51820 (WireGuard)
- All other inbound traffic blocked
- Stateful packet inspection
- Attack traffic logged

---

### 🟡 Yellow Zone: VPN Tunnel

**Network:** 10.6.0.0/24  
**Trust Level:** LIMITED  
**Threat Level:** MEDIUM  
**Access:** Authenticated but restricted

**Characteristics:**
- Cryptographically authenticated users
- Service-level access control only
- No network-level trust granted
- Cannot reach firewall management
- No peer-to-peer VPN traffic

**Connected To:**
- fw-edge01 wg0 interface (10.6.0.1)
- Allowed services in Green Zone

**Purpose:**
- Remote access to specific services
- Secure tunnel from untrusted networks
- Authentication layer before service access

**Security Posture:**
- WireGuard public key authentication
- Explicit allow-list per service
- No lateral movement capability
- All access logged

**Allowed Access:**
- Proxmox (192.168.x.241:8006)
- TrueNAS HTTPS (192.168.x.240:443)
- TrueNAS SMB (192.168.x.240:445)
- Jumphost SSH (192.168.x.67:2222)

**Blocked Access:**
- fw-edge01 management interfaces
- Other home network devices
- Direct lab network access
- VPN client-to-client communication

---

### 🟢 Green Zone: Home Network

**Network:** 192.168.x.0/24  
**Trust Level:** HIGH  
**Threat Level:** LOW  
**Access:** Trusted devices only

**Characteristics:**
- Personal devices and infrastructure
- Production services located here
- No direct internet exposure
- Protected by fw-edge01

**Connected To:**
- fw-edge01 LAN interface (192.168.x.1)
- All home devices and servers

**Purpose:**
- Production infrastructure hosting
- General home network use
- Secure service platform

**Security Posture:**
- No services exposed to internet
- VPN required for remote access
- Lab isolated from this network
- All devices trusted (personal network)

**Key Services:**
- Proxmox (192.168.x.241)
- TrueNAS (192.168.x.240)
- Jumphost (192.168.x.67)
- General home devices

**Current State:**
- Flat network (VLAN 1)
- All devices on same subnet
- Adequate for current threat model
- VLANs planned for future

---

### 🔵 Blue Zone: Lab Environment

**Network:** 10.30.0.0/16  
**Trust Level:** NONE  
**Threat Level:** HIGH (Intentional)  
**Access:** Strictly controlled

**Characteristics:**
- Intentionally vulnerable systems
- Attack tools and malware present
- Assumed compromised at all times
- Complete isolation from production

**Connected To:**
- fw-lab01 (isolation firewall)
- Lab segments via VLANs

**Purpose:**
- Red team operations
- Security research and testing
- Attack/defense practice
- Safe malware analysis

**Security Posture:**
- Cannot initiate to Green Zone
- Cannot reach fw-edge01
- Accessed via Jumphost only
- All activity monitored

**Lab Segments:**

#### VLAN 1: Management (10.30.x.0/24)
- fw-lab01 management interface
- Lab infrastructure control
- Restricted access from Jumphost

#### VLAN 10: Server (10.30.10.0/24)
- Active Directory Domain Controller
- SQL Server
- Web application servers
- Wazuh SIEM
- Role: Victim infrastructure

#### VLAN 20: Client (10.30.20.0/24)
- Windows workstations
- Linux desktops
- Domain-joined machines
- Role: Target endpoints

#### VLAN 66: Attack (10.30.66.0/24)
- Kali Linux
- Parrot Security OS
- Windows attack clients
- C2 infrastructure
- Role: Offensive tools

---

## Trust Boundaries

### Boundary 1: Internet ↔ fw-edge01 (Red → All)

**Control Point:** fw-edge01 WAN interface  
**Direction:** Inbound from Internet  
**Default Policy:** DENY ALL

**Enforcement:**
- WAN firewall rules
- Stateful packet inspection
- Connection logging

**Allowed Traffic:**
- UDP 51820 → fw-edge01 (WireGuard VPN)

**Blocked Traffic:**
- ALL other inbound connections
- Port scans logged
- Attack attempts logged

**Security Controls:**
- Stateful firewall
- DDoS protection (basic)
- Dynamic DNS with Cloudflare
- Fail2ban (optional)

---

### Boundary 2: VPN ↔ Home Network (Yellow → Green)

**Control Point:** fw-edge01 wg0 interface  
**Direction:** From VPN to Home Network  
**Default Policy:** DENY ALL (explicit allow only)

**Enforcement:**
- wg0 interface firewall rules
- Service-level access control
- Connection state tracking

**Allowed Traffic:**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| 10.6.0.0/24 | 192.168.x.241 | 8006 | TCP | Proxmox GUI |
| 10.6.0.0/24 | 192.168.x.240 | 443 | TCP | TrueNAS HTTPS |
| 10.6.0.0/24 | 192.168.x.240 | 445 | TCP | TrueNAS SMB |
| 10.6.0.0/24 | 192.168.x.67 | 2222 | TCP | Jumphost SSH |

**Blocked Traffic:**
- fw-edge01 management (SSH :22, GUI :10443)
- Other home network hosts
- Broadcast/multicast traffic
- VPN peer-to-peer traffic

**Security Controls:**
- Explicit allow rules only
- No management interface access
- No default allow rule
- All denied traffic logged

---

### Boundary 3: Home Network ↔ Lab (Green → Blue)

**Control Point:** fw-lab01 WAN interface  
**Direction:** Bidirectional (strict control)  
**Default Policy:** DENY (lab cannot reach home)

**Enforcement:**
- fw-lab01 firewall rules
- Separate firewall instance
- Complete network isolation

**Home to Lab (Allowed):**

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| 192.168.x.67 | 10.30.0.0/16 | 22 | TCP | Jumphost SSH to lab |
| 192.168.x.67 | 10.30.0.0/16 | 3389 | TCP | Jumphost RDP to lab |
| 192.168.x.67 | 10.30.0.0/16 | Various | TCP/UDP | Management ports |

**Lab to Home (Blocked):**

| Source | Destination | Action | Reason |
|--------|-------------|--------|--------|
| 10.30.0.0/16 | 192.168.x.0/24 | BLOCK | Lab cannot reach production |
| 10.30.0.0/16 | fw-edge01 | BLOCK | Lab cannot reach edge firewall |
| 10.30.0.0/16 | Internet | ALLOW | Updates and tools (filtered) |

**Security Controls:**
- Dedicated isolation firewall
- No reverse access allowed
- Jumphost as only entry point
- Lab assumed compromised

---

### Boundary 4: Lab Internal (Blue VLANs)

**Control Point:** fw-lab01 internal routing  
**Direction:** Between lab VLANs  
**Default Policy:** Configurable per scenario

**Enforcement:**
- Inter-VLAN firewall rules
- Scenario-based policies
- Attack simulation support

**Typical Configuration:**

| Source | Destination | Action | Purpose |
|--------|-------------|--------|---------|
| VLAN 66 (Attack) | VLAN 10 (Server) | ALLOW | Attack scenarios |
| VLAN 66 (Attack) | VLAN 20 (Client) | ALLOW | Attack scenarios |
| VLAN 10 (Server) | VLAN 20 (Client) | ALLOW | Normal operations |
| VLAN 1 (Management) | ALL | Restricted | Secure management |

**Security Controls:**
- Flexible rules for scenarios
- Management VLAN protected
- Wazuh monitoring all traffic
- Easy rule modification

---

## Access Control Matrix

### VPN Client Access

**What VPN Clients CAN Access:**

| Service | IP:Port | Protocol | Authentication | Purpose |
|---------|---------|----------|----------------|---------|
| Proxmox | 192.168.x.241:8006 | HTTPS | Username/Password + 2FA | VM management |
| TrueNAS Web | 192.168.x.240:443 | HTTPS | Username/Password | Storage management |
| TrueNAS SMB | 192.168.x.240:445 | SMB | Username/Password | File access |
| Jumphost | 192.168.x.67:2222 | SSH | Public key only | Lab access |

**What VPN Clients CANNOT Access:**

| Service | Reason | Alternative |
|---------|--------|-------------|
| fw-edge01 SSH | Security (no mgmt via VPN) | Access from LAN only |
| fw-edge01 GUI | Security (no mgmt via VPN) | Access from LAN only |
| Other home devices | Not explicitly allowed | Add firewall rule if needed |
| Lab networks directly | Must use Jumphost | SSH through Jumphost |
| Other VPN clients | No peer-to-peer | By design |

### Jumphost Access

**What Jumphost CAN Access:**

| Destination | Port | Protocol | Purpose |
|-------------|------|----------|---------|
| All lab VLANs | 22 | SSH | Linux administration |
| All lab VLANs | 3389 | RDP | Windows administration |
| fw-lab01 | 443 | HTTPS | Firewall management |
| Lab VMs | Various | TCP/UDP | Service management |

**What Jumphost CANNOT Access:**

| Destination | Reason |
|-------------|--------|
| fw-edge01 management | Not necessary (different network) |
| Home network devices | Purpose is lab access only |

### Lab Network Access

**What Lab CAN Access:**

| Destination | Purpose | Filtering |
|-------------|---------|-----------|
| Internet | Updates, tools | Filtered by fw-lab01 |
| DNS resolution | Name lookups | Allowed |

**What Lab CANNOT Access:**

| Destination | Reason | Enforcement |
|-------------|--------|-------------|
| Home network (192.168.x.0/24) | Isolation | fw-lab01 blocks |
| fw-edge01 | Security | fw-lab01 blocks |
| VPN tunnel | Not routable | Network design |

---

## Firewall Rules

### fw-edge01: WAN Interface

**Purpose:** Perimeter defense

**Rule Priority:** Top to bottom (first match wins)

#### Rule 1: Allow WireGuard VPN

    Action: PASS
    Interface: WAN
    Protocol: UDP
    Source: any
    Destination: WAN address
    Destination Port: 51820
    Description: Allow WireGuard VPN connections
    Log: Yes

#### Rule 2: Block Everything Else (Implicit)

    Action: BLOCK
    Interface: WAN
    Protocol: any
    Source: any
    Destination: any
    Description: Default deny all inbound
    Log: Yes

### fw-edge01: WireGuard Interface

**Purpose:** Service-level access control

**Rule Priority:** Top to bottom (first match wins)

#### Rule 1: Allow Proxmox

    Action: PASS
    Interface: WireGuard
    Protocol: TCP
    Source: 10.6.0.0/24
    Destination: 192.168.x.241
    Destination Port: 8006
    Description: VPN to Proxmox GUI
    Log: Yes

#### Rule 2: Allow TrueNAS HTTPS

    Action: PASS
    Interface: WireGuard
    Protocol: TCP
    Source: 10.6.0.0/24
    Destination: 192.168.x.240
    Destination Port: 443
    Description: VPN to TrueNAS HTTPS
    Log: Yes

#### Rule 3: Allow TrueNAS SMB

    Action: PASS
    Interface: WireGuard
    Protocol: TCP
    Source: 10.6.0.0/24
    Destination: 192.168.x.240
    Destination Port: 445
    Description: VPN to TrueNAS SMB
    Log: Yes

#### Rule 4: Allow Jumphost SSH

    Action: PASS
    Interface: WireGuard
    Protocol: TCP
    Source: 10.6.0.0/24
    Destination: 192.168.x.67
    Destination Port: 2222
    Description: VPN to Jumphost SSH
    Log: Yes

#### Rule 5: Block Everything Else (Implicit)

    Action: BLOCK
    Interface: WireGuard
    Protocol: any
    Source: any
    Destination: any
    Description: Deny all other VPN traffic
    Log: Yes

### fw-lab01: WAN Interface

**Purpose:** Lab isolation from home network

**Rule Priority:** Top to bottom (first match wins)

#### Rule 1: Allow Jumphost to Lab

    Action: PASS
    Interface: WAN
    Protocol: TCP/UDP
    Source: 192.168.x.67
    Destination: 10.30.0.0/16
    Destination Port: 22, 3389, 443, others
    Description: Allow Jumphost to lab management
    Log: Yes

#### Rule 2: Block Home Network to Lab

    Action: BLOCK
    Interface: WAN
    Protocol: any
    Source: 192.168.x.0/24
    Destination: 10.30.0.0/16
    Description: Block other home devices from lab
    Log: Yes

#### Rule 3: Allow Lab to Internet

    Action: PASS
    Interface: WAN
    Protocol: TCP/UDP
    Source: 10.30.0.0/16
    Destination: !192.168.x.0/24
    Description: Allow lab internet access (not home network)
    Log: Yes

### fw-lab01: LAN Interface

**Purpose:** Lab internal access and internet routing

**Rule Priority:** Top to bottom (first match wins)

#### Rule 1: Block Lab to Home Network

    Action: BLOCK
    Interface: LAN
    Protocol: any
    Source: 10.30.0.0/16
    Destination: 192.168.x.0/24
    Description: Prevent lab from reaching production
    Log: Yes

#### Rule 2: Allow Lab Internal Traffic

    Action: PASS
    Interface: LAN
    Protocol: any
    Source: 10.30.0.0/16
    Destination: 10.30.0.0/16
    Description: Allow inter-VLAN routing (configurable)
    Log: No (too verbose)

#### Rule 3: Allow Lab to Internet

    Action: PASS
    Interface: LAN
    Protocol: any
    Source: 10.30.0.0/16
    Destination: any
    Description: Allow lab internet for updates
    Log: Yes

---

## Isolation Enforcement

### Lab Isolation Mechanisms

**Network Layer:**
- Separate firewall (fw-lab01)
- Different IP addressing (10.30.0.0/16 vs 192.168.x.0/24)
- No routing from lab to home

**Firewall Layer:**
- Explicit block rules on fw-lab01
- No reverse access allowed
- Internet access filtered

**Access Layer:**
- Only Jumphost can reach lab
- No direct VPN to lab
- SSH key authentication required

### Testing Isolation

**From Lab VM, these should FAIL:**

    ping 192.168.x.1          # Cannot reach fw-edge01
    ping 192.168.x.241        # Cannot reach Proxmox
    ping 192.168.x.240        # Cannot reach TrueNAS
    ssh user@192.168.x.67     # Cannot reach Jumphost
    curl http://192.168.x.1   # Cannot reach any home host

**From Lab VM, these should SUCCEED:**

    ping 8.8.8.8              # Can reach internet
    ping 10.30.10.10          # Can reach other lab VLANs
    curl http://google.com    # Can access internet

**From Home Network, these should FAIL:**

    ping 10.30.10.10          # Cannot reach lab (except Jumphost)
    ssh user@10.30.66.10      # Cannot access lab VMs

**From Jumphost, these should SUCCEED:**

    ssh user@10.30.10.10      # Can reach lab servers
    ssh user@10.30.66.10      # Can reach attack VMs
    https://10.30.x.1         # Can manage fw-lab01

---

## Threat Model

### External Threats

**Threat:** Port scanning and reconnaissance

**Attack Vector:** Internet to WAN interface  
**Mitigation:**
- Single exposed port (UDP 51820)
- All other ports blocked
- Scanning attempts logged
- No service version disclosure

**Risk Level:** LOW (minimal attack surface)

---

**Threat:** Brute force on VPN

**Attack Vector:** Repeated WireGuard handshake attempts  
**Mitigation:**
- Public key authentication (no passwords)
- Cryptographically secure handshake
- No user enumeration possible
- Rate limiting (optional)

**Risk Level:** VERY LOW (cryptographic authentication)

---

**Threat:** Zero-day in WireGuard

**Attack Vector:** Exploit in VPN software  
**Mitigation:**
- Modern, audited codebase
- Small attack surface
- Regular updates
- Limited blast radius (service-level rules)

**Risk Level:** LOW (but monitor for CVEs)

---

### Insider Threats

**Threat:** Compromised VPN credentials

**Attack Vector:** Stolen VPN client keys  
**Mitigation:**
- Limited to specific services only
- No management interface access
- No lateral movement capability
- Complete access logging

**Risk Level:** MEDIUM (limited blast radius)

**Response:**
1. Revoke compromised peer on fw-edge01
2. Review logs for unauthorized access
3. Issue new keys to legitimate user

---

**Threat:** Compromised Jumphost

**Attack Vector:** Stolen SSH keys or exploit  
**Mitigation:**
- Lab is assumed hostile anyway
- Cannot reach production from lab
- SSH key rotation
- MFA on Jumphost (planned)

**Risk Level:** MEDIUM (lab access but isolated)

**Response:**
1. Isolate Jumphost from network
2. Review lab access logs
3. Rebuild Jumphost from clean image
4. Rotate all SSH keys

---

### Lab-Specific Threats

**Threat:** Lab malware escaping to production

**Attack Vector:** Network-based propagation  
**Mitigation:**
- fw-lab01 blocks all lab to home traffic
- Dedicated isolation firewall
- No routing path exists
- Regular testing of isolation

**Risk Level:** VERY LOW (strict enforcement)

**Validation:**
- Test isolation regularly
- Attempt to reach home network from lab
- Should fail 100% of the time

---

**Threat:** Accidental compromise of production

**Attack Vector:** Misconfigured firewall rule  
**Mitigation:**
- Default deny on all interfaces
- Explicit rules only
- Rule review process
- Validation scripts

**Risk Level:** LOW (defense in depth)

**Prevention:**
- Document all rule changes
- Test rules before production
- Use validation scripts
- Regular security audits

---

## Security Controls

### Authentication

**Layer 1: VPN Authentication**
- Mechanism: WireGuard public key cryptography
- Strength: Cryptographically secure
- Bypass: Not possible without private key

**Layer 2: Service Authentication**
- Proxmox: Username/password (2FA available)
- TrueNAS: Username/password (2FA available)
- Jumphost: SSH public key only (no passwords)

**Layer 3: Lab Access**
- Jumphost SSH: Public key authentication
- Lab VMs: Various (intentionally vulnerable in some cases)

### Authorization

**Network Level:**
- Firewall rules define what can be accessed
- Explicit allow-list model
- No implicit trust

**Service Level:**
- Role-based access control (Proxmox, TrueNAS)
- User permissions per service
- Principle of least privilege

**Lab Level:**
- Controlled access via Jumphost
- No direct network access
- Monitored by Wazuh SIEM

### Logging and Monitoring

**What's Logged:**
- All VPN connections and disconnections
- All firewall allow/deny decisions
- All service access attempts
- SSH access to Jumphost
- Lab activity (via Wazuh)

**Log Retention:**
- Firewall logs: 30 days (rotating)
- Service logs: 90 days
- Security events: 1 year
- Access logs: 1 year

**Monitoring:**
- Manual log review (current)
- Automated alerting (planned)
- SIEM for lab (Wazuh active)
- SIEM for home network (planned)

### Incident Response

**Detection:**
- Log analysis
- Anomaly detection
- Wazuh alerts (lab)
- Manual observation

**Response Procedures:**

**If VPN compromise suspected:**
1. Disable affected peer on fw-edge01
2. Review logs for unauthorized access
3. Check accessed services for signs of compromise
4. Issue new keys to legitimate user

**If Jumphost compromise suspected:**
1. Isolate from network (disable interface)
2. Review lab access logs
3. Check lab VMs for suspicious activity
4. Rebuild Jumphost from clean image
5. Rotate all SSH keys

**If lab escape suspected:**
1. Verify fw-lab01 rules are correct
2. Check fw-edge01 logs for lab source traffic
3. Isolate lab network completely
4. Investigate compromise vector
5. Rebuild lab environment if needed

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture design
- [NETWORK_TOPOLOGY.md](NETWORK_TOPOLOGY.md) - Network layout details
- [TRAFFIC_FLOWS.md](TRAFFIC_FLOWS.md) - Packet routing through zones
- [THREAT_MODEL.md](THREAT_MODEL.md) - Detailed threat analysis
- [../security/firewall-rules/](../security/firewall-rules/) - Complete firewall configs

---

Last Updated: February 2026
