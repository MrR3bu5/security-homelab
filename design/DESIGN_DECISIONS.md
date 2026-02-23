# Design Decisions

Documentation of key architectural decisions, rationale, alternatives considered, and lessons learned.

## Table of Contents

1. [Overview](#overview)
2. [Network Architecture Decisions](#network-architecture-decisions)
3. [Security Decisions](#security-decisions)
4. [Technology Choices](#technology-choices)
5. [Lab Design Decisions](#lab-design-decisions)
6. [Deferred Decisions](#deferred-decisions)
7. [Mistakes and Lessons Learned](#mistakes-and-lessons-learned)
8. [Future Considerations](#future-considerations)

---

## Overview

### Purpose

This document explains **why** specific design choices were made, not just **what** was implemented. Each decision includes:
- Problem being solved
- Options considered
- Choice made and rationale
- Trade-offs accepted
- Lessons learned

### Decision Framework

**Priorities (in order):**
1. Security first
2. Learning value
3. Functionality
4. Cost effectiveness
5. Performance
6. Aesthetics

---

## Network Architecture Decisions

### Decision 1: Flat Home Network (Current State)

**Problem:** How to segment home network for security and management?

**Options Considered:**

**Option A: Immediate VLAN Segmentation**
- Pros: Better isolation, enterprise-like
- Cons: Requires managed switch, complex setup, disrupts working network
- Cost: $200-500 for managed switch

**Option B: Flat Network (Chosen)**
- Pros: Simple, works now, no additional hardware needed
- Cons: All devices on same subnet, limited isolation
- Cost: $0

**Option C: Software-Based Segmentation**
- Pros: No hardware required
- Cons: Complex, limited effectiveness, performance impact
- Cost: $0

**Decision:** Start with flat network (Option B)

**Rationale:**
- Home network is trusted environment (personal devices only)
- fw-edge01 provides perimeter defense
- VPN access uses service-level rules (not network-level trust)
- Can add VLANs later without disrupting current setup
- Prioritized lab segmentation first (where attacks happen)

**Trade-offs Accepted:**
- All home devices on same subnet
- Less isolation between production services
- Cannot separate guest network (yet)

**Validation:**
- No services exposed to internet ✓
- VPN has service-level access control ✓
- Lab completely isolated ✓
- Adequate for current threat model ✓

**Future Plan:**
- Purchase managed switch (Q2 2026)
- Implement VLANs for management, production, guest
- Maintain backward compatibility

---

### Decision 2: Two-Tier Firewall Architecture

**Problem:** How to isolate lab from production while maintaining internet access?

**Options Considered:**

**Option A: Single Firewall with Complex Rules**
- Pros: Simpler topology, one device to manage
- Cons: Complex rule sets, single point of failure for isolation
- Risk: One misconfigured rule exposes everything

**Option B: Two Separate Firewalls (Chosen)**
- Pros: Complete isolation, independent failure, clear boundaries
- Cons: More complex, two devices to manage
- Cost: fw-lab01 is VM (no additional cost)

**Option C: Network Segmentation Only**
- Pros: Simplest approach
- Cons: No active enforcement, relies on routing only
- Risk: Routing misconfiguration could expose production

**Decision:** Two-tier firewall architecture (Option B)

**Rationale:**
- Lab assumed compromised at all times
- Need absolute isolation from production
- fw-lab01 as VM has no hardware cost
- Independent firewalls = defense in depth
- Clear security boundaries (edge vs isolation)

**Implementation:**
- fw-edge01: Perimeter defense, VPN termination
- fw-lab01: Lab isolation, inter-VLAN routing

**Trade-offs Accepted:**
- More complex to manage (two firewall configs)
- Additional routing hop for lab traffic
- Need to maintain two rule sets

**Validation:**
- Lab cannot reach home network ✓
- Tested by attempting ping from lab ✓
- Independent control of each firewall ✓

**Lesson Learned:**
Worth the complexity. Multiple times during testing, lab VMs were "compromised" during exercises. Having dedicated isolation firewall provided peace of mind.

---

### Decision 3: Lab on Proxmox vs Separate Hardware

**Problem:** Where to run lab environment?

**Options Considered:**

**Option A: Separate Physical Hardware**
- Pros: True isolation, dedicated resources
- Cons: Expensive, space requirements, power consumption
- Cost: $500-1000+ for server

**Option B: Lab VMs on Proxmox (Chosen)**
- Pros: No additional cost, flexible, easy snapshots
- Cons: Shares hardware with production
- Risk: Resource contention

**Option C: Dedicated Lab Host**
- Pros: Isolated hardware, dedicated resources
- Cons: Two hypervisors to manage, higher cost
- Cost: $300-500 for used hardware

**Decision:** Lab VMs on Proxmox (Option B)

**Rationale:**
- Firewall isolation is at network layer (not physical)
- fw-lab01 enforces security boundary
- Proxmox resource allocation prevents contention
- Snapshots enable easy lab reset
- Cost effective (already have Proxmox)

**Risk Mitigation:**
- Resource limits on lab VMs (CPU, RAM quotas)
- Network isolation via fw-lab01
- Regular snapshots before testing
- Monitoring for resource exhaustion

**Trade-offs Accepted:**
- Lab and production share physical hardware
- Proxmox compromise would affect both
- Resource allocation needed

**Validation:**
- Firewall rules prevent lab network access ✓
- Resource limits working (no production impact) ✓
- Snapshots save time when resetting lab ✓

**Lesson Learned:**
This works well for homelab. Physical isolation not necessary when network isolation is strong. Proxmox resource management is sufficient.

---

## Security Decisions

### Decision 4: WireGuard vs OpenVPN

**Problem:** Which VPN protocol for remote access?

**Options Considered:**

**Option A: OpenVPN**
- Pros: Mature, widely supported, flexible
- Cons: Complex configuration, slower performance
- Performance: ~100-200 Mbps typical

**Option B: WireGuard (Chosen)**
- Pros: Modern, simple config, fast, secure
- Cons: Newer (less mature), fewer enterprise features
- Performance: ~300-500 Mbps typical

**Option C: IPsec**
- Pros: Industry standard, built into OS
- Cons: Complex, difficult to configure
- Risk: Easy to misconfigure

**Decision:** WireGuard (Option B)

**Rationale:**
- Modern cryptography (Curve25519, ChaCha20, Poly1305)
- Simple configuration (less error-prone)
- Better performance (important for homelab on residential connection)
- Public key authentication (no passwords)
- Small codebase (easier to audit)

**Configuration:**
- UDP port 51820 (default)
- PersistentKeepalive 25 (maintain NAT mapping)
- Split-tunnel (only route lab traffic)
- No peer-to-peer traffic

**Trade-offs Accepted:**
- Less mature than OpenVPN
- Fewer enterprise management features
- Newer protocol (less organizational acceptance)

**Validation:**
- Connection stable ✓
- Performance excellent (90%+ of WAN speed) ✓
- Simple to add new peers ✓
- Works through NAT without issues ✓

**Lesson Learned:**
WireGuard's simplicity is a security feature. Easier configuration means fewer mistakes. Performance is noticeably better than OpenVPN.

---

### Decision 5: Service-Level Access Control (Zero Trust)

**Problem:** What network access should VPN grant?

**Options Considered:**

**Option A: Full LAN Access**
- Pros: Simple, everything accessible
- Cons: Huge attack surface, VPN = full network trust
- Risk: Compromised VPN key = full network access

**Option B: Service-Level Rules (Chosen - Zero Trust)**
- Pros: Minimal access, explicit allow-list, reduced blast radius
- Cons: More firewall rules, must add rule per service
- Complexity: Medium

**Option C: Jump Host Only**
- Pros: Single entry point, centralized access control
- Cons: Jump host becomes critical, extra hop
- Risk: Jump host compromise affects all access

**Decision:** Service-level access control (Option B)

**Rationale:**
- Zero trust principle: authentication ≠ authorization
- VPN authentication grants tunnel, not network access
- Each service requires explicit firewall rule
- Compromised VPN limited to specific services only
- Cannot access firewall management
- No lateral movement within network

**Implementation:**
- Explicit firewall rule per service
- wg0 interface rules on fw-edge01
- Default deny on VPN interface
- All access logged

**Trade-offs Accepted:**
- Must add firewall rule for each new service
- More complex than "full LAN access"
- Users cannot discover services (must know what's allowed)

**Validation:**
- Can access allowed services (Proxmox, TrueNAS, Jumphost) ✓
- Cannot access fw-edge01 management ✓
- Cannot access other home devices ✓
- Compromised VPN has limited scope ✓

**Lesson Learned:**
Worth the effort. During testing, intentionally "compromised" a VPN key. Limited blast radius meant only approved services accessible. Management interfaces remained secure.

---

### Decision 6: Lab Isolation Strategy

**Problem:** How to safely run attack tools and malware?

**Options Considered:**

**Option A: Hope and Manual Care**
- Pros: No effort
- Cons: Easy to make mistakes, high risk
- Risk: Lab malware escapes to production

**Option B: Network Isolation Only**
- Pros: Simple routing rules
- Cons: No active enforcement
- Risk: Misconfiguration or routing change

**Option C: Dedicated Isolation Firewall (Chosen)**
- Pros: Active enforcement, cannot be bypassed
- Cons: Additional VM, more complexity
- Cost: Minimal (VM on existing hardware)

**Decision:** Dedicated isolation firewall (Option C)

**Rationale:**
- Lab assumed compromised at all times
- Need active enforcement (not just routing)
- fw-lab01 dedicated to isolation
- Separate firewall = independent failure domain
- Can modify lab rules without touching edge firewall

**Implementation:**
- fw-lab01 VM on Proxmox
- WAN side: Connected to home network (192.168.x.x)
- LAN side: Lab networks (10.30.0.0/16)
- Default DENY: Lab cannot reach home
- Only Jumphost allowed to initiate into lab

**Rules Enforced:**
- Block all lab → home network traffic
- Allow lab → internet (for tools/updates)
- Allow Jumphost → lab (management)
- Block home network → lab (except Jumphost)

**Trade-offs Accepted:**
- Additional VM resource usage
- Two firewalls to manage
- Extra routing hop for lab traffic

**Validation:**
- Tested by attempting to ping home network from lab ✗
- Tested by attempting to reach fw-edge01 from lab ✗
- Tested internet access from lab ✓
- Tested Jumphost can reach lab ✓

**Lesson Learned:**
Critical decision. Multiple times during testing, "accidentally" tried to access production from lab. fw-lab01 blocked it every time. Peace of mind is worth the complexity.

---

## Technology Choices

### Decision 7: OPNsense vs pfSense

**Problem:** Which firewall OS for fw-edge01 and fw-lab01?

**Options Considered:**

**Option A: pfSense**
- Pros: More mature, larger community, more packages
- Cons: Netgate ownership concerns, licensing changes
- History: Industry standard for years

**Option B: OPNsense (Chosen)**
- Pros: Modern UI, frequent updates, open development
- Cons: Smaller community, fewer third-party packages
- Philosophy: Truly open source

**Option C: Commercial Firewall**
- Pros: Professional support, enterprise features
- Cons: Expensive, overkill for homelab
- Cost: $500-2000+ per year

**Decision:** OPNsense (Option B)

**Rationale:**
- Modern, clean web interface
- Frequent security updates
- Open development model
- Strong WireGuard support
- Free and open source
- Good documentation

**Experience:**
- Easy to configure
- WireGuard plugin works well
- Firewall rules straightforward
- Logging is comprehensive

**Trade-offs Accepted:**
- Smaller community than pfSense
- Fewer third-party packages
- Less "battle tested" in enterprise

**Validation:**
- Works reliably ✓
- WireGuard performance excellent ✓
- UI intuitive ✓
- Updates regular and stable ✓

**Lesson Learned:**
OPNsense strikes good balance for homelab. Modern interface makes configuration easier. Would choose again.

---

### Decision 8: Proxmox vs ESXi vs Hyper-V

**Problem:** Which virtualization platform?

**Options Considered:**

**Option A: VMware ESXi**
- Pros: Industry standard, powerful, well-known
- Cons: Licensing changes (Broadcom), future uncertain
- Cost: Free tier limited, enterprise expensive

**Option B: Proxmox VE (Chosen)**
- Pros: Open source, KVM-based, great web UI, free
- Cons: Less enterprise adoption, smaller ecosystem
- Community: Growing rapidly

**Option C: Microsoft Hyper-V**
- Pros: Free, Windows integration, enterprise support
- Cons: Windows-centric, less flexible
- Use case: Windows environments

**Decision:** Proxmox VE (Option B)

**Rationale:**
- Open source (no licensing concerns)
- Excellent web interface
- Supports VMs and containers (LXC)
- ZFS support built-in
- Active community
- Great for homelabs
- Free for all features

**Features Used:**
- VM templates for quick deployment
- Snapshots before risky changes
- Resource quotas for lab VMs
- Backup and restore
- Virtual networking for lab

**Trade-offs Accepted:**
- Less enterprise adoption (vs ESXi)
- Smaller third-party ecosystem
- Fewer professional certifications

**Validation:**
- Stable for months of uptime ✓
- Web UI accessible and intuitive ✓
- Snapshots saved multiple failed experiments ✓
- Resource management works well ✓

**Lesson Learned:**
Proxmox perfect for homelab. No licensing concerns, all features available, active development. ESXi licensing changes (Broadcom) validate this choice.

---

### Decision 9: TrueNAS Core vs TrueNAS SCALE

**Problem:** Which TrueNAS version for storage?

**Options Considered:**

**Option A: TrueNAS Core (FreeBSD)**
- Pros: Mature, stable, proven ZFS implementation
- Cons: FreeBSD-based (less familiar), plugins limited
- Stability: Rock solid

**Option B: TrueNAS SCALE (Linux) (Chosen)**
- Pros: Linux-based, Docker support, modern, active development
- Cons: Newer (less proven), ZFS on Linux
- Future: iXsystems' focus going forward

**Option C: Ubuntu with ZFS**
- Pros: Flexible, full OS control
- Cons: No nice web UI, manual ZFS management
- Risk: More room for configuration errors

**Decision:** TrueNAS SCALE (Option B)

**Rationale:**
- Linux-based (more familiar)
- Docker app support (future use)
- Modern web interface
- Active development focus by iXsystems
- ZFS still excellent on Linux
- Easy SMB/NFS setup

**Features Used:**
- ZFS pools for data integrity
- SMB shares for file access
- Snapshots for backup
- Replication (planned)

**Trade-offs Accepted:**
- Newer platform (less battle-tested)
- Migration path from Core (if chosen) would be complex
- ZFS on Linux vs native FreeBSD implementation

**Validation:**
- Stable operation ✓
- ZFS working perfectly ✓
- SMB performance good ✓
- Web UI excellent ✓

**Lesson Learned:**
Good choice for homelab. Docker support opens future possibilities. Linux familiarity helps with troubleshooting.

---

## Lab Design Decisions

### Decision 10: Four-VLAN Lab Segmentation

**Problem:** How to segment lab for realistic scenarios?

**Options Considered:**

**Option A: Flat Lab Network**
- Pros: Simple, no inter-VLAN routing
- Cons: Unrealistic, cannot practice segmentation attacks
- Value: Limited learning

**Option B: Two VLANs (Servers and Clients)**
- Pros: Simple, covers basic scenarios
- Cons: No separate attack network, less realistic
- Complexity: Low

**Option C: Four VLANs (Chosen)**
- Pros: Realistic enterprise layout, multiple attack paths
- Cons: More complex to manage
- Segments: Management, Servers, Clients, Attack

**Decision:** Four VLAN design (Option C)

**Rationale:**
- Mimics enterprise network structure
- Enables realistic attack scenarios
- Practice network pivoting
- Separate attack tools from targets
- Management VLAN for security

**VLAN Layout:**
- VLAN 1 (10.30.x.0/24): Management
- VLAN 10 (10.30.10.0/24): Servers (DC, SQL, Web, SIEM)
- VLAN 20 (10.30.20.0/24): Clients (Workstations)
- VLAN 66 (10.30.66.0/24): Attack (Kali, tools)

**Scenarios Enabled:**
- External pentest (Attack → Servers/Clients)
- Lateral movement (Client → Server pivot)
- Active Directory attacks
- Network segmentation bypass
- Detection engineering (Wazuh monitoring)

**Trade-offs Accepted:**
- More complex firewall rules
- Inter-VLAN routing overhead
- More IP address planning
- Additional VLAN configuration

**Validation:**
- Attack VLAN can reach Server/Client VLANs ✓
- Management VLAN access restricted ✓
- Realistic enterprise simulation ✓
- Multiple attack paths available ✓

**Lesson Learned:**
Worth the complexity. Four VLANs enable much more realistic scenarios. Practice mimics real penetration tests.

---

### Decision 11: Active Directory Lab Environment

**Problem:** What services to run in lab for realistic scenarios?

**Options Considered:**

**Option A: Standalone Vulnerable VMs Only**
- Pros: Simple, quick to setup
- Cons: Unrealistic, limited scenarios
- Value: Basic skill building

**Option B: Full Enterprise Stack (Chosen)**
- Pros: Realistic, enterprise AD attacks, complete environment
- Cons: Resource intensive, complex setup
- Components: DC, SQL, Web apps, clients

**Option C: HackTheBox VPN Only**
- Pros: Pre-built scenarios, variety
- Cons: No control over environment, no persistence
- Cost: Subscription required

**Decision:** Full enterprise stack (Option B)

**Rationale:**
- Active Directory attacks are critical skill
- Realistic enterprise environment
- Practice both offensive and defensive
- Persistent environment (not time-limited)
- Can customize for specific scenarios

**Components Deployed:**
- Domain Controller (Windows Server)
- SQL Server (vulnerable configurations)
- Web application servers
- Domain-joined workstations
- Wazuh SIEM for detection

**Scenarios Enabled:**
- Kerberoasting attacks
- Pass-the-Hash / Pass-the-Ticket
- DCSync attacks
- Golden Ticket creation
- SQL injection to domain admin
- Lateral movement through domain
- Detection and response practice

**Trade-offs Accepted:**
- Significant resource requirements (RAM, CPU)
- Windows licensing (evaluation or dev licenses)
- Complex setup and maintenance
- Requires AD knowledge to maintain

**Validation:**
- AD domain functional ✓
- Kerberos authentication working ✓
- Attack scenarios successful ✓
- Wazuh detecting attacks ✓

**Lesson Learned:**
High value for learning. AD attacks are fundamental for red/blue team. Having persistent environment allows deep practice. Resources well spent.

---

### Decision 12: Wazuh for Lab SIEM

**Problem:** How to practice detection and blue team skills?

**Options Considered:**

**Option A: No SIEM (Red Team Only)**
- Pros: Simple, fewer resources
- Cons: No blue team practice, cannot measure detection
- Learning: One-sided

**Option B: Splunk Free**
- Pros: Industry standard, powerful
- Cons: 500MB/day limit, complex for homelab
- Cost: Free tier limited

**Option C: Wazuh (Chosen)**
- Pros: Open source, full featured, no limits, XDR capabilities
- Cons: Learning curve, resource usage
- Community: Growing rapidly

**Option D: ELK Stack**
- Pros: Flexible, powerful, industry standard
- Cons: Complex setup, resource intensive, manual SIEM configuration
- Maintenance: High

**Decision:** Wazuh (Option C)

**Rationale:**
- Open source (no cost or limits)
- Purpose-built for security (vs general logging)
- Agent-based collection
- Pre-built detection rules
- File integrity monitoring
- Vulnerability detection
- XDR capabilities
- Good for learning blue team

**Deployment:**
- Wazuh server on VLAN 10 (Server segment)
- Agents on all lab VMs
- Monitoring all lab activity
- Alerts on suspicious behavior

**Use Cases:**
- Detect Kali scanning from VLAN 66
- Alert on Kerberoasting attempts
- Monitor file changes on DC
- Log PowerShell commands
- Track lateral movement

**Trade-offs Accepted:**
- Resource usage (Wazuh server needs RAM)
- Agent installation on all systems
- Alert tuning required
- Learning curve for rule creation

**Validation:**
- Agents reporting successfully ✓
- Detects port scans ✓
- Alerts on suspicious PowerShell ✓
- Dashboard provides visibility ✓

**Lesson Learned:**
Essential for complete learning. Red team without blue team is incomplete. Wazuh makes blue team practice accessible in homelab.

---

## Deferred Decisions

### Deferred 1: Home Network VLAN Segmentation

**Current State:** Flat network (VLAN 1)

**Plan:** Segment home network with VLANs

**Why Deferred:**
- Requires managed switch purchase ($200-500)
- Current flat network is functional and secure
- VPN has service-level access control (not network-level trust)
- Lab (where attacks happen) already segmented
- No immediate security concern

**Timeline:** Q2 2026 (after managed switch purchase)

**Planned VLANs:**
- VLAN 10: Management (firewall, switch)
- VLAN 20: Production (Proxmox, TrueNAS)
- VLAN 30: Lab WAN (fw-lab01 connection)
- VLAN 40: Guest (visitors)

**Dependencies:**
- Purchase managed switch
- Plan IP addressing for new VLANs
- Update firewall rules
- Migrate devices to new VLANs

---

### Deferred 2: Central SIEM for Home Network

**Current State:** Manual log review, Wazuh in lab only

**Plan:** Deploy SIEM for home network monitoring

**Why Deferred:**
- Lab SIEM priority (where attacks simulated)
- Home network has low threat exposure
- Manual log review adequate for current activity level
- Resource allocation to lab priorities

**Timeline:** Q3 2026 (after home VLAN segmentation)

**Options:**
- Extend Wazuh to home network
- Deploy separate SIEM instance
- Centralized logging to existing Wazuh

**Benefits:**
- Visibility into home network activity
- Detect anomalies on production services
- Centralized log management
- Correlation across all networks

---

### Deferred 3: High Availability

**Current State:** Single points of failure exist

**Plan:** Add redundancy for critical services

**Why Deferred:**
- Homelab can tolerate downtime
- Cost of redundant hardware significant
- Current setup reliable enough
- Learning focus, not production SLA

**Timeline:** 2027+ (long-term)

**Considerations:**
- Second Proxmox node for clustering
- Redundant firewall (CARP/VRRP)
- UPS for power protection
- Off-site backup replication

---

## Mistakes and Lessons Learned

### Mistake 1: Initial Direct Service Exposure

**What Happened:**
Early setup had Proxmox web UI exposed directly to internet on non-standard port.

**Problem:**
- Brute force attempts within hours
- Logs filled with failed logins
- Unnecessary attack surface

**Lesson Learned:**
Never expose management interfaces to internet, even on non-standard ports. Port scanners find everything.

**Solution:**
- Implemented WireGuard VPN
- All services behind VPN
- Only UDP 51820 exposed
- Attack traffic dropped to zero

**Impact:**
Dramatically reduced security risk. VPN approach is correct design.

---

### Mistake 2: Insufficient Lab Isolation Testing

**What Happened:**
Initially deployed fw-lab01 but didn't thoroughly test isolation.

**Problem:**
- Assumed firewall rules worked
- Didn't verify lab couldn't reach home network
- False confidence in isolation

**Lesson Learned:**
Trust but verify. Test isolation regularly, not just at deployment.

**Solution:**
- Created isolation validation script
- Runs from lab VM, attempts to reach home network
- Should fail 100% of the time
- Run after any firewall change

**Validation Script Example:**

    #!/bin/bash
    # Run from lab VM - all should FAIL
    
    echo "Testing lab isolation (all should timeout)..."
    ping -c 2 192.168.x.1 || echo "✓ Cannot reach fw-edge01"
    ping -c 2 192.168.x.241 || echo "✓ Cannot reach Proxmox"
    ping -c 2 192.168.x.240 || echo "✓ Cannot reach TrueNAS"
    
    echo "Testing internet (should succeed)..."
    ping -c 2 8.8.8.8 && echo "✓ Internet works"

**Impact:**
Regular testing catches configuration drift. Isolation validated continuously.

---

### Mistake 3: Over-complicated Initial VPN Config

**What Happened:**
First WireGuard setup had complex routing rules trying to enable everything.

**Problem:**
- Confusing configuration
- Hard to troubleshoot
- Not following zero trust principles
- Too much access granted

**Lesson Learned:**
Start minimal, add services explicitly. Zero trust means no default trust.

**Solution:**
- Removed all-access rules
- Created explicit rule per service
- Default deny on wg0 interface
- Added services only as needed

**Impact:**
Simpler configuration, better security, easier to understand and maintain.

---

### Mistake 4: Not Documenting from Day One

**What Happened:**
Built infrastructure, documented later (now).

**Problem:**
- Forgot some design decisions
- Had to reverse-engineer own setup
- Wasted time remembering why choices were made

**Lesson Learned:**
Document as you go, not after. Future you will thank present you.

**Solution:**
- Now maintaining this documentation
- Update with each change
- Include rationale, not just configuration
- Track lessons learned in real-time

**Impact:**
Better understanding of own infrastructure. Easier to maintain and improve.

---

## Future Considerations

### Consideration 1: 10 Gbps Networking

**Current:** 1 Gbps network

**Future:** Upgrade to 10 Gbps for storage traffic

**Rationale:**
- Large file transfers (backups, media)
- Multiple VM disk I/O
- Future-proofing

**Requirements:**
- 10 Gbps NIC for Proxmox
- 10 Gbps NIC for TrueNAS
- 10 Gbps switch or direct connection
- Cat6a/7 or fiber cabling

**Timeline:** 2027+ (when prices drop)

**Cost Estimate:** $300-500

---

### Consideration 2: Kubernetes Lab Cluster

**Current:** VM-based lab

**Future:** Add Kubernetes cluster for container workloads

**Rationale:**
- Learn container orchestration
- Practice cloud-native security
- Deploy microservices applications
- Red team container environments

**Architecture:**
- 3-node cluster (1 control, 2 workers)
- Separate VLAN in lab network
- Network policies for segmentation
- Service mesh for security

**Timeline:** Q3-Q4 2026

**Skills Developed:**
- Kubernetes administration
- Container security
- Cloud-native architecture
- DevSecOps practices

---

### Consideration 3: Advanced Threat Detection

**Current:** Basic SIEM with rules

**Future:** ML-based anomaly detection

**Technologies:**
- Zeek for network analysis
- Suricata for IDS/IPS
- Machine learning for anomaly detection
- Threat intelligence integration

**Goals:**
- Detect unknown threats
- Reduce false positives
- Automated response
- Advanced blue team skills

**Timeline:** 2027+ (requires significant learning)

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - What was built
- [NETWORK_TOPOLOGY.md](NETWORK_TOPOLOGY.md) - Network layout
- [SECURITY_ZONES.md](SECURITY_ZONES.md) - Security controls
- [TRAFFIC_FLOWS.md](TRAFFIC_FLOWS.md) - How it works
- [THREAT_MODEL.md](THREAT_MODEL.md) - What we're protecting against

---

Last Updated: February 2026
