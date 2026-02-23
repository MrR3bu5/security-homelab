## Network Architecture

### Current Physical Topology

**Network Flow:**

    Internet
       │
       └─── fw-edge01 (Edge Firewall)
               │
               ├─── WAN Interface (DHCP from ISP)
               │
               └─── LAN Interface (192.168.x.1) - VLAN 1
                       │
                       └─── Home Network (Flat - Standard home network)
                               │
                               ├─── Proxmox Host (192.168.x.241)
                               ├─── TrueNAS (192.168.x.240)
                               ├─── Jumphost (192.168.x.67)
                               └─── Other home devices
                                       │
                                       └─── fw-lab01 VM (on Proxmox)
                                               │
                                               └─── Lab Segments (VLANs)
                                                       ├─── VLAN 1: Management (10.30.x.0/24)
                                                       ├─── VLAN 10: Servers (10.30.10.0/24)
                                                       ├─── VLAN 20: Clients (10.30.20.0/24)
                                                       └─── VLAN 66: Attack (10.30.66.0/24)

### Network Design Notes

**Home Network (Production):**
- Current State: Standard flat network (VLAN 1)
- IP Range: 192.168.x.0/24
- Gateway: 192.168.x.1 (fw-edge01)
- Status: Functional for current needs
- Future Enhancement: VLAN segmentation planned for management/production/guest isolation

**Lab Network (Segmented):**
- Implementation: Fully segmented with VLANs
- Gateway: fw-lab01 (10.30.x.1)
- Isolation: Complete separation from home network
- Management: Via fw-lab01 VM running on Proxmox

**Why This Design:**

This architecture represents real-world homelab evolution:
1. Started with working flat network (like most homelabs)
2. Prioritized lab segmentation first (where attacks happen)
3. Production network functional and secure via fw-edge01
4. Allows incremental improvement without disruption

**Planned Upgrades:**
- Home network VLAN segmentation (management, production, guest)
- Managed switch for home network
- Further isolation of production services

---

## IP Addressing

### Home Network (Green Zone)

Network: 192.168.x.0/24  
Gateway: 192.168.x.1 (fw-edge01)

| Device | IP | Purpose |
|--------|-----|---------|
| fw-edge01 | 192.168.x.1 | Gateway and firewall |
| Proxmox | 192.168.x.241 | Virtualization host |
| TrueNAS | 192.168.x.240 | Storage server |
| Jumphost | 192.168.x.67 | Lab access point |
| Home devices | DHCP range | General network devices |

Current State: Flat network (VLAN 1)  
Security: Protected by fw-edge01 with service-level access rules  
Future: VLAN segmentation for enhanced isolation

### VPN Tunnel (Yellow Zone)

Network: 10.6.0.0/24  
Gateway: 10.6.0.1 (fw-edge01 wg0 interface)

| Host | IP | Purpose |
|------|-----|---------|
| fw-edge01 wg0 | 10.6.0.1 | VPN server |
| VPN clients | 10.6.0.2+ | Remote devices |

### Lab Networks (Blue Zone)

Management by: fw-lab01 VM  
Physical Host: Proxmox (192.168.x.241)  
Isolation: Firewalled from home network

#### VLAN 1: Management
- Network: 10.30.x.0/24
- Gateway: 10.30.x.1 (fw-lab01)
- Purpose: Firewall and switch management
- Access: Restricted to jumphost only

#### VLAN 10: Server Segment
- Network: 10.30.10.0/24
- Gateway: 10.30.10.1 (fw-lab01)
- Purpose: Server infrastructure
- Systems:
  - Domain Controller (Active Directory)
  - SQL Server
  - Web Application servers
  - Wazuh (SIEM/Security monitoring)

#### VLAN 20: Client Segment
- Network: 10.30.20.0/24
- Gateway: 10.30.20.1 (fw-lab01)
- Purpose: Client machines
- Systems:
  - Windows workstations
  - Linux desktop systems
  - Test client environments

#### VLAN 66: Attack Segment
- Network: 10.30.66.0/24
- Gateway: 10.30.66.1 (fw-lab01)
- Purpose: Offensive security tools
- Systems:
  - Kali Linux
  - Parrot Security OS
  - Windows attack clients
  - Red team infrastructure

**Segmentation Purpose:**
- Server VLAN (10): Victim infrastructure for attacks
- Client VLAN (20): Target endpoints for exploitation
- Attack VLAN (66): Offensive tools isolated from targets
- Management VLAN (1): Secure firewall access

---

## Security Architecture

### Current Security Model

**Layer 1: Perimeter (fw-edge01)**
- Single exposed port: UDP 51820 (WireGuard)
- All other inbound traffic blocked
- Outbound NAT for home network
- Stateful packet inspection

**Layer 2: VPN Authentication**
- WireGuard public key cryptography
- No password-based VPN access
- Authenticated clients get 10.6.0.0/24 addresses
- Split-tunnel configuration

**Layer 3: Service-Level Access Control**
- Firewall rules on fw-edge01 wg0 interface
- Explicit allow rules for:
  - Proxmox (192.168.x.241:8006)
  - TrueNAS (192.168.x.240:443, :445)
  - Jumphost (192.168.x.67:2222)
- All other access implicitly denied

**Layer 4: Lab Isolation (fw-lab01)**
- VM firewall on Proxmox
- Dedicated firewall for lab segments
- WAN side: Connected to home network (192.168.x.0/24)
- LAN side: Lab segments (10.30.0.0/16)
- Default DENY: Lab cannot reach home network
- Controlled access: Jumphost can reach lab

**Layer 5: Application Security**
- SSH key authentication on Jumphost
- Individual service authentication (Proxmox, TrueNAS)
- Lab systems: Various security levels (intentional)

### Trust Boundaries

**Boundary 1: Internet → fw-edge01**
- Control: WAN firewall rules
- Only WireGuard allowed inbound
- All else blocked and logged

**Boundary 2: VPN → Home Network**
- Control: wg0 interface rules on fw-edge01
- Service-level explicit allow rules
- No management interface access
- No unauthorized host access

**Boundary 3: Home Network → Lab**
- Control: fw-lab01 WAN interface rules
- Lab can receive from jumphost only
- Lab cannot initiate to home network
- Complete isolation enforced

**Boundary 4: Lab Internal (Between VLANs)**
- Control: fw-lab01 internal rules
- Attack VLAN can reach Server/Client VLANs (simulation)
- Management VLAN restricted
- Configurable for scenarios

### Why Home Network is Flat (For Now)

**Current Security Posture:**
- fw-edge01 provides perimeter defense
- Service-level rules on VPN interface
- No direct internet exposure of services
- Lab completely isolated via fw-lab01

**Security is Adequate Because:**
1. No services exposed to internet
2. VPN provides authentication layer
3. Explicit service rules prevent lateral movement
4. Lab isolation prevents compromise propagation
5. All home devices trusted (personal network)

**Planned Improvements:**
- Add managed switch to home network
- Implement VLANs:
  - VLAN 10: Management (firewall, switch)
  - VLAN 20: Production (Proxmox, TrueNAS)
  - VLAN 30: Lab WAN (fw-lab01 connection)
  - VLAN 40: Guest network (visitors)
- Further isolation of production services
- Enhanced monitoring per segment

**Why Not Done Yet:**
- Requires managed switch purchase
- Current design is functional and secure
- Lab (where attacks happen) is already segmented
- Incremental improvement approach

---

## Lab Architecture Details

### Lab Segmentation Strategy

**Purpose of Each VLAN:**

**VLAN 1 (Management - 10.30.x.0/24):**
- fw-lab01 management interface
- Lab switch management (if applicable)
- Access restricted to jumphost
- Critical for lab administration

**VLAN 10 (Server - 10.30.10.0/24):**
- Active Directory Domain Controller
- SQL Server (for web app vulnerabilities)
- Web Application servers (intentionally vulnerable)
- Wazuh SIEM (for blue team practice)
- Role: Victim infrastructure

**VLAN 20 (Client - 10.30.20.0/24):**
- Windows workstations (domain-joined)
- Linux desktop systems
- Various client OS versions
- Role: Target endpoints for exploitation

**VLAN 66 (Attack - 10.30.66.0/24):**
- Kali Linux (primary attack platform)
- Parrot Security OS (alternative platform)
- Windows attack clients (for AD attacks)
- Red team C2 infrastructure
- Role: Offensive tools and techniques

### Lab Use Cases

**Red Team Scenarios:**
1. External Penetration: Attack from VLAN 66 to Server/Client VLANs
2. Lateral Movement: Compromise client, pivot to servers
3. Active Directory Attacks: Kerberoasting, Pass-the-Hash, etc.
4. Web Application Testing: SQL injection, XSS on VLAN 10 apps
5. Ransomware Simulation: Deploy and detect in safe environment

**Blue Team Scenarios:**
1. SIEM Monitoring: Wazuh detects attacks from VLAN 66
2. Incident Response: Practice forensics on compromised systems
3. Detection Engineering: Create rules for specific attacks
4. Log Analysis: Correlate events across VLANs

**HackTheBox Pro Labs:**
- Deploy HackTheBox VPN on VLAN 66
- Practice Dante, Expressway, etc.
- Isolated from home network
- Can reset/snapshot for retries

### Lab Isolation Enforcement

**fw-lab01 Rules:**

**WAN to LAN (Home to Lab):**
- Source: 192.168.x.67 (Jumphost)
- Destination: 10.30.x.0/16 (Lab networks)
- Ports: SSH (22), RDP (3389), management ports
- Action: ALLOW (controlled access)

**WAN to LAN (Everything Else):**
- Source: 192.168.x.0/24 (Home network)
- Destination: 10.30.x.0/16 (Lab)
- Action: BLOCK (no unauthorized access)

**LAN to WAN (Lab to Home):**
- Source: 10.30.x.0/16 (Lab networks)
- Destination: 192.168.x.0/24 (Home)
- Action: BLOCK (lab cannot reach production)

**LAN to WAN (Lab to Internet):**
- Source: 10.30.x.0/16 (Lab)
- Destination: Internet
- Action: ALLOW (for updates, tools) with filtering

**LAN to LAN (Between Lab VLANs):**
- Configurable based on scenario
- Typically allow Attack to Server/Client
- Restrict Management VLAN access

### Access Path to Lab

**From VPN to Lab:**

    VPN Client (10.6.0.2)
      ↓
    fw-edge01 (VPN rules)
      ↓ ALLOW to Jumphost :2222
    Home Network (192.168.x.67)
      ↓ Jumphost
      ↓ SSH connection
    fw-lab01 (WAN side)
      ↓ fw-lab01 rules: Allow jumphost
    Lab Networks (10.30.x.0/16)
      ↓
    Specific lab systems

**Security Checkpoints:**
1. VPN authentication (WireGuard keys)
2. fw-edge01 firewall rule (explicit allow to Jumphost)
3. Jumphost SSH authentication (keys only)
4. fw-lab01 firewall rule (allow from jumphost)
5. Target system authentication (if applicable)

---

## Design Evolution

### Version 1.0 (Initial Setup)
- Basic home network
- Proxmox installed
- No VPN
- Direct service access (insecure)

### Version 2.0 (VPN Implementation)
- Added WireGuard VPN
- Service-level firewall rules
- Reduced attack surface
- No lab isolation yet

### Version 3.0 (Lab Isolation - Current)
- Deployed fw-lab01 VM
- Created lab VLANs (1, 10, 20, 66)
- Complete lab isolation
- Active Directory deployment
- Wazuh SIEM for monitoring

### Version 4.0 (Planned - Home Network Segmentation)
- Purchase managed switch
- Implement home network VLANs
- Further isolate production services
- Enhanced monitoring per segment

### Version 5.0 (Future - Advanced Monitoring)
- SIEM integration for home network
- Network tap for passive monitoring
- Automated threat detection
- Enhanced incident response

---

## Current vs Ideal State

### What's Production-Ready ✅

**fw-edge01 (Edge Firewall):**
- Solid perimeter defense
- WireGuard VPN working perfectly
- Service-level access control
- Complete logging

**VPN Access:**
- Zero-trust model implemented
- Explicit service rules
- No management exposure
- Validated and documented

**Lab Isolation:**
- Complete segmentation (4 VLANs)
- Proper firewall rules
- Cannot reach production
- Safe for aggressive testing

### What's "Homelab Good Enough" 🟡

**Home Network:**
- Flat network (VLAN 1)
- All devices on same subnet
- Adequate for personal use
- Planned improvement with VLANs

**Monitoring:**
- Basic logging enabled
- Manual log review
- No central SIEM for home network
- Wazuh in lab only

### What's Planned 🔮

**Short-Term (Next 3 months):**
- Document lab scenarios and playbooks
- Expand Wazuh monitoring
- Create automated health checks
- More lab attack/defense scenarios

**Medium-Term (6 months):**
- Purchase managed switch
- Implement home network VLANs
- Segregate production services
- Add monitoring for home network

**Long-Term (12 months):**
- Full stack observability
- Automated threat detection
- High availability for critical services
- Advanced lab environments
