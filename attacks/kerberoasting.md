# Kerberoasting – Active Directory Service Ticket Abuse

## Objective
Demonstrate how a low-privileged domain user can request Kerberos service tickets
for SPN-backed accounts and extract crackable material without exploiting a vulnerability.

## Preconditions
- Active Directory domain (lab.local)
- Service account with SPN configured
- Domain-joined client
- Network segmentation enforced
- Attacker with valid domain credentials

## Attack Summary
A non-administrative domain user authenticated to Active Directory and requested
Kerberos service tickets for a service account. The request succeeded and generated
standard authentication logs.

## Observed Telemetry
- Windows Security Event ID 4769 (Kerberos Service Ticket Requested)
- Source: Domain Controller
- Account: Low-privileged user
- Result: Audit Success

## Key Observations
- No firewall alerts were generated
- No exploit was required
- Activity appears legitimate without contextual analysis

## Defensive Takeaways
- Kerberoasting cannot be detected via network controls alone
- Detection requires identity-aware logging and correlation
- Monitoring for anomalous service ticket request patterns is critical

## Next Steps
- Forward AD logs to SIEM
- Create detection logic for abnormal 4769 behavior
