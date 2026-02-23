# Network Topology

Detailed network design documentation for the security homelab infrastructure.

## Table of Contents

1. [Overview](#overview)
2. [Physical Topology](#physical-topology)
3. [Logical Topology](#logical-topology)
4. [IP Addressing](#ip-addressing)
5. [VLAN Design](#vlan-design)
6. [Routing](#routing)
7. [Network Services](#network-services)
8. [Firewall Placement](#firewall-placement)
9. [Connection Details](#connection-details)

---

## Overview

### Network Architecture Summary

The homelab network consists of two distinct environments:

**Home Network (Production):**
- Standard flat network configuration
- Network: 192.168.x.0/24
- Gateway: fw-edge01 (192.168.x.1)
- Purpose: Production services and general home use

**Lab Network (Isolated):**
- Fully segmented with VLANs
- Network: 10.30.0.0/16
- Gateway: fw-lab01 (VM on Proxmox)
- Purpose: Red team operations and security research

### Design Philosophy

**Separation of Concerns:**
- Production network kept simple and functional
- Lab network fully segmented for attack/defense scenarios
- Complete isolation between environments

**Security First:**
- Lab cannot reach production network
- All access controlled by firewalls
- Multiple trust boundaries enforced

**Incremental Improvement:**
- Started with working flat network
- Prioritized lab segmentation (where attacks happen)
- Home network VLANs planned for future

---

## Physical Topology

### Network Diagram

    Internet (ISP)
       │
       │ WAN Connection (DHCP)
       │
    ┌──▼────────────────┐
    │   fw-edge01       │ Edge Firewall
    │  (192.168.x.1)    │
    └──┬────────────────┘
       │
       │ LAN Interface
       │
    ┌──▼────────────────────────────────────────┐
    │  Home Network (Flat - VLAN 1)             │
    │  192.168.x.0/24                           │
    │                                           │
    │  ┌──────────┐  ┌──────────┐  ┌─────────┐│
    │  │ Proxmox  │  │ TrueNAS  │  │Jumphost ││
    │  │  .241    │  │  .240    │  │  .67    ││
    │  └────┬─────┘  └──────────┘  └─────────┘│
    │       │                                   │
    └───────┼───────────────────────────────────┘
            │
            │ VM Network
            │
    ┌───────▼───────────────────────┐
    │   fw-lab01 (VM)               │
    │   WAN: 192.168.x.x            │
    │   LAN: 10.30.x.1              │
    └───────┬───────────────────────┘
            │
            │ Lab Segments
            │
    ┌───────▼────────────────────────────────────┐
    │  Lab Network (Segmented)                   │
    │  10.30.0.0/16                              │
    │                                            │
    │  ┌──────────────┐  ┌──────────────┐       │
    │  │ VLAN 1       │  │ VLAN 10      │       │
    │  │ Management   │  │ Servers      │       │
    │  │ 10.30.x.0/24 │  │ 10.30.10.0/24│       │
    │  └──────────────┘  └──────────────┘       │
    │                                            │
    │  ┌──────────────┐  ┌──────────────┐       │
    │  │ VLAN 20      │  │ VLAN 66      │       │
    │  │ Clients      │  │ Attack       │       │
    │  │ 10.30.20.0/24│  │ 10.30.66.0/24│       │
    │  └──────────────┘  └──────────────┘       │
    └────────────────────────────────────────────┘

### Physical Connections

**ISP to fw-edge01:**
- Connection: Ethernet (WAN port)
- Type: DHCP from ISP
- Speed: [Your connection speed]
- Public IP: Dynamic (via Cloudflare DDNS)

**fw-edge01 to Network:**
- Connection: Ethernet (LAN port)
- Type: Gateway for 192.168.x.0/24
- Speed: 1 Gbps (or your speed)
- VLAN: 1 (untagged)

**Home Network Devices:**
- Proxmox: 192.168.x.241
- TrueNAS: 192.168.x.240
- Jumphost: 192.168.x.67
- Other devices: DHCP or static

**Proxmox to fw-lab01:**
- Connection: Virtual network bridge
- Type: VM networking
- Lab firewall WAN: 192.168.x.x
- Lab firewall LAN: 10.30.x.1

**fw-lab01 to Lab Segments:**
- Connection: Virtual VLANs
- Type: VLAN tagging
- VLANs: 1, 10, 20, 66
- Routing: All handled by fw-lab01

---

## Logical Topology

### Trust Zones

**Four Security Zones:**

    ┌─────────────────────────────────────────┐
    │ Red Zone: Internet/WAN                  │
    │ Threat: HIGH | Trust: NONE              │
    │                                         │
    │ ┌─────────────────────────────────────┐ │
    │ │ Yellow Zone: VPN Tunnel             │ │
    │ │ 10.6.0.0/24                         │ │
    │ │ Threat: MEDIUM | Trust: LIMITED     │ │
    │ │                                     │ │
    │ │ ┌─────────────────────────────────┐ │ │
    │ │ │ Green Zone: Home Network        │ │ │
    │ │ │ 192.168.x.0/24                  │ │ │
    │ │ │ Threat: LOW | Trust: HIGH       │ │ │
    │ │ └─────────────────────────────────┘ │ │
    │ │                                     │ │
    │ │ ┌─────────────────────────────────┐ │ │
    │ │ │ Blue Zone: Lab (Isolated)       │ │ │
    │ │ │ 10.30.0.0/16                    │ │ │
    │ │ │ Threat: HIGH | Trust: NONE      │ │ │
    │ │ └─────────────────────────────────┘ │ │
    │ └─────────────────────────────────────┘ │
    └─────────────────────────────────────────┘

### Zone Relationships

**Red Zone (Internet):**
- Can reach: fw-edge01 WAN (UDP 51820 only)
- Cannot reach: Any internal networks directly
- Controlled by: WAN firewall rules

**Yellow Zone (VPN):**
- Can reach: Specific services in Green Zone (explicit rules)
- Cannot reach: fw-edge01 management, unauthorized hosts
- Controlled by: wg0 interface firewall rules

**Green Zone (Home Network):**
- Can reach: Internet (via NAT)
- Can reach: Lab (via Jumphost only)
- Cannot be reached: By Lab networks
- Controlled by: fw-edge01 LAN rules

**Blue Zone (Lab):**
- Can reach: Internet (for updates, filtered)
- Cannot reach: Green Zone (blocked by fw-lab01)
- Can be reached: By Jumphost only
- Controlled by: fw-lab01 firewall rules

---

## IP Addressing

### Address Allocation Scheme

#### Home Network (Green Zone)

**Network:** 192.168.x.0/24  
**Subnet Mask:** 255.255.255.0  
**Gateway:** 192.168.x.1 (fw-edge01)  
**DNS:** [Your DNS servers]  
**DHCP Range:** 192.168.x.100-192.168.x.200

**Static Assignments:**

| Device | IP Address | MAC Address | Purpose |
|--------|------------|-------------|---------|
| fw-edge01 | 192.168.x.1 | [MAC] | Gateway and firewall |
| Proxmox | 192.168.x.241 | [MAC] | Virtualization host |
| TrueNAS | 192.168.x.240 | [MAC] | Storage server |
| Jumphost | 192.168.x.67 | [MAC] | Lab access bastion |
| fw-lab01 WAN | 192.168.x.[Y] | [MAC] | Lab firewall WAN side |

**Reserved Ranges:**
- 192.168.x.1-192.168.x.99: Infrastructure and static hosts
- 192.168.x.100-192.168.x.200: DHCP pool
- 192.168.x.201-192.168.x.254: Reserved for future use

#### VPN Tunnel (Yellow Zone)

**Network:** 10.6.0.0/24  
**Subnet Mask:** 255.255.255.0  
**Gateway:** 10.6.0.1 (fw-edge01 wg0)  
**Purpose:** WireGuard VPN tunnel

**Assignments:**

| Host | IP Address | Purpose |
|------|------------|---------|
| fw-edge01 wg0 | 10.6.0.1 | VPN server endpoint |
| VPN Client 1 | 10.6.0.2 | First VPN client |
| VPN Client 2 | 10.6.0.3 | Second VPN client |
| VPN Client N | 10.6.0.x | Additional clients |

**Notes:**
- Each VPN client gets /32 assignment
- Clients cannot communicate peer-to-peer
- Only routed to allowed services in 192.168.x.0/24

#### Lab Networks (Blue Zone)

**Supernet:** 10.30.0.0/16  
**Managed by:** fw-lab01  
**Purpose:** Isolated red team lab

##### VLAN 1: Management

**Network:** 10.30.x.0/24  
**Gateway:** 10.30.x.1  
**Purpose:** Firewall and infrastructure management

| Device | IP Address | Purpose |
|--------|------------|---------|
| fw-lab01 | 10.30.x.1 | Lab firewall management |
| Lab Switch | 10.30.x.2 | Managed switch (if applicable) |

##### VLAN 10: Server Segment

**Network:** 10.30.10.0/24  
**Gateway:** 10.30.10.1  
**Purpose:** Victim server infrastructure

| Device | IP Address | Purpose |
|--------|------------|---------|
| Domain Controller | 10.30.10.10 | Active Directory DC |
| SQL Server | 10.30.10.20 | Database server |
| Web Server | 10.30.10.30 | Web application server |
| Wazuh | 10.30.10.100 | SIEM and monitoring |

##### VLAN 20: Client Segment

**Network:** 10.30.20.0/24  
**Gateway:** 10.30.20.1  
**Purpose:** Victim client machines

| Device | IP Address | Purpose |
|--------|------------|---------|
| Windows Client 1 | 10.30.20.10 | Domain-joined workstation |
| Windows Client 2 | 10.30.20.11 | Additional workstation |
| Linux Client 1 | 10.30.20.20 | Linux desktop |
| DHCP Pool | 10.30.20.100-200 | Dynamic clients |

##### VLAN 66: Attack Segment

**Network:** 10.30.66.0/24  
**Gateway:** 10.30.66.1  
**Purpose:** Offensive security tools

| Device | IP Address | Purpose |
|--------|------------|---------|
| Kali Linux | 10.30.66.10 | Primary attack platform |
| Parrot OS | 10.30.66.11 | Alternative attack OS |
| Windows Attacker | 10.30.66.20 | Windows-based attacks |
| C2 Server | 10.30.66.50 | Command and control testing |

---

## VLAN Design

### Home Network VLANs

**Current State:**

| VLAN ID | Name | Network | Purpose | Status |
|---------|------|---------|---------|--------|
| 1 | Default | 192.168.x.0/24 | All home devices | Active |

**Planned Future State:**

| VLAN ID | Name | Network | Purpose | Status |
|---------|------|---------|---------|--------|
| 1 | Native | - | Unused (best practice) | Planned |
| 10 | Management | 192.168.10.0/24 | Firewall, switch mgmt | Planned |
| 20 | Production | 192.168.20.0/24 | Proxmox, TrueNAS | Planned |
| 30 | Lab WAN | 192.168.30.0/24 | fw-lab01 WAN side | Planned |
| 40 | Guest | 192.168.40.0/24 | Guest network | Planned |

### Lab Network VLANs

**Current State:**

| VLAN ID | Name | Network | Purpose | Gateway | Status |
|---------|------|---------|---------|---------|--------|
| 1 | Management | 10.30.x.0/24 | fw-lab01 management | 10.30.x.1 | Active |
| 10 | Server | 10.30.10.0/24 | Server infrastructure | 10.30.10.1 | Active |
| 20 | Client | 10.30.20.0/24 | Client machines | 10.30.20.1 | Active |
| 66 | Attack | 10.30.66.0/24 | Attack platforms | 10.30.66.1 | Active |

### VLAN Tagging

**Home Network:**
- Current: All untagged (VLAN 1)
- Switch: Unmanaged or basic managed
- Tagging: Not implemented yet

**Lab Network:**
- Tagging: Full 802.1Q VLAN tagging
- Managed by: fw-lab01
- Switch: Virtual or physical managed switch
- Trunk: All VLANs (1, 10, 20, 66)

---

## Routing

### Default Routes

**Home Network Devices:**
- Default Gateway: 192.168.x.1 (fw-edge01)
- Route: All traffic to fw-edge01 for internet access

**VPN Clients:**
- Split-tunnel: Only 10.6.0.0/24 and 192.168.x.0/24 via VPN
- Default: Internet traffic via client's normal connection
- Configured in: WireGuard client config (AllowedIPs)

**Lab Networks:**
- Default Gateway: 10.30.x.1 (fw-lab01)
- Route: All traffic to fw-lab01
- Internet: fw-lab01 routes to 192.168.x.1 (fw-edge01)

### Static Routes

**On fw-edge01:**
- Route to Lab: 10.30.0.0/16 via 192.168.x.[fw-lab01-WAN]
- Purpose: Allow routing to lab networks (for Jumphost access)

**On fw-lab01:**
- Default route: 0.0.0.0/0 via 192.168.x.1
- Purpose: Lab internet access for updates

**On VPN Clients:**
- 10.6.0.0/24 via WireGuard tunnel
- 192.168.x.0/24 via WireGuard tunnel
- All else via normal internet connection

### Inter-VLAN Routing (Lab)

**Handled by:** fw-lab01

**Routing Rules:**
- VLAN 66 (Attack) can reach VLAN 10 (Server): ALLOW
- VLAN 66 (Attack) can reach VLAN 20 (Client): ALLOW
- VLAN 10 (Server) can reach VLAN 20 (Client): Configurable
- VLAN 1 (Management) access: Restricted

**Purpose:**
- Enable attack scenarios from Attack VLAN
- Simulate lateral movement
- Control access to management

---

## Network Services

### DNS

**Home Network:**
- Primary DNS: [Your DNS]
- Secondary DNS: [Backup DNS]
- Internal Resolution: Via fw-edge01 or separate DNS server
- Purpose: Resolve internal hostnames and internet domains

**Lab Networks:**
- DNS Server: On Domain Controller (10.30.10.10)
- Purpose: Active Directory DNS, internal lab resolution
- Fallback: Forward to home network DNS

### DHCP

**Home Network:**
- DHCP Server: fw-edge01 or separate server
- Range: 192.168.x.100-192.168.x.200
- Lease Time: 24 hours
- Options: DNS, Gateway, NTP

**Lab Networks:**

**VLAN 10 (Server):**
- Static assignments only
- No DHCP (servers have fixed IPs)

**VLAN 20 (Client):**
- DHCP Server: On Domain Controller or fw-lab01
- Range: 10.30.20.100-10.30.20.200
- Lease Time: 8 hours
- Options: DNS (DC), Gateway, Domain

**VLAN 66 (Attack):**
- DHCP Server: fw-lab01
- Range: 10.30.66.100-10.30.66.200
- Lease Time: 4 hours
- Options: DNS, Gateway

**VLAN 1 (Management):**
- Static assignments only
- No DHCP for security

### NTP

**Time Synchronization:**
- Home network: Syncs to internet NTP pools
- Lab networks: Sync to Domain Controller or fw-lab01
- Purpose: Accurate logging timestamps

---

## Firewall Placement

### fw-edge01 (Edge Firewall)

**Position:** Between Internet and Home Network

**Interfaces:**
- WAN (bge1): Public IP from ISP
- LAN (bge0): 192.168.x.1
- WireGuard (wg0): 10.6.0.1

**Role:**
- Perimeter defense
- VPN termination
- NAT for home network
- Service-level access control

**Firewall Rules:** See [SECURITY_ZONES.md](SECURITY_ZONES.md)

### fw-lab01 (Lab Firewall)

**Position:** Between Home Network and Lab Segments

**Interfaces:**
- WAN: 192.168.x.[Y] (connected to home network)
- LAN: 10.30.x.1 (lab gateway)
- VLANs: 1, 10, 20, 66 (virtual interfaces)

**Role:**
- Lab isolation
- Inter-VLAN routing
- Protect home network from lab
- Control lab internet access

**Firewall Rules:** See [SECURITY_ZONES.md](SECURITY_ZONES.md)

### Firewall Hierarchy

    Internet
       │
    ┌──▼──────────┐
    │  fw-edge01  │ ← Perimeter Defense
    └──┬──────────┘
       │
    Home Network
       │
    ┌──▼──────────┐
    │  fw-lab01   │ ← Lab Isolation
    └──┬──────────┘
       │
    Lab Segments

**Defense in Depth:**
- Two independent firewalls
- Different purposes (perimeter vs isolation)
- Multiple trust boundaries
- Layered security approach

---

## Connection Details

### Physical Connections

**ISP Equipment:**
- Type: Cable modem or fiber ONT
- Connection: Ethernet to fw-edge01 WAN
- Speed: [Your speed]
- IP Assignment: DHCP

**fw-edge01:**
- WAN Port: To ISP equipment
- LAN Port: To home network switch/devices
- Management: Via LAN only (not WAN or VPN)

**Home Network Switch:**
- Type: Unmanaged or basic managed
- Connections: All home devices
- VLAN Support: Not currently used
- Speed: 1 Gbps ports

**Proxmox Host:**
- Network: Connected to home network
- Bridges: Virtual bridges for VM networking
- Speed: 1 Gbps (or 10 Gbps if applicable)

**TrueNAS:**
- Network: Connected to home network
- Purpose: SMB/NFS file shares
- Speed: 1 Gbps (or bonded)

**Jumphost:**
- Network: Connected to home network
- Purpose: SSH bastion for lab access
- Speed: 1 Gbps

### Virtual Connections (Lab)

**fw-lab01 VM:**
- Host: Proxmox
- WAN Interface: Bridged to home network
- LAN Interface: Virtual network for lab VMs
- VLAN Tagging: Software-based on virtual interfaces

**Lab VMs:**
- Host: Proxmox
- Network: Virtual network managed by fw-lab01
- VLAN Assignment: Tagged or untagged per VM
- Isolation: Enforced by fw-lab01 firewall rules

---

## Network Performance

### Bandwidth

**WAN Connection:**
- Download: [Your download speed]
- Upload: [Your upload speed]
- Latency: [Your typical latency]

**Internal Network:**
- Speed: 1 Gbps wired (or your speed)
- Latency: <1ms between local devices

**VPN Performance:**
- Added Latency: 5-20ms (WireGuard overhead)
- Throughput: Limited by WAN upload speed
- Protocol: UDP for best performance

**Lab Network:**
- Speed: Virtual network (no physical limit)
- Performance: Limited by Proxmox host resources

### Monitoring

**Current Monitoring:**
- Basic firewall logs
- Proxmox resource monitoring
- Manual observation

**Planned Monitoring:**
- Bandwidth graphs per interface
- Network flow analysis
- Performance alerts
- SNMP monitoring (if switch supports)

---

## Network Evolution

### Current State (v3.0)

**What's Working:**
- Home network flat but functional
- VPN access to specific services
- Lab fully segmented with 4 VLANs
- Complete lab isolation via fw-lab01

**What's Adequate:**
- Single flat home network
- Adequate for current use case
- All critical services accessible
- Lab completely isolated

### Planned State (v4.0)

**Home Network Segmentation:**
- Purchase managed switch
- Implement VLANs for home network
- Separate management from production
- Add guest network isolation

**Enhanced Monitoring:**
- Deploy network monitoring tools
- Add SNMP to managed devices
- Create bandwidth dashboards
- Set up alerting

### Future State (v5.0+)

**Advanced Features:**
- 10 Gbps networking for storage
- Additional firewall for redundancy
- Network tap for passive monitoring
- Advanced threat detection

**Scalability:**
- Multiple Proxmox nodes (clustering)
- Distributed storage
- Load balancing
- High availability

---

## Troubleshooting

### Common Issues

**Cannot Reach Internet from Home Network:**
- Check: fw-edge01 WAN interface status
- Check: Default gateway on devices (should be 192.168.x.1)
- Check: DNS servers configured
- Check: Outbound NAT rules on fw-edge01

**Cannot Access Services via VPN:**
- Check: VPN tunnel established (wg show)
- Check: Firewall rules on wg0 interface
- Check: Routing on client (AllowedIPs)
- Check: Service is running and reachable from LAN

**Lab Cannot Reach Internet:**
- Check: fw-lab01 default route to 192.168.x.1
- Check: fw-lab01 WAN interface connected
- Check: Outbound NAT on fw-edge01 includes lab networks
- Check: DNS configuration on lab VMs

**Cannot Access Lab from Jumphost:**
- Check: Static route on fw-edge01 to 10.30.0.0/16
- Check: fw-lab01 WAN rules allow from jumphost IP
- Check: SSH keys configured on jumphost
- Check: Lab VM firewall not blocking

### Diagnostic Commands

**Test connectivity:**

    ping 8.8.8.8
    ping 192.168.x.1
    traceroute google.com

**Check routing:**

    ip route show
    netstat -rn

**Check VPN tunnel:**

    wg show
    ping 10.6.0.1

**Check firewall logs:**

    # On OPNsense
    clog /var/log/filter.log

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - High-level architecture
- [SECURITY_ZONES.md](SECURITY_ZONES.md) - Trust boundaries and firewall rules
- [TRAFFIC_FLOWS.md](TRAFFIC_FLOWS.md) - How packets move through network
- [../infrastructure/network/](../infrastructure/network/) - Implementation configs

---

Last Updated: February 2026
