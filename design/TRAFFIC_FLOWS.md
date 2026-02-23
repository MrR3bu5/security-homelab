# Traffic Flows

Detailed packet flow documentation showing how traffic moves through the homelab infrastructure across different security zones.

## Table of Contents

1. [Overview](#overview)
2. [VPN Connection Flow](#vpn-connection-flow)
3. [Service Access Flows](#service-access-flows)
4. [Lab Access Flow](#lab-access-flow)
5. [Internet Access Flows](#internet-access-flows)
6. [Lab Internal Flows](#lab-internal-flows)
7. [Blocked Traffic Examples](#blocked-traffic-examples)
8. [Troubleshooting Flows](#troubleshooting-flows)

---

## Overview

### Purpose

This document provides step-by-step packet flow analysis for common traffic patterns in the homelab. Each flow shows:
- Source and destination
- Each hop along the path
- Firewall evaluations
- NAT translations (if applicable)
- Expected outcome

### Reading Flow Diagrams

**Format:**

    [Source] → [Hop 1] → [Decision Point] → [Hop 2] → [Destination]

**Symbols:**
- `→` : Packet forwarding
- `✓` : Rule match, ALLOW
- `✗` : Rule match, BLOCK
- `↺` : NAT translation
- `◄─` : Return path

---

## VPN Connection Flow

### 1. VPN Handshake (Connection Establishment)

**Scenario:** VPN client connecting to fw-edge01

**Step-by-Step Flow:**

#### Outbound (Client to Server)

    Step 1: VPN Client initiates connection
    ├─ Source IP: Client's public IP
    ├─ Source Port: Random high port (e.g., 54321)
    ├─ Destination IP: fw-edge01 public IP
    ├─ Destination Port: UDP 51820
    └─ Protocol: UDP

    Step 2: Packet reaches Internet
    ├─ Routing: Via client's default gateway
    ├─ Path: Through ISP network
    └─ No modifications yet

    Step 3: Packet arrives at fw-edge01 WAN interface
    ├─ Interface: WAN (bge1)
    ├─ Firewall evaluation: WAN rules
    │
    ├─ Rule Check 1: Allow UDP 51820?
    │  ├─ Protocol: UDP ✓
    │  ├─ Destination Port: 51820 ✓
    │  ├─ Result: PASS ✓
    │  └─ Log: Connection attempt logged
    │
    └─ Action: Forward to WireGuard process

    Step 4: WireGuard handshake processing
    ├─ Cryptographic handshake initiated
    ├─ Public key validation
    ├─ Session key establishment
    └─ Result: Tunnel established

#### Inbound (Server to Client)

    Step 5: fw-edge01 responds to client
    ├─ Source IP: fw-edge01 public IP
    ├─ Source Port: UDP 51820
    ├─ Destination IP: Client's public IP
    ├─ Destination Port: Client's source port
    └─ Protocol: UDP

    Step 6: Response routed through Internet
    ├─ Stateful firewall: Existing connection ✓
    ├─ Path: Back to client via ISP
    └─ Arrives at client

    Step 7: Client completes handshake
    ├─ Session established
    ├─ Client assigned VPN IP: 10.6.0.x
    └─ Tunnel ready for traffic

**Result:** VPN tunnel established, client has 10.6.0.x address

**Total Latency:** ~20-50ms (handshake overhead)

---

### 2. VPN Keepalive Traffic

**Scenario:** Maintaining VPN connection

**Flow:**

    Every 25 seconds (PersistentKeepalive):
    
    Client (10.6.0.x) → Encrypted keepalive packet → fw-edge01
    ├─ Size: Small (~100 bytes)
    ├─ Purpose: Maintain NAT mapping
    └─ No application data

    fw-edge01 → Response → Client
    ├─ Acknowledges keepalive
    └─ Tunnel stays active

**Purpose:**
- Keep tunnel alive through NAT
- Prevent connection timeout
- Enable immediate communication

---

## Service Access Flows

### 3. VPN Client Accessing Proxmox

**Scenario:** User accessing Proxmox web GUI via VPN

#### Step-by-Step Flow

    Step 1: Client initiates HTTPS connection
    ├─ Source IP: 10.6.0.2 (VPN client)
    ├─ Source Port: Random (e.g., 45678)
    ├─ Destination IP: 192.168.x.241 (Proxmox)
    ├─ Destination Port: 8006
    └─ Protocol: TCP

    Step 2: Packet encrypted by WireGuard
    ├─ Inner packet: 10.6.0.2 → 192.168.x.241:8006
    ├─ Outer packet: Client public IP → fw-edge01 public IP
    ├─ Protocol: UDP 51820
    └─ Encrypted tunnel

    Step 3: Packet arrives at fw-edge01 WAN
    ├─ Interface: WAN
    ├─ Firewall: Existing WireGuard connection ✓
    └─ Forward to WireGuard process

    Step 4: WireGuard decrypts packet
    ├─ Decryption with session key
    ├─ Inner packet extracted: 10.6.0.2 → 192.168.x.241:8006
    └─ Forward to wg0 interface

    Step 5: Firewall evaluation on wg0 interface
    ├─ Interface: WireGuard (wg0)
    ├─ Firewall rules: wg0 interface rules
    │
    ├─ Rule Check: Allow Proxmox?
    │  ├─ Source: 10.6.0.0/24 ✓
    │  ├─ Destination: 192.168.x.241 ✓
    │  ├─ Port: 8006 ✓
    │  ├─ Protocol: TCP ✓
    │  ├─ Result: PASS ✓
    │  └─ Log: Access logged
    │
    └─ Action: Forward to LAN

    Step 6: Routing to Proxmox
    ├─ Source: 10.6.0.2
    ├─ Destination: 192.168.x.241
    ├─ Interface: LAN (bge0)
    └─ Forward to Proxmox host

    Step 7: Proxmox receives packet
    ├─ Connection established
    ├─ HTTPS handshake
    └─ Proxmox GUI responds

#### Return Path

    Step 8: Proxmox response
    ├─ Source IP: 192.168.x.241
    ├─ Source Port: 8006
    ├─ Destination IP: 10.6.0.2
    ├─ Destination Port: 45678
    └─ Protocol: TCP

    Step 9: Routing to fw-edge01
    ├─ Default gateway: 192.168.x.1
    ├─ Arrives at fw-edge01 LAN interface
    └─ Recognized as return traffic

    Step 10: Firewall evaluation (return path)
    ├─ Stateful firewall: Existing connection ✓
    ├─ No rule evaluation needed (established)
    └─ Forward to wg0

    Step 11: WireGuard encryption
    ├─ Inner packet: 192.168.x.241:8006 → 10.6.0.2
    ├─ Encrypt with session key
    └─ Outer packet: fw-edge01 → Client public IP

    Step 12: Send to Internet
    ├─ Interface: WAN
    ├─ Route to client via Internet
    └─ Deliver to VPN client

    Step 13: Client receives packet
    ├─ WireGuard decrypts
    ├─ Inner packet extracted
    └─ Delivered to browser

**Result:** User sees Proxmox GUI in browser

**Total Round-Trip Time:** ~30-60ms (depending on Internet latency)

---

### 4. VPN Client Accessing TrueNAS SMB

**Scenario:** Mounting network share via VPN

#### Connection Flow

    Step 1: SMB connection request
    ├─ Source: 10.6.0.2 (VPN client)
    ├─ Destination: 192.168.x.240:445 (TrueNAS)
    └─ Protocol: TCP

    Step 2: Through VPN tunnel
    ├─ Encrypted by WireGuard
    ├─ Arrives at fw-edge01
    └─ Decrypted to wg0 interface

    Step 3: Firewall evaluation on wg0
    ├─ Interface: WireGuard
    │
    ├─ Rule Check: Allow TrueNAS SMB?
    │  ├─ Source: 10.6.0.0/24 ✓
    │  ├─ Destination: 192.168.x.240 ✓
    │  ├─ Port: 445 ✓
    │  ├─ Protocol: TCP ✓
    │  ├─ Result: PASS ✓
    │  └─ Log: Access logged
    │
    └─ Action: Forward to LAN

    Step 4: TrueNAS receives connection
    ├─ SMB authentication
    ├─ Share permissions check
    └─ Access granted

    Step 5: File access
    ├─ Client: Reads/writes files
    ├─ Path: Client ↔ VPN tunnel ↔ fw-edge01 ↔ TrueNAS
    └─ All traffic encrypted in tunnel

**Result:** Network share mounted and accessible

**Performance:** Limited by VPN upload speed

---

### 5. VPN Client Blocked from fw-edge01 Management

**Scenario:** Attempt to access firewall GUI (should fail)

#### Flow (Blocked)

    Step 1: Client attempts connection
    ├─ Source: 10.6.0.2 (VPN client)
    ├─ Destination: 192.168.x.1:443 (fw-edge01 GUI)
    └─ Protocol: TCP

    Step 2: Through VPN tunnel
    ├─ Encrypted by WireGuard
    ├─ Arrives at fw-edge01
    └─ Decrypted to wg0 interface

    Step 3: Firewall evaluation on wg0
    ├─ Interface: WireGuard
    │
    ├─ Rule Check: Allow fw-edge01 management?
    │  ├─ Check Rule 1 (Proxmox): No match
    │  ├─ Check Rule 2 (TrueNAS HTTPS): No match
    │  ├─ Check Rule 3 (TrueNAS SMB): No match
    │  ├─ Check Rule 4 (Jumphost): No match
    │  ├─ No matching allow rule
    │  ├─ Default policy: DENY
    │  ├─ Result: BLOCK ✗
    │  └─ Log: Denied connection logged
    │
    └─ Action: DROP packet

    Step 4: No response sent
    ├─ Client connection times out
    └─ No access to firewall management

**Result:** Connection blocked, management interface protected

**Security Benefit:** VPN users cannot access firewall configuration

---

## Lab Access Flow

### 6. VPN Client Accessing Lab via Jumphost

**Scenario:** SSH to lab VM through Jumphost

#### Phase 1: VPN to Jumphost

    Step 1: SSH to Jumphost
    ├─ Source: 10.6.0.2 (VPN client)
    ├─ Destination: 192.168.x.67:2222 (Jumphost)
    └─ Protocol: TCP

    Step 2: Through VPN tunnel
    ├─ Encrypted by WireGuard
    ├─ Arrives at fw-edge01
    └─ Decrypted to wg0

    Step 3: Firewall evaluation on wg0
    ├─ Rule Check: Allow Jumphost SSH?
    │  ├─ Source: 10.6.0.0/24 ✓
    │  ├─ Destination: 192.168.x.67 ✓
    │  ├─ Port: 2222 ✓
    │  ├─ Result: PASS ✓
    │  └─ Log: Access logged
    │
    └─ Action: Forward to Jumphost

    Step 4: Jumphost authentication
    ├─ SSH public key authentication
    ├─ User authenticated
    └─ Shell access granted

**Result:** User logged into Jumphost

#### Phase 2: Jumphost to Lab VM

    Step 5: SSH from Jumphost to Lab
    ├─ Source: 192.168.x.67 (Jumphost)
    ├─ Destination: 10.30.66.10 (Kali in lab)
    └─ Protocol: TCP port 22

    Step 6: Routing to fw-lab01
    ├─ Default gateway: 192.168.x.1
    ├─ Static route: 10.30.0.0/16 → fw-lab01 WAN
    └─ Packet reaches fw-lab01 WAN interface

    Step 7: Firewall evaluation on fw-lab01 WAN
    ├─ Interface: WAN (connected to home network)
    │
    ├─ Rule Check: Allow Jumphost to Lab?
    │  ├─ Source: 192.168.x.67 ✓
    │  ├─ Destination: 10.30.0.0/16 ✓
    │  ├─ Port: 22 ✓
    │  ├─ Result: PASS ✓
    │  └─ Log: Access logged
    │
    └─ Action: Forward to Lab LAN

    Step 8: Routing to Lab VLAN
    ├─ Destination: 10.30.66.10
    ├─ VLAN: 66 (Attack segment)
    └─ Forward to VLAN 66

    Step 9: Kali VM receives connection
    ├─ SSH authentication
    ├─ User authenticated
    └─ Shell access granted

**Result:** User logged into Kali VM in lab

#### Complete Path

    VPN Client (10.6.0.2)
      ↓ WireGuard tunnel
    fw-edge01 (wg0 → LAN)
      ↓ Firewall rule: Allow Jumphost
    Jumphost (192.168.x.67)
      ↓ SSH session
    Home Network routing
      ↓ Static route to 10.30.0.0/16
    fw-lab01 (WAN → LAN)
      ↓ Firewall rule: Allow from Jumphost
    Lab VLAN 66
      ↓
    Kali VM (10.30.66.10)

**Security Checkpoints:**
1. VPN authentication (WireGuard)
2. Firewall rule on wg0 (only Jumphost allowed)
3. Jumphost SSH authentication (public key)
4. Firewall rule on fw-lab01 (only from Jumphost)
5. Lab VM SSH authentication

---

### 7. Lab VM Blocked from Reaching Home Network

**Scenario:** Kali VM attempts to reach Proxmox (should fail)

#### Flow (Blocked)

    Step 1: Kali initiates connection
    ├─ Source: 10.30.66.10 (Kali in lab)
    ├─ Destination: 192.168.x.241:8006 (Proxmox)
    └─ Protocol: TCP

    Step 2: Routing to fw-lab01
    ├─ Default gateway: 10.30.66.1 (fw-lab01)
    ├─ Packet reaches fw-lab01 LAN interface
    └─ Destination: 192.168.x.241 (home network)

    Step 3: Firewall evaluation on fw-lab01 LAN
    ├─ Interface: LAN
    │
    ├─ Rule Check: Block Lab to Home?
    │  ├─ Source: 10.30.0.0/16 ✓
    │  ├─ Destination: 192.168.x.0/24 ✓
    │  ├─ Result: BLOCK ✗
    │  └─ Log: Blocked attempt logged
    │
    └─ Action: DROP packet

    Step 4: No response sent
    ├─ Kali connection times out
    └─ Cannot reach home network

**Result:** Lab isolated from production network

**Security Validation:** Lab cannot escape to home network ✓

---

## Internet Access Flows

### 8. Home Network Device to Internet

**Scenario:** Proxmox downloading updates

#### Outbound Flow

    Step 1: Proxmox initiates connection
    ├─ Source: 192.168.x.241 (Proxmox)
    ├─ Source Port: Random (e.g., 54321)
    ├─ Destination: Internet IP (e.g., 1.2.3.4)
    ├─ Destination Port: 443 (HTTPS)
    └─ Protocol: TCP

    Step 2: Routing to gateway
    ├─ Default gateway: 192.168.x.1
    ├─ Packet reaches fw-edge01 LAN interface
    └─ Destination: Internet

    Step 3: Firewall evaluation on LAN
    ├─ Interface: LAN
    ├─ Default LAN rules: Allow outbound
    └─ Result: PASS ✓

    Step 4: NAT translation
    ├─ Source IP: 192.168.x.241 → fw-edge01 public IP ↺
    ├─ Source Port: 54321 → Translated port ↺
    ├─ Destination: Unchanged (1.2.3.4:443)
    └─ State entry created

    Step 5: Send to Internet
    ├─ Interface: WAN
    ├─ Route via ISP
    └─ Arrives at destination

#### Inbound (Return) Flow

    Step 6: Response from Internet
    ├─ Source: 1.2.3.4:443
    ├─ Destination: fw-edge01 public IP:translated port
    └─ Protocol: TCP

    Step 7: Arrives at fw-edge01 WAN
    ├─ Stateful firewall: Existing connection ✓
    ├─ NAT reverse translation
    └─ Destination: 192.168.x.241:54321 ↺

    Step 8: Forward to LAN
    ├─ Interface: LAN
    ├─ Route to Proxmox
    └─ Delivered

**Result:** Proxmox successfully downloads updates

---

### 9. Lab VM to Internet

**Scenario:** Kali downloading tools

#### Outbound Flow

    Step 1: Kali initiates connection
    ├─ Source: 10.30.66.10 (Kali)
    ├─ Destination: Internet (1.2.3.4:443)
    └─ Protocol: TCP

    Step 2: Routing to lab gateway
    ├─ Default gateway: 10.30.66.1 (fw-lab01)
    ├─ Packet reaches fw-lab01 LAN interface
    └─ Destination: Internet

    Step 3: Firewall evaluation on fw-lab01 LAN
    ├─ Interface: LAN
    │
    ├─ Rule Check 1: Block to home network?
    │  ├─ Destination: 1.2.3.4 (not 192.168.x.0/24) ✓
    │  └─ No match, continue
    │
    ├─ Rule Check 2: Allow lab to internet?
    │  ├─ Source: 10.30.0.0/16 ✓
    │  ├─ Destination: any ✓
    │  ├─ Result: PASS ✓
    │  └─ Log: Access logged
    │
    └─ Action: Forward to WAN

    Step 4: Routing to fw-edge01
    ├─ fw-lab01 WAN interface: 192.168.x.[Y]
    ├─ Default route: 192.168.x.1
    ├─ Packet reaches fw-edge01 LAN
    └─ Source: 10.30.66.10 (lab address)

    Step 5: Firewall evaluation on fw-edge01 LAN
    ├─ Interface: LAN
    ├─ Source: 10.30.66.10 (routed from fw-lab01)
    ├─ Destination: Internet
    └─ Result: PASS ✓ (allow outbound)

    Step 6: NAT translation on fw-edge01
    ├─ Source: 10.30.66.10 → fw-edge01 public IP ↺
    ├─ Source port translated
    ├─ State entry created
    └─ Forward to WAN

    Step 7: Send to Internet
    ├─ Routed via ISP
    └─ Arrives at destination

#### Return Flow

    Step 8: Response from Internet
    ├─ Destination: fw-edge01 public IP:translated port
    ├─ Stateful firewall: Existing connection ✓
    └─ NAT reverse: Destination → 10.30.66.10 ↺

    Step 9: Routing back to lab
    ├─ Static route: 10.30.0.0/16 via fw-lab01
    ├─ Forward to fw-lab01 WAN
    └─ fw-lab01 routes to VLAN 66

    Step 10: Delivered to Kali
    └─ Connection complete

**Result:** Kali successfully downloads tools from internet

**Note:** Lab can reach internet but NOT home network

---

## Lab Internal Flows

### 10. Attack VLAN to Server VLAN

**Scenario:** Kali scanning Domain Controller

#### Flow

    Step 1: Kali initiates scan
    ├─ Source: 10.30.66.10 (VLAN 66 - Attack)
    ├─ Destination: 10.30.10.10 (VLAN 10 - Server/DC)
    ├─ Port: 445 (SMB)
    └─ Protocol: TCP

    Step 2: Routing via fw-lab01
    ├─ Gateway: 10.30.66.1 (fw-lab01 VLAN 66 interface)
    ├─ Destination: Different VLAN (10)
    └─ Inter-VLAN routing required

    Step 3: Firewall evaluation (Inter-VLAN)
    ├─ Source VLAN: 66 (Attack)
    ├─ Destination VLAN: 10 (Server)
    │
    ├─ Rule Check: Allow Attack to Server?
    │  ├─ Source: VLAN 66 ✓
    │  ├─ Destination: VLAN 10 ✓
    │  ├─ Result: PASS ✓ (for attack scenarios)
    │  └─ Log: Traffic logged (monitored by Wazuh)
    │
    └─ Action: Forward to VLAN 10

    Step 4: DC receives scan
    ├─ SMB port open
    ├─ Connection established
    └─ Kali performs reconnaissance

**Result:** Attack scenario successful (intended for testing)

**Monitoring:** Wazuh SIEM logs and alerts on suspicious activity

---

### 11. Server VLAN to Client VLAN

**Scenario:** Domain Controller serving Group Policy to workstation

#### Flow

    Step 1: DC pushes GPO
    ├─ Source: 10.30.10.10 (VLAN 10 - DC)
    ├─ Destination: 10.30.20.11 (VLAN 20 - Workstation)
    ├─ Ports: 389 (LDAP), 445 (SMB)
    └─ Protocol: TCP

    Step 2: Inter-VLAN routing via fw-lab01
    ├─ Source VLAN: 10
    ├─ Destination VLAN: 20
    └─ Firewall evaluation

    Step 3: Firewall rules
    ├─ Rule: Allow Server to Client
    │  ├─ Required for normal AD operations
    │  ├─ Result: PASS ✓
    │  └─ Log: Normal traffic (not suspicious)
    │
    └─ Action: Forward to VLAN 20

    Step 4: Workstation receives GPO
    ├─ Applies Group Policy
    └─ Normal operation

**Result:** Active Directory functions normally across VLANs

---

## Blocked Traffic Examples

### 12. VPN Client to Other Home Device (Blocked)

**Scenario:** Attempt to access unauthorized device

    VPN Client (10.6.0.2) attempts: 192.168.x.50:80

    ├─ Encrypted packet arrives at fw-edge01
    ├─ Decrypted to wg0 interface
    ├─ Firewall evaluation on wg0
    │  ├─ Check all allow rules
    │  ├─ No matching rule for 192.168.x.50
    │  ├─ Default policy: DENY
    │  └─ Result: BLOCK ✗
    └─ Packet dropped, logged

**Result:** Access denied, unauthorized host protected

---

### 13. VPN Peer-to-Peer (Blocked)

**Scenario:** VPN client trying to reach another VPN client

    VPN Client 1 (10.6.0.2) attempts: 10.6.0.3:445

    ├─ Encrypted packet arrives at fw-edge01
    ├─ Decrypted to wg0 interface
    ├─ Destination: Another VPN peer
    ├─ Not routed (WireGuard config: no peer-to-peer)
    └─ Result: BLOCK ✗ (by design)

**Result:** VPN clients cannot communicate directly

**Security Benefit:** Compromised VPN client cannot attack other clients

---

### 14. Direct VPN to Lab (Blocked)

**Scenario:** VPN client trying to bypass Jumphost

    VPN Client (10.6.0.2) attempts: 10.30.66.10:22

    ├─ Encrypted packet arrives at fw-edge01
    ├─ Decrypted to wg0 interface
    ├─ Firewall evaluation on wg0
    │  ├─ Destination: 10.30.0.0/16 (lab network)
    │  ├─ No rule allowing VPN → Lab directly
    │  ├─ Only Jumphost is allowed
    │  └─ Result: BLOCK ✗
    └─ Packet dropped, logged

**Result:** Must use Jumphost for lab access (forced path)

---

## Troubleshooting Flows

### Diagnosing Connection Issues

**If cannot connect via VPN to service:**

    1. Check VPN tunnel is up:
       wg show
       # Should show handshake and transfer

    2. Verify routing on client:
       ip route | grep 192.168.x
       # Should route via WireGuard tunnel

    3. Test connectivity from VPN:
       ping 10.6.0.1  # VPN server (should work)
       ping 192.168.x.241  # Service (may be blocked by firewall)

    4. Check firewall logs on fw-edge01:
       # Look for denied connections from 10.6.0.x
       # If denied, rule may be missing

    5. Test from LAN:
       # Connect from home network device
       # If works from LAN but not VPN, it's a firewall rule issue

**If cannot reach lab from Jumphost:**

    1. Check Jumphost can reach fw-lab01:
       ping 192.168.x.[fw-lab01-WAN]
       # Should work (same network)

    2. Check static route exists:
       ip route | grep 10.30.0.0
       # Should show route via fw-lab01

    3. Test from Jumphost:
       ssh user@10.30.66.10
       # If fails, check fw-lab01 rules

    4. Check fw-lab01 logs:
       # Look for blocked connections from 192.168.x.67
       # Verify WAN rules allow from Jumphost

**If lab can reach home network (SHOULD FAIL):**

    1. Test from lab VM:
       ping 192.168.x.241
       # SHOULD TIMEOUT (isolation breach if works)

    2. If it works, CRITICAL SECURITY ISSUE:
       # Check fw-lab01 rules immediately
       # Verify block rule exists for lab → home
       # Review rule priority

    3. Isolation validation:
       # Should fail: ping 192.168.x.1
       # Should fail: curl http://192.168.x.241:8006
       # Should work: ping 8.8.8.8 (internet)

---

## Flow Summary Tables

### Allowed Flows

| Source | Destination | Path | Purpose |
|--------|-------------|------|---------|
| Internet | fw-edge01:51820 | Direct | VPN connection |
| VPN (10.6.0.x) | Proxmox:8006 | VPN → fw-edge01 → LAN | Service access |
| VPN (10.6.0.x) | TrueNAS:443,445 | VPN → fw-edge01 → LAN | Service access |
| VPN (10.6.0.x) | Jumphost:2222 | VPN → fw-edge01 → LAN | Lab access |
| Jumphost | Lab (10.30.x.x) | LAN → fw-lab01 → Lab | Lab management |
| Home devices | Internet | LAN → fw-edge01 → WAN | Internet access |
| Lab VMs | Internet | Lab → fw-lab01 → fw-edge01 → WAN | Updates/tools |
| Lab VLAN 66 | Lab VLAN 10,20 | Via fw-lab01 routing | Attack scenarios |

### Blocked Flows

| Source | Destination | Block Point | Reason |
|--------|-------------|-------------|--------|
| VPN (10.6.0.x) | fw-edge01 mgmt | fw-edge01 wg0 rules | No mgmt via VPN |
| VPN (10.6.0.x) | Other home devices | fw-edge01 wg0 rules | Not explicitly allowed |
| VPN (10.6.0.x) | Lab networks | fw-edge01 wg0 rules | Must use Jumphost |
| VPN peer | VPN peer | WireGuard config | No peer-to-peer |
| Lab (10.30.x.x) | Home (192.168.x.x) | fw-lab01 LAN rules | Lab isolation |
| Lab (10.30.x.x) | fw-edge01 | fw-lab01 LAN rules | Cannot reach edge FW |
| Home devices | Lab (direct) | fw-lab01 WAN rules | Only Jumphost allowed |

---

## Performance Considerations

### Latency Added by Hops

**VPN to Service:**
- VPN encryption/decryption: ~5-10ms
- fw-edge01 processing: ~1-2ms
- Network routing: ~1ms
- Total overhead: ~10-15ms

**VPN to Lab:**
- VPN tunnel: ~5-10ms
- Jumphost SSH: ~2-5ms
- fw-lab01 routing: ~1-2ms
- Total overhead: ~15-20ms

### Throughput Limits

**VPN Performance:**
- Limited by WAN upload speed
- WireGuard overhead: ~5-10%
- Expected: 90-95% of upload speed

**Lab Internet:**
- Double NAT: fw-lab01 → fw-edge01
- Overhead: ~10-15%
- Usually not noticeable for normal use

---

## Related Documentation

- [SECURITY_ZONES.md](SECURITY_ZONES.md) - Security zone definitions
- [NETWORK_TOPOLOGY.md](NETWORK_TOPOLOGY.md) - Network layout
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall design
- [../security/firewall-rules/](../security/firewall-rules/) - Complete firewall configs

---

Last Updated: February 2026
