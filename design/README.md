# Design Documentation

This folder contains the complete architectural design of the security homelab, including network topology, security zones, traffic flows, and design decisions.

## 📋 Documentation Index

### Core Architecture
- [ARCHITECTURE.md](ARCHITECTURE.md) - High-level architecture overview
- [NETWORK_TOPOLOGY.md](NETWORK_TOPOLOGY.md) - Complete network design
- [SECURITY_ZONES.md](SECURITY_ZONES.md) - Trust boundaries and isolation
- [TRAFFIC_FLOWS.md](TRAFFIC_FLOWS.md) - How packets traverse the network

### Design Process
- [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) - Why specific choices were made
- [THREAT_MODEL.md](THREAT_MODEL.md) - Security analysis and mitigations
- [COMPONENT_INVENTORY.md](COMPONENT_INVENTORY.md) - All infrastructure components

### Visual Diagrams
- [diagrams/](diagrams/) - Network diagrams and visual representations

### Technical Specifications
- [specifications/](specifications/) - IP addressing, VLANs, hardware specs

---

## 🎯 Quick Start

### Understanding the Architecture

**If you're new to this homelab:**

1. Start with [ARCHITECTURE.md](ARCHITECTURE.md) for the big picture
2. Review [diagrams/full-topology.png](diagrams/full-topology.png) for visual overview
3. Read [SECURITY_ZONES.md](SECURITY_ZONES.md) to understand trust model
4. Check [TRAFFIC_FLOWS.md](TRAFFIC_FLOWS.md) for how VPN access works

**If you're implementing something similar:**

1. Review [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for rationale
2. Check [THREAT_MODEL.md](THREAT_MODEL.md) for security considerations
3. Reference [specifications/](specifications/) for technical details
4. Adapt diagrams from [diagrams/](diagrams/) for your environment

---

## 🏗️ Architecture Summary

### Four Security Zones

**Red Zone (Untrusted)**
- Internet/WAN
- Default deny all inbound
- Single exposed port (WireGuard UDP 51820)

**Yellow Zone (Semi-Trusted)**
- WireGuard VPN tunnel (10.6.0.0/24)
- Authenticated but restricted
- Service-level access control

**Green Zone (Trusted)**
- Production services (192.168.x.0/24)
- Proxmox, TrueNAS, management
- Protected behind multiple layers

**Blue Zone (Isolated)**
- Lab networks
- Intentionally vulnerable systems
- Strictly isolated from production

See [SECURITY_ZONES.md](SECURITY_ZONES.md) for complete details.

---

## 🔍 Key Design Principles

### 1. Security by Default
Everything starts locked down. Access is explicitly granted, never assumed.

### 2. Defense in Depth
Multiple independent security layers:
- Perimeter firewall
- Network segmentation
- Service authentication
- Monitoring and logging

### 3. Zero Trust Network
VPN authentication does NOT grant network access. Each service requires explicit firewall rule.

### 4. Lab Isolation
Red team lab is assumed compromised at all times. Strict firewall prevents escape to production.

### 5. Complete Visibility
All access logged. All denied connections monitored. Security events correlated.

---

## 📐 Network Design Philosophy

### Segmentation Strategy

**Physical Segmentation:**
- Dedicated firewall hardware (fw-edge01)
- Managed switch with VLAN support
- Separate lab firewall VM (fw-lab01)

**Logical Segmentation:**
- VLANs per trust zone
- Firewall rules between zones
- No flat network access

**Why This Matters:**
- Lab malware cannot escape
- Compromised VPN limited to specific services
- Easy to audit access patterns
- Clear trust boundaries

See [NETWORK_TOPOLOGY.md](NETWORK_TOPOLOGY.md) for implementation.

---

## 🎨 Diagram Guide

### Available Diagrams

**Full Topology** ([diagrams/full-topology.png](diagrams/full-topology.png))
- Complete network layout
- All components and connections
- Physical and logical topology
- Use this to understand entire infrastructure

**Security Zones** ([diagrams/security-zones.png](diagrams/security-zones.png))
- Trust boundaries
- Firewall control points
- Allowed and blocked traffic
- Use this to understand security model

**Traffic Flow** ([diagrams/traffic-flow-vpn.png](diagrams/traffic-flow-vpn.png))
- Step-by-step packet routing
- VPN connection and service access
- Firewall rule evaluation
- Use this to troubleshoot connectivity

**VLAN Design** ([diagrams/vlan-design.png](diagrams/vlan-design.png))
- VLAN assignments
- Port allocations
- Inter-VLAN routing
- Use this for network implementation

### Diagram Sources

All diagrams created using draw.io. Editable `.drawio` files included for customization.

---

## 📊 Technical Specifications

### IP Address Scheme

**WAN Interface:**
- Public IP via DHCP (Cloudflare DDNS)

**Home LAN (Green Zone):**
- Network: 192.168.x.0/24
- Gateway: 192.168.x.1 (fw-edge01)
- Proxmox: 192.168.x.241
- TrueNAS: 192.168.x.240
- Jumphost: 192.168.x.67

**VPN Tunnel (Yellow Zone):**
- Network: 10.6.0.0/24
- Server: 10.6.0.1 (fw-edge01 wg0)
- Clients: 10.6.0.2+

**Lab Networks (Blue Zone):**
- Managed by fw-lab01
- Multiple VLANs for lab segmentation
- Details in [specifications/vlan-assignments.md](specifications/vlan-assignments.md)

See [specifications/ip-allocation.md](specifications/ip-allocation.md) for complete scheme.

### VLAN Design

#### Home
| VLAN ID | Name | Purpose | Gateway |
|---------|------|---------|---------|
| 1 | Home Network | Std. Home network - upgrades coming | 192.168.x.1 |

#### Lab
| VLAN ID | Name | Purpose | Gateway |
|---------|------|---------|---------|
| 1 | Management | Firewall and switch management | 10.30.x.1 |
| 10 | Server | DC, SQL, WebApp, Wazuh | 10.30.10.x |
| 20 | Clients | Client machines (Linux and Windows) | 10.30.20.x |
| 66 | Attack | Kali, Parrot, Windows Attack Clients | 10.30.66.x |

See [specifications/vlan-assignments.md](specifications/vlan-assignments.md) for details.

---

## 🔐 Security Model Overview

### Threat Vectors Considered

**External Threats:**
- Port scanning and reconnaissance
- Brute force attacks
- Zero-day exploitation
- DDoS attacks

**Insider Threats:**
- Compromised VPN credentials
- Lateral movement attempts
- Service exploitation

**Lab Threats:**
- Lab malware escaping to production
- Accidental compromise of production
- Intentional red team attacks

### Mitigations Implemented

**Perimeter Defense:**
- Single exposed port (WireGuard)
- Strong cryptographic authentication
- Dynamic DNS with encrypted updates

**Network Defense:**
- Service-level firewall rules
- No VPN lateral movement
- Lab isolation with dedicated firewall

**Service Defense:**
- Individual authentication per service
- SSH keys only (no passwords)
- Regular patching and updates

**Monitoring:**
- Complete access logging
- Failed attempt monitoring
- Security event correlation

See [THREAT_MODEL.md](THREAT_MODEL.md) for complete analysis.

---

## 🚀 Design Evolution

This architecture evolved over time based on lessons learned:

**Version 1.0 (Initial):**
- Single flat network
- Direct service exposure
- Basic firewall rules

**Version 2.0 (Current):**
- Multi-zone architecture
- VPN-only access
- Service-level rules
- Lab isolation

**Version 3.0 (Planned):**
- SIEM integration
- Advanced monitoring
- Automated threat detection
- Enhanced lab segmentation

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for evolution rationale.

---

## 📝 Using This Documentation

### For Learning

**Study the design process:**
- Understand why decisions were made
- Learn from mistakes documented
- Apply principles to your lab

**Use as reference:**
- Copy diagram styles
- Adapt security model
- Reference IP schemes

### For Implementation

**Follow the architecture:**
- Use diagrams as blueprint
- Reference specifications for settings
- Validate against threat model

**Adapt to your needs:**
- All designs are examples
- Adjust for your hardware
- Scale up or down as needed

---

## 🤝 Feedback and Contributions

Found an issue? Have a suggestion?

**Open an issue** for:
- Design flaws or security concerns
- Documentation improvements
- Diagram updates
- Alternative approaches

**Discussion topics:**
- Better segmentation strategies
- Additional security controls
- Performance optimizations
- Cost-effective alternatives

---

## 📚 Additional Resources

**Related Documentation:**
- [../infrastructure/](../infrastructure/) - Implementation configs
- [../security/](../security/) - Security controls
- [../projects/secure-remote-access/](../projects/secure-remote-access/) - VPN project

**External References:**
- NIST Cybersecurity Framework
- Zero Trust Architecture (NIST SP 800-207)
- Defense in Depth strategies
- Homelab community best practices

---

Last Updated: February 2026
