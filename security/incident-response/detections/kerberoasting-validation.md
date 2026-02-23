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
```

## Expected Behavior

- Kerberos TGS requests are generated
- No authentication failures occur
- Legitimate Kerberos functionality is abused
- Service account ticket material is retrievable

---

## Telemetry Observed

### Primary Event
- **Event ID:** 4769  
- **Log Source:** Microsoft Windows Security Auditing  
- **Description:** Kerberos service ticket requested  

### Key Fields Validated

| Field | Purpose |
|------|--------|
| `event.code` | Kerberos TGS activity |
| `winlog.event_data.ServiceName` | Targeted SPN |
| `user.name` | Requesting account |
| `source.ip` | Originating host |
| `host.name` | Domain controller |
| `winlog.channel` | Security |

---

## SIEM Validation (Analyst View)

All validation was performed using the **read-only `soc_analyst` account**, confirming proper RBAC enforcement.

### Base Query
```text
event.code:4769
```

### SPN-Focused Query

```text
event.code:4769 AND winlog.event_data.ServiceName:*$
```

### Results
- Kerberos service ticket requests are visible
- Source IP correlates to the ATTACK VLAN
- SPN usage is attributable to specific service accounts
- Domain controller is correctly identified as the event source

---

## RBAC Validation

The following access model was validated during this phase.

### Analyst Capabilities
- Search Wazuh indices
- View Kerberos authentication events
- Correlate identity and network context

### Analyst Restrictions
- Cannot modify detection rules
- Cannot edit ingestion pipelines
- Cannot delete indices
- Cannot alter SIEM configuration

This confirms **proper separation of duties** between SOC analyst and platform administration roles.

---

## Security Insights

- Kerberoasting generates **legitimate authentication events**
- No exploit signatures or malware indicators are present
- Effective detection requires:
  - Behavioral analysis
  - Volume and pattern awareness
  - Contextual filtering (source host, account type, host role)
- Reliable detection depends on:
  - Correct Windows auditing
  - Consistent log ingestion
  - Identity-aware telemetry

---

## Key Takeaway

> Detection engineering begins with validating data quality and access boundaries before writing alerts.
