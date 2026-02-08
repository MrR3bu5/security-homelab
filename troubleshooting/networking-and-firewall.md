# Networking & Firewall Troubleshooting

## Context

This document captures real-world networking and firewall issues encountered while building a segmented home security lab using Proxmox, OPNsense, and VLAN-based isolation.

The goal was not to achieve connectivity quickly, but to **understand why traffic was allowed or denied** at each stage.

---

## Common Issues Encountered

### 1. VLAN Traffic Passing Unexpectedly

**Symptoms**
- Hosts in isolated VLANs could reach unintended networks
- Ping succeeded when it should have failed

**Root Cause**
- Firewall rules were evaluated pre-NAT instead of post-NAT
- Implicit allow rules existed above intended block rules

**Resolution**
- Reviewed rule order and evaluation direction
- Explicitly blocked RFC1918 networks where appropriate
- Used logging to validate rule matches

**Lesson Learned**
> Firewall behavior must be validated through logs and packet flow, not assumptions.

---

### 2. SSH Access Failing Through NAT

**Symptoms**
- SSH connection timed out
- Port forwarding rule appeared correct
- Service confirmed running on target host

**Root Cause**
- Destination NAT rule existed without a matching WAN firewall rule
- Port mismatch between forwarded port and client connection

**Resolution**
- Verified WAN firewall rule explicitly allowed forwarded port
- Confirmed destination IP and port mapping
- Used firewall logs to confirm rule hits

**Lesson Learned**
> NAT rules do not implicitly allow traffic — firewall rules still apply.

---

### 3. DNS Failing Across Segmented Networks

**Symptoms**
- Host could resolve external domains but not internal names
- `ping hostname` failed while `ping IP` succeeded

**Root Cause**
- DNS traffic was blocked by lateral movement rules
- DNS server placement not explicitly allowed in firewall policy

**Resolution**
- Added explicit DNS allow rules (TCP/UDP 53)
- Scoped rules to specific source and destination networks

**Lesson Learned**
> DNS is often the first service impacted by segmentation and must be intentionally permitted.

---

## Key Takeaways

- Always validate connectivity with logs, not intuition
- Rule order and evaluation direction matter
- Segmentation failures are often policy-related, not configuration-related
