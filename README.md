# 🏠 Security-Focused Homelab

Enterprise-grade homelab infrastructure designed for security research, red team operations, and continuous learning. Multi-zone architecture with complete network segmentation, defense-in-depth security controls, and isolated attack simulation environment.

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Proxmox-orange)](https://www.proxmox.com/)
[![Security](https://img.shields.io/badge/Security-OPNsense-blue)](https://opnsense.org/)
[![Network](https://img.shields.io/badge/Network-Segmented-green)]()
[![Lab](https://img.shields.io/badge/Lab-Isolated-red)]()

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Infrastructure](#infrastructure)
- [Security Model](#security-model)
- [Services](#services)
- [Projects](#projects)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Lessons Learned](#lessons-learned)

---

## 🎯 Overview

This homelab serves multiple purposes:

**Production Infrastructure**
- Virtualization platform for development and testing
- Secure file storage and backup
- Remote access infrastructure
- Network services (DNS, DHCP, monitoring)

**Security Research**
- Isolated red team lab environment
- Attack simulation and defense testing
- Security tool development and validation
- Incident response practice

**Continuous Learning**
- HackTheBox Pro Lab practice environment
- CVE research and exploit development
- Blue team detection engineering
- New technology evaluation

### Design Principles

1. **Security by Default**: Everything starts locked down
2. **Defense in Depth**: Multiple layers of protection
3. **Segmentation**: Strict network isolation
4. **Monitoring**: Complete visibility into activity
5. **Documentation**: Everything documented for learning
6. **Validation**: Regular testing and validation

---

## 🏗️ Architecture

### Network Topology

![Network Topology](diagrams/full-topology.png)

### Security Zones

The homelab is divided into four distinct trust zones:

**🔴 Red Zone (Untrusted)**
- Internet/WAN interface
- Default deny all inbound
- Only WireGuard VPN exposed

**🟡 Yellow Zone (Semi-Trusted)**
- WireGuard VPN tunnel (10.6.0.0/24)
- Authenticated but restricted access
- Service-level firewall rules

**🟢 Green Zone (Trusted)**
- Production services (192.168.x.0/24)
- Proxmox, TrueNAS, management interfaces
- Protected behind multiple security layers

**🔵 Blue Zone (Isolated)**
- Red team lab networks
- Intentionally vulnerable systems
- Strictly isolated from production
- No reverse access allowed

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design.

---

## ✨ Key Features

### Infrastructure
- **Virtualization**: Proxmox VE with clustered storage
- **Networking**: Multi-zone architecture with VLANs
- **Storage**: TrueNAS with ZFS for data integrity
- **Compute**: Dedicated resources per zone
- **High Availability**: Redundant services and backups

### Security
- **Firewall**: Dual OPNsense instances (edge + lab)
- **VPN**: WireGuard with zero-trust access model
- **Segmentation**: Complete network isolation
- **Monitoring**: Centralized logging and alerting
- **Validation**: Automated security testing

### Lab Environment
- **Attack Infrastructure**: Kali Linux, custom tooling
- **Victim Systems**: Intentionally vulnerable VMs
- **Network Simulation**: Multiple attack scenarios
- **Isolation**: Cannot reach production networks
- **Snapshot Management**: Easy reset and restore

---

## 🖥️ Infrastructure

### Hardware

| Component | Specification | Purpose |
|-----------|---------------|---------|
| Hypervisor |  | Proxmox host |
| Firewall |  | OPNsense edge firewall |
| Storage |  | TrueNAS server |
| Network |  | Managed switch, VLANs |

See [docs/HARDWARE.md](docs/HARDWARE.md) for complete specs.

### Network Design

**Physical Network:**
- ISP → fw-edge01 (WAN)
- fw-edge01 (LAN) → Managed Switch
- Dedicated lab VLAN behind fw-lab01

**VLANs:**
- VLAN 10: Servers
- VLAN 20: Clients
- VLAN 30: Attack Infrastructure
- VLAN 0: Jumphost

See [docs/NETWORK_DESIGN.md](docs/NETWORK_DESIGN.md) for routing and firewall rules.

---

## 🔒 Security Model

### Defense in Depth

**Layer 1: Perimeter**
- Single exposed port (WireGuard UDP 51820)
- All other inbound traffic blocked
- DDoS protection via Cloudflare

**Layer 2: Authentication**
- WireGuard public key authentication
- No password-based VPN access
- Multi-factor authentication on services

**Layer 3: Network Access Control**
- Service-level firewall rules
- Explicit allow-list only
- No lateral movement via VPN

**Layer 4: Application Security**
- Individual service authentication
- Strong passwords and SSH keys
- Regular patching and updates

**Layer 5: Monitoring**
- Complete access logging
- Security event correlation
- Automated alerting

See [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) for threat model and controls.

### Lab Isolation

The red team lab is completely isolated:
- Dedicated firewall (fw-lab01)
- No direct access to production
- Cannot initiate connections outbound
- Accessed only via jumphost
- Assumed compromised at all times

---

## 🚀 Services

### Production Services

**Virtualization**
- Proxmox VE 8.x
- Multiple VM templates
- Automated backups
- Resource monitoring

**Storage**
- TrueNAS Core
- ZFS with snapshots
- SMB and NFS shares
- Automated replication

**Network Services**
- Internal DNS
- DHCP server
- NTP server
- Reverse proxy

**Monitoring**
- Grafana dashboards
- Prometheus metrics
- Log aggregation
- Uptime monitoring

### Lab Services

**Attack Infrastructure**
- Kali Linux (latest)
- Custom exploit development environment
- Metasploit, Cobalt Strike (licensed)
- C2 infrastructure testing

**Vulnerable Systems**
- Intentionally vulnerable VMs
- HackTheBox practice machines
- CVE testing environments
- Custom vulnerable applications

**Blue Team**
- Security Onion (SIEM)
- Suricata IDS/IPS
- Log analysis platform
- Incident response tools

See [docs/SERVICES.md](docs/SERVICES.md) for complete service inventory.

---

## 📁 Projects

Active projects built on this infrastructure:

### [Secure Remote Access](https://github.com/MrR3bu5/secure-remote-access)
Zero-trust VPN with service-level access control. 95% reduction in attack surface.

**Status:** Production  
**Tech:** WireGuard, OPNsense, Python

### Active Directory Lab (Coming Soon)
Enterprise AD environment for attack and defense practice.

**Status:** Planning  
**Tech:** Windows Server, AD, GPO

### SIEM Deployment (Coming Soon)
Centralized logging and security monitoring.

**Status:** In Progress  
**Tech:** Security Onion, Wazuh, ELK

### Red Team Infrastructure (Coming Soon)
C2 framework testing and development.

**Status:** Planning  
**Tech:** Covenant, Sliver, Custom tools

---

## 🚦 Getting Started

### For Recruiters/Employers

**What This Demonstrates:**
- Enterprise-grade infrastructure design
- Security-first mindset
- Defense-in-depth implementation
- Complete documentation skills
- Continuous learning and improvement

**Key Highlights:**
- Multi-zone security architecture
- Isolated red team environment
- Automated validation and testing
- Real-world problem solving

### For Fellow Homelabbers

**Learning Path:**
1. Review [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions
2. Check [docs/NETWORK_DESIGN.md](docs/NETWORK_DESIGN.md) for network layout
3. Read [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) for threat model
4. Explore [projects/](projects/) for specific implementations
5. Review [docs/LESSONS_LEARNED.md](docs/LESSONS_LEARNED.md) for pitfalls

**Prerequisites:**
- Basic networking knowledge
- Virtualization experience
- Linux/Unix familiarity
- Security fundamentals

---

## 📚 Documentation

### Core Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Hardware Specifications](docs/HARDWARE.md)
- [Network Design](docs/NETWORK_DESIGN.md)
- [Security Model](docs/SECURITY_MODEL.md)
- [Service Inventory](docs/SERVICES.md)
- [Lab Environment](docs/LAB_ENVIRONMENT.md)

### Operations

- [Backup & Disaster Recovery](docs/BACKUP_DR.md)
- [Monitoring Setup](docs/MONITORING.md)
- [Incident Response](security/incident-response/)
- [Lessons Learned](docs/LESSONS_LEARNED.md)

### Technical Guides

- [Firewall Configuration](infrastructure/network/fw-edge01/)
- [VPN Setup](projects/secure-remote-access/)
- [VM Templates](infrastructure/proxmox/vm-templates/)
- [Automation Scripts](automation/scripts/)

---

## 💡 Lessons Learned

### What Worked Well

**Infrastructure:**
- Proxmox provides excellent flexibility
- Network segmentation simplified security
- ZFS snapshots saved me multiple times
- Documentation prevented repeated mistakes

**Security:**
- Zero-trust model reduced risk significantly
- Lab isolation prevented production incidents
- Regular validation caught misconfigurations
- Defense in depth provided time to respond

**Process:**
- Document everything as you go
- Test before deploying to production
- Automate repetitive tasks
- Regular backups are non-negotiable

### Challenges Encountered

**Technical:**
- Routing through multiple firewalls required planning
- Resource allocation needed careful tuning
- Lab isolation rules are complex
- Performance monitoring took iteration

**Learning:**
- Underestimated documentation time
- Should have automated backups earlier
- Needed better change management
- Log storage requirements were higher than expected

See [docs/LESSONS_LEARNED.md](docs/LESSONS_LEARNED.md) for complete retrospective.

---

## 🔄 Continuous Improvement

### Current Focus (Q1 2026)
- [ ] Complete SIEM deployment
- [ ] Implement automated testing
- [ ] Add network tap for monitoring
- [ ] Deploy honeypot services

### Roadmap
- [ ] Active Directory lab environment
- [ ] Kubernetes cluster for container workloads
- [ ] Advanced threat hunting capabilities
- [ ] CI/CD pipeline for infrastructure

### Metrics

**Security Posture:**
- Exposed ports: 1 (WireGuard only)
- Failed access attempts logged: 100%
- Time to detect anomaly: <1 hour
- Backup success rate: 99.9%

**Infrastructure:**
- Uptime: 99.95% (last 90 days)
- VM count: [1] production, [9] lab
- Storage usage: [4]TB / [1]TB
- Network throughput: [1] Gbps

---

## 🤝 Contributing

This is a personal learning lab, but feedback and suggestions are welcome via issues.

### Sharing Knowledge

If you're building a similar lab:
- Feel free to adapt these designs
- Reach out with questions
- Share your improvements
- Cite this repo if helpful

---

## 📬 Contact

**GitHub:** [@MrR3bu5](https://github.com/MrR3bu5)  
**LinkedIn:** [LinkedIn](https://www.linkedin.com/in/errik-guzman/)
**Location:** California

Open to discussing homelab design, security architecture, or collaboration opportunities.

---

## 🙏 Acknowledgments

**Community Resources:**
- r/homelab for hardware advice
- r/Proxmox for virtualization help
- OPNsense community forums
- HackTheBox for lab inspiration

**Tools & Technologies:**
- Proxmox VE team
- OPNsense developers
- TrueNAS community
- WireGuard project

---

**Last Updated:** February 2026  
**Status:** Active Development
