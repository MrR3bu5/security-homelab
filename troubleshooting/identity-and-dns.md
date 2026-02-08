# Identity & DNS Troubleshooting

## Context

This document captures troubleshooting performed while integrating Active Directory, DNS, and DHCP into a segmented lab environment.

Identity services introduced implicit dependencies that immediately surfaced misconfigurations.

---

## Issues Encountered

### 1. Domain Join Failures Across VLANs

**Symptoms**
- Windows client unable to join domain
- Authentication attempts timed out

**Root Cause**
- Required ports for AD authentication were blocked
- DNS resolution for domain controller was incomplete

**Resolution**
- Validated required AD ports (LDAP, Kerberos, SMB)
- Ensured DNS requests resolved to the correct domain controller
- Confirmed firewall rules allowed identity traffic only where intended

**Lesson Learned**
> Identity systems assume broad network access unless constrained deliberately.

---

### 2. DHCP Options Missing DNS Information

**Symptoms**
- Clients received IP addresses but could not resolve domain names

**Root Cause**
- DNS server option not provided via DHCP
- Incorrect assumption that domain join would populate DNS automatically

**Resolution**
- Explicitly configured DHCP to advertise the domain controller as DNS server
- Validated lease information on client systems

**Lesson Learned**
> DHCP and DNS are tightly coupled in domain environments and must be configured together.

---

### 3. Name Resolution Failing from Jump Host

**Symptoms**
- SSH access worked
- Internal hostnames did not resolve

**Root Cause**
- Jump host not configured to use domain DNS
- Firewall rules blocked DNS responses

**Resolution**
- Updated system resolver configuration
- Allowed DNS traffic explicitly between networks

**Lesson Learned**
> Access does not imply visibility — DNS must be explicitly designed.

---

## Key Takeaways

- Identity introduces dependencies that segmentation exposes immediately
- DNS failures often masquerade as authentication failures
- Troubleshooting identity requires validating network, DNS, and authentication layers together
