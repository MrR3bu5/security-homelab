# Component Inventory

Complete inventory of all hardware, software, and services in the homelab infrastructure.

## Table of Contents

1. [Overview](#overview)
2. [Hardware Inventory](#hardware-inventory)
3. [Network Equipment](#network-equipment)
4. [Firewall Instances](#firewall-instances)
5. [Virtual Machines](#virtual-machines)
6. [Services and Applications](#services-and-applications)
7. [Network Configuration](#network-configuration)
8. [Software Versions](#software-versions)
9. [Licenses and Subscriptions](#licenses-and-subscriptions)
10. [Maintenance Schedule](#maintenance-schedule)

---

## Overview

### Purpose

This document provides a complete inventory of all infrastructure components for:
- Asset tracking
- Capacity planning
- Disaster recovery planning
- Documentation reference
- Change management

### Inventory Scope

**Included:**
- Physical hardware
- Network equipment
- Virtual machines
- Operating systems
- Applications and services
- Network configurations
- Software licenses

**Excluded:**
- Client devices (laptops, desktops not part of infrastructure)
- IoT devices
- Consumer electronics

---

## Hardware Inventory

### Physical Servers

#### Proxmox Host

**Hardware Details:**

| Component | Specification | Notes |
|-----------|---------------|-------|
| Hostname | proxmox-host01 | Primary virtualization host |
| Model | [Your Model] | [Manufacturer/Model] |
| CPU | [Your CPU] | [Cores/Threads/Speed] |
| RAM | [Your RAM] | [Capacity/Type/Speed] |
| Storage | [Your Storage] | [Type/Capacity/Configuration] |
| Network | [Your NIC] | [Speed/Type] |
| Management | [IPMI/iLO] | [If applicable] |

**Network Interfaces:**

| Interface | Type | Speed | Connected To | IP Address |
|-----------|------|-------|--------------|------------|
| eth0 | Physical | 1 Gbps | Home network switch | 192.168.x.241 |
| vmbr0 | Bridge | Virtual | VM networking | 192.168.x.241 |

**Location:** [Physical location in home]

**Purchase Date:** [Date]

**Warranty:** [Warranty info]

**Status:** Production

---

#### TrueNAS Server

**Hardware Details:**

| Component | Specification | Notes |
|-----------|---------------|-------|
| Hostname | truenas01 | Storage server |
| Model | [Your Model] | [Physical or VM] |
| CPU | [Your CPU] | [Cores/Threads/Speed] |
| RAM | [Your RAM] | [Capacity - ZFS needs RAM] |
| Storage Disks | [Your Disks] | [Number/Type/Capacity] |
| RAID Config | [Your Config] | [RAIDZ1/RAIDZ2/Mirror] |
| Network | [Your NIC] | [Speed/Type] |

**Network Interfaces:**

| Interface | Type | Speed | Connected To | IP Address |
|-----------|------|-------|--------------|------------|
| eth0 | Physical | 1 Gbps | Home network | 192.168.x.240 |

**Storage Pools:**

| Pool Name | Type | Capacity | Usage | Purpose |
|-----------|------|----------|-------|---------|
| [Pool 1] | [RAIDZ1/etc] | [X TB] | [X%] | [Data/Backups] |

**Location:** [Physical location]

**Purchase Date:** [Date]

**Status:** Production

---

### Power and Environmental

#### UPS (Uninterruptible Power Supply)

**Details:**

| Component | Specification |
|-----------|---------------|
| Model | [Your UPS Model] |
| Capacity | [VA Rating] |
| Runtime | [Minutes at load] |
| Connected Devices | fw-edge01, Proxmox, TrueNAS, Network |
| Management | [USB/Network] |

**Purpose:** Protect against power outages and surges

**Status:** [Active/Planned]

---

#### Cooling and Rack

**Details:**

| Component | Specification |
|-----------|---------------|
| Rack | [Rack type/size if applicable] |
| Cooling | [Fans/AC if needed] |
| Cable Management | [Type] |

---

## Network Equipment

### Edge Firewall (fw-edge01)

**Hardware/Platform:**

| Component | Specification |
|-----------|---------------|
| Hostname | fw-edge01 |
| Platform | [Physical appliance or VM] |
| Model | [Hardware model if physical] |
| CPU | [Specifications] |
| RAM | [Capacity] |
| Storage | [Capacity] |

**Network Interfaces:**

| Interface | Type | Speed | Purpose | Network |
|-----------|------|-------|---------|---------|
| WAN (bge1) | Physical | 1 Gbps | Internet connection | Public IP (DHCP) |
| LAN (bge0) | Physical | 1 Gbps | Home network | 192.168.x.1 |
| wg0 | Virtual | N/A | VPN tunnel | 10.6.0.1 |

**Purpose:** Perimeter firewall, VPN termination, routing

**Location:** [Physical location]

**Status:** Production

---

### Network Switch

**Hardware Details:**

| Component | Specification |
|-----------|---------------|
| Model | [Your Switch Model] |
| Type | [Managed/Unmanaged] |
| Ports | [Number of ports] |
| Speed | [1 Gbps/10 Gbps] |
| VLAN Support | [Yes/No] |
| Management | [Web/CLI/None] |

**Current State:**
- VLANs: Not implemented yet (flat network)
- Future: Managed switch for VLAN segmentation

**Connected Devices:**
- fw-edge01 (LAN)
- Proxmox host
- TrueNAS
- Jumphost
- Other home devices

**Status:** Production

---

### ISP Equipment

**Modem/ONT:**

| Component | Specification |
|-----------|---------------|
| Type | [Cable modem/Fiber ONT] |
| Model | [ISP provided model] |
| Connection | [Coax/Fiber] |

**Internet Connection:**

| Attribute | Value |
|-----------|-------|
| ISP | [Your ISP] |
| Service Type | [Cable/Fiber/DSL] |
| Download Speed | [Speed] |
| Upload Speed | [Speed] |
| IP Assignment | DHCP (dynamic) |
| Static IP | No |

**Dynamic DNS:**
- Provider: Cloudflare
- Domain: [Your domain if used]
- Update Method: [Script/Built-in]

---

## Firewall Instances

### fw-edge01 (Edge Firewall)

**Software:**

| Attribute | Value |
|-----------|-------|
| OS | OPNsense |
| Version | [Current version] |
| Install Date | [Date] |
| Update Schedule | Monthly |

**Role:** Perimeter defense, VPN termination, NAT

**Interfaces:**
- WAN: Public IP (ISP DHCP)
- LAN: 192.168.x.1
- WireGuard: 10.6.0.1

**Key Services:**
- WireGuard VPN server
- NAT for home network
- DHCP server (if applicable)
- DNS forwarder (if applicable)
- Dynamic DNS client

**Backup:**
- Config backups: [Location/Frequency]
- Restoration tested: [Date]

**Status:** Production - Critical

---

### fw-lab01 (Lab Firewall)

**Platform:**

| Attribute | Value |
|-----------|-------|
| Type | Virtual Machine |
| Host | Proxmox (proxmox-host01) |
| OS | OPNsense |
| Version | [Current version] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |

**Role:** Lab isolation, inter-VLAN routing

**Interfaces:**
- WAN: 192.168.x.[Y] (home network)
- LAN: 10.30.x.1 (lab management)
- VLAN Interfaces: 10.30.10.1, 10.30.20.1, 10.30.66.1

**Key Services:**
- Firewall (lab isolation)
- DHCP for lab VLANs
- DNS forwarder for lab
- Inter-VLAN routing

**Backup:**
- Config backups: [Location/Frequency]
- Snapshots: [Schedule]

**Status:** Production - Critical for lab isolation

---

## Virtual Machines

### Production VMs (on Proxmox)

#### Jumphost

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | jumphost |
| OS | [Linux distro] |
| Version | [OS version] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| IP Address | 192.168.x.67 |

**Purpose:** SSH bastion for lab access

**Services:**
- SSH (port 2222)
- No other services

**Access:**
- From VPN: SSH key authentication only
- To Lab: Full access to all lab VLANs

**Backup:**
- Snapshots: [Schedule]
- Config backup: [Location]

**Status:** Production

---

#### fw-lab01

(See Firewall Instances section above)

---

### Lab VMs (on Proxmox)

#### Domain Controller (VLAN 10)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | dc01 |
| OS | Windows Server [Version] |
| Version | [Build] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 10 (Server segment) |
| IP Address | 10.30.10.10 |

**Purpose:** Active Directory domain controller

**Services:**
- Active Directory Domain Services
- DNS
- DHCP (for client VLAN)
- Group Policy

**Domain:**
- Domain Name: [lab.local or similar]
- Forest Level: [Level]
- Domain Level: [Level]

**Status:** Lab - Intentionally vulnerable

---

#### SQL Server (VLAN 10)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | sql01 |
| OS | Windows Server [Version] |
| Version | [Build] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 10 (Server segment) |
| IP Address | 10.30.10.20 |

**Purpose:** Database server for vulnerable web apps

**Services:**
- SQL Server [Version]
- Intentionally misconfigured for exploitation

**Status:** Lab - Intentionally vulnerable

---

#### Web Server (VLAN 10)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | web01 |
| OS | [Linux or Windows] |
| Version | [OS version] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 10 (Server segment) |
| IP Address | 10.30.10.30 |

**Purpose:** Vulnerable web applications

**Services:**
- Web server (Apache/IIS/Nginx)
- Vulnerable web apps (DVWA, etc.)
- Intentional SQL injection, XSS, etc.

**Status:** Lab - Intentionally vulnerable

---

#### Wazuh SIEM (VLAN 10)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | wazuh01 |
| OS | [Linux distro] |
| Version | [OS version] |
| vCPU | [Number] |
| RAM | [Amount - needs significant RAM] |
| Storage | [Size - needs space for logs] |
| VLAN | 10 (Server segment) |
| IP Address | 10.30.10.100 |

**Purpose:** Security monitoring and SIEM

**Services:**
- Wazuh server
- Wazuh dashboard
- Agent management

**Agents Installed On:**
- All lab VMs
- Monitors attack activity
- Alerts on suspicious behavior

**Status:** Lab - Production-grade monitoring

---

#### Windows Clients (VLAN 20)

**VM Details (per client):**

| Attribute | Client 1 | Client 2 |
|-----------|----------|----------|
| Hostname | win-client01 | win-client02 |
| OS | Windows [Version] | Windows [Version] |
| vCPU | [Number] | [Number] |
| RAM | [Amount] | [Amount] |
| Storage | [Size] | [Size] |
| VLAN | 20 (Client) | 20 (Client) |
| IP Address | 10.30.20.10 | 10.30.20.11 |
| Domain Joined | Yes | Yes |

**Purpose:** Target workstations for exploitation

**Status:** Lab - Intentionally vulnerable

---

#### Linux Clients (VLAN 20)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | linux-client01 |
| OS | [Ubuntu/Debian/etc] |
| Version | [Version] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 20 (Client) |
| IP Address | 10.30.20.20 |

**Purpose:** Linux target for exploitation

**Status:** Lab - Various vulnerability levels

---

#### Kali Linux (VLAN 66)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | kali01 |
| OS | Kali Linux |
| Version | [Rolling/Version] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 66 (Attack) |
| IP Address | 10.30.66.10 |

**Purpose:** Primary attack platform

**Tools Installed:**
- Metasploit Framework
- Burp Suite
- Nmap
- Hydra
- Custom scripts
- [Other tools]

**Status:** Lab - Attack platform

---

#### Parrot Security (VLAN 66)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | parrot01 |
| OS | Parrot Security OS |
| Version | [Version] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 66 (Attack) |
| IP Address | 10.30.66.11 |

**Purpose:** Alternative attack platform

**Status:** Lab - Attack platform

---

#### Windows Attacker (VLAN 66)

**VM Details:**

| Attribute | Value |
|-----------|-------|
| Hostname | win-attacker01 |
| OS | Windows [Version] |
| Version | [Build] |
| vCPU | [Number] |
| RAM | [Amount] |
| Storage | [Size] |
| VLAN | 66 (Attack) |
| IP Address | 10.30.66.20 |

**Purpose:** Windows-based attacks (AD exploitation)

**Tools Installed:**
- PowerShell Empire
- Mimikatz
- BloodHound
- Rubeus
- [Other tools]

**Status:** Lab - Attack platform

---

## Services and Applications

### Production Services

#### Proxmox VE

**Service Details:**

| Attribute | Value |
|-----------|-------|
| Service | Proxmox VE |
| Version | [Version] |
| Web Interface | https://192.168.x.241:8006 |
| API | Available |
| Authentication | Username/password (2FA available) |

**Features Used:**
- VM management
- LXC containers (if used)
- Snapshots
- Backups
- Resource monitoring

**Access:**
- Via VPN: 10.6.0.0/24 → 192.168.x.241:8006
- From LAN: Direct access

**Backup:**
- Config: [Backup method]
- VMs: [Backup schedule]

---

#### TrueNAS

**Service Details:**

| Attribute | Value |
|-----------|-------|
| Service | TrueNAS SCALE |
| Version | [Version] |
| Web Interface | https://192.168.x.240:443 |
| Authentication | Username/password (2FA available) |

**Shares:**

| Share Name | Protocol | Path | Purpose | Access |
|------------|----------|------|---------|--------|
| [Share 1] | SMB | [Path] | [Purpose] | [Users/Groups] |
| [Share 2] | NFS | [Path] | [Purpose] | [Hosts] |

**Access:**
- Via VPN: 10.6.0.0/24 → 192.168.x.240:443, :445
- From LAN: Direct access

**Backup:**
- ZFS snapshots: [Schedule]
- Replication: [If configured]

---

#### WireGuard VPN

**Service Details:**

| Attribute | Value |
|-----------|-------|
| Service | WireGuard |
| Platform | OPNsense (fw-edge01) |
| Version | [Version] |
| Listen Port | UDP 51820 |
| Server IP | 10.6.0.1 |

**Client Configuration:**

| Client Name | IP Address | Public Key | Status |
|-------------|------------|------------|--------|
| client-01 | 10.6.0.2 | [Key] | Active |
| client-02 | 10.6.0.3 | [Key] | Active |

**Allowed Services:**
- Proxmox (192.168.x.241:8006)
- TrueNAS (192.168.x.240:443, :445)
- Jumphost (192.168.x.67:2222)

---

### Lab Services

#### Active Directory Domain Services

**Service Details:**

| Attribute | Value |
|-----------|-------|
| Service | AD DS |
| Domain | [lab.local] |
| Forest Functional Level | [Level] |
| Domain Controller | dc01 (10.30.10.10) |

**Purpose:** Enterprise AD for attack/defense practice

---

#### Wazuh SIEM

**Service Details:**

| Attribute | Value |
|-----------|-------|
| Service | Wazuh |
| Version | [Version] |
| Server | wazuh01 (10.30.10.100) |
| Dashboard | https://10.30.10.100 |

**Monitored Systems:**
- All lab VMs (agents installed)
- Lab network traffic (if configured)

**Purpose:** Detection and blue team practice

---

## Network Configuration

### IP Address Allocation

#### Home Network (192.168.x.0/24)

**Static Assignments:**

| Device | IP Address | MAC Address | Notes |
|--------|------------|-------------|-------|
| fw-edge01 | 192.168.x.1 | [MAC] | Gateway |
| Proxmox | 192.168.x.241 | [MAC] | Hypervisor |
| TrueNAS | 192.168.x.240 | [MAC] | Storage |
| Jumphost | 192.168.x.67 | [MAC] | Bastion |
| fw-lab01 WAN | 192.168.x.[Y] | [MAC] | Lab firewall |

**DHCP Range:**
- Range: 192.168.x.100-192.168.x.200
- Lease Time: 24 hours
- DNS Servers: [DNS IPs]
- Default Gateway: 192.168.x.1

---

#### VPN Tunnel (10.6.0.0/24)

| Host | IP Address | Type |
|------|------------|------|
| fw-edge01 wg0 | 10.6.0.1 | Server |
| VPN Client 1 | 10.6.0.2 | Client |
| VPN Client 2 | 10.6.0.3 | Client |

---

#### Lab Networks (10.30.0.0/16)

**VLAN 1 - Management (10.30.x.0/24):**

| Device | IP Address |
|--------|------------|
| fw-lab01 | 10.30.x.1 |

**VLAN 10 - Servers (10.30.10.0/24):**

| Device | IP Address |
|--------|------------|
| Gateway | 10.30.10.1 |
| dc01 | 10.30.10.10 |
| sql01 | 10.30.10.20 |
| web01 | 10.30.10.30 |
| wazuh01 | 10.30.10.100 |

**VLAN 20 - Clients (10.30.20.0/24):**

| Device | IP Address |
|--------|------------|
| Gateway | 10.30.20.1 |
| win-client01 | 10.30.20.10 |
| win-client02 | 10.30.20.11 |
| linux-client01 | 10.30.20.20 |
| DHCP Range | 10.30.20.100-200 |

**VLAN 66 - Attack (10.30.66.0/24):**

| Device | IP Address |
|--------|------------|
| Gateway | 10.30.66.1 |
| kali01 | 10.30.66.10 |
| parrot01 | 10.30.66.11 |
| win-attacker01 | 10.30.66.20 |

---

### DNS Configuration

**Home Network:**
- Primary DNS: [DNS server IP]
- Secondary DNS: [Backup DNS]
- Internal resolution: [If configured]

**Lab Network:**
- Primary DNS: 10.30.10.10 (DC)
- Domain: [lab.local]
- Forwarders: [External DNS]

---

### Routing

**Static Routes:**

**On fw-edge01:**

| Destination | Gateway | Purpose |
|-------------|---------|---------|
| 10.30.0.0/16 | 192.168.x.[fw-lab01] | Route to lab networks |

**On fw-lab01:**

| Destination | Gateway | Purpose |
|-------------|---------|---------|
| 0.0.0.0/0 | 192.168.x.1 | Default route to internet |

---

## Software Versions

### Operating Systems

| System | OS | Version | Last Updated |
|--------|-----|---------|--------------|
| fw-edge01 | OPNsense | [Version] | [Date] |
| fw-lab01 | OPNsense | [Version] | [Date] |
| Proxmox | Proxmox VE | [Version] | [Date] |
| TrueNAS | TrueNAS SCALE | [Version] | [Date] |
| Jumphost | [Linux distro] | [Version] | [Date] |
| dc01 | Windows Server | [Version] | [Date] |
| sql01 | Windows Server | [Version] | [Date] |
| wazuh01 | [Linux distro] | [Version] | [Date] |
| kali01 | Kali Linux | [Rolling] | [Date] |

---

### Key Applications

| Application | Version | Installed On | Purpose |
|-------------|---------|--------------|---------|
| WireGuard | [Version] | fw-edge01 | VPN |
| Wazuh | [Version] | wazuh01 | SIEM |
| Active Directory | [Version] | dc01 | Directory services |
| SQL Server | [Version] | sql01 | Database |
| Metasploit | [Version] | kali01 | Pentesting |

---

## Licenses and Subscriptions

### Commercial Software

| Software | License Type | Expiration | Notes |
|----------|--------------|------------|-------|
| Windows Server | Evaluation/Dev | [Date] | [License key location] |
| SQL Server | Express/Dev | N/A | Free version |

### Open Source Software

| Software | License | Support |
|----------|---------|---------|
| OPNsense | BSD | Community |
| Proxmox VE | AGPL | Community (no subscription) |
| TrueNAS SCALE | GPL | Community |
| Kali Linux | GPL | Community |
| Wazuh | GPL | Community |

**Note:** All production infrastructure uses free/open source software. No commercial subscriptions required.

---

## Maintenance Schedule

### Regular Updates

**Monthly:**
- fw-edge01 OPNsense updates
- fw-lab01 OPNsense updates
- Proxmox updates
- TrueNAS updates

**Weekly:**
- Kali Linux updates (rolling)
- Security patches for critical systems

**As Needed:**
- Lab VMs (intentionally may stay vulnerable)
- Windows evaluation licenses (rearm as needed)

---

### Backup Schedule

**Daily:**
- TrueNAS ZFS snapshots
- Critical VM snapshots (if configured)

**Weekly:**
- Full Proxmox VM backups
- Firewall config backups

**Monthly:**
- Off-site backup sync (if configured)
- Backup restoration test

---

### Testing Schedule

**Weekly:**
- Lab isolation validation (ping test from lab)
- VPN connectivity test

**Monthly:**
- Firewall rule review
- Service access validation
- Backup restoration test

**Quarterly:**
- Full disaster recovery test
- Security audit
- Documentation review

---

## Change Log

### Recent Changes

| Date | Component | Change | Reason |
|------|-----------|--------|--------|
| [Date] | fw-lab01 | Deployed lab firewall | Lab isolation |
| [Date] | VPN | Added new client | New device |
| [Date] | Lab | Added Wazuh SIEM | Blue team practice |

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture
- [NETWORK_TOPOLOGY.md](NETWORK_TOPOLOGY.md) - Network design
- [HARDWARE.md](../docs/HARDWARE.md) - Detailed hardware specs
- [SERVICES.md](../docs/SERVICES.md) - Service documentation
- [../infrastructure/](../infrastructure/) - Configuration files

---

Last Updated: February 2026
