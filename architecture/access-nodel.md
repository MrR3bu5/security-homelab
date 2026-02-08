# Access Model

This lab enforces controlled access paths to reflect enterprise administrative
and SOC workflows.

---

## Administrative Access

- All administrative access occurs through a jump/bastion host
- Direct access to internal systems from the home network is not permitted
- SSH key–based authentication is required
- Per-device keys are used to support revocation and auditability

---

## Analyst Access

- SIEM access is restricted to least-privileged roles
- Analysts operate without administrative permissions
- Detection and investigation are performed through read-only access

---

## Design Intent

This model separates:
- Administration from observation
- Platform control from detection analysis
- Authentication from authorization

The goal is to prevent convenience-driven privilege escalation while supporting
realistic SOC workflows.
