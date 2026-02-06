# Kerberoasting Telemetry Validation

## Objective

Validate that Kerberos service ticket activity generated during a Kerberoasting attack is properly logged, ingested, searchable, and attributable within the SIEM under a **least-privileged SOC analyst role**.

This phase focuses on **telemetry correctness and visibility**, not alerting. Detection logic is intentionally deferred until data quality and identity context are confirmed.

---

## Environment Overview

**Domain**
- Active Directory: `lab.local`
- Domain Controller: `DC01.lab.local`

**Security Stack**
- SIEM: Wazuh (OpenSearch backend)
- Analyst Account: `soc_analyst` (read-only)
- Logging Source: Windows Security Event Log

**Network Architecture**
- Firewall-enforced VLAN segmentation
- Dedicated ATTACK VLAN
- Bastion / Jump host access model
- No east-west trust between VLANs

---

## Attack Simulation

### Technique
- **Kerberoasting**
- MITRE ATT&CK: `T1558.003`

### Tooling
- Impacket (`GetUserSPNs`)

### Execution (Attack Host)
```bash
impacket-GetUserSPNs LAB/username -dc-ip 10.30.x.x
