# Jump Host (Bastion) Build Notes

## Purpose

The jump host serves as the **single controlled administrative entry point** into the lab environment.  
It enforces access discipline, limits exposure of internal systems, and mirrors enterprise bastion host patterns.

No direct administrative access to internal servers or infrastructure is permitted from external or home networks.

---

## Role in the Lab

The jump host is used to:
- Perform administrative access to internal systems
- Act as a controlled pivot point across segmented networks
- Enforce authentication hygiene and access auditing
- Reduce the attack surface of internal hosts

It is **not** used for:
- Daily user activity
- Development work
- Hosting services

---

## Network Placement

- Resides in a dedicated management segment
- Accessible only from the home network or VPN
- Has controlled, explicit access to internal lab networks
- No inbound access from client or attack networks

All access paths through the jump host are **explicitly defined and logged**.

---

## Authentication Model

### SSH-Based Access
- SSH is the only remote access method enabled
- Password-based authentication is disabled (or intentionally phased out)
- Public key authentication is enforced

### Per-Device SSH Keys
- Each administrator device uses a **unique SSH key**
- Keys are associated with a single user account
- Multiple keys are authorized for the same account to support:
  - Desktop access
  - Laptop/offsite access
  - Individual key revocation

This model improves auditability and limits blast radius in the event of device compromise.

---

## Access Controls

- Direct SSH access to internal servers is not permitted
- All administrative traffic must traverse the jump host
- Firewall rules enforce:
  - Source restrictions
  - Destination restrictions
  - Directional trust

The jump host acts as both a **technical and procedural control**.

---

## Security Controls

- Minimal software footprint
- No unnecessary services exposed
- SSH access restricted by firewall policy
- Strong authentication with passphrase-protected keys
- Logging enabled for authentication events

These controls reduce the likelihood that the jump host becomes a lateral movement vector.

---

## Design Tradeoffs

### Accepted Tradeoffs
- Slight administrative friction in exchange for stronger access control
- Centralized access point introduces dependency on jump host availability

### Intentional Decisions
- Convenience-driven shortcuts (direct server access) are avoided
- Access discipline is prioritized over speed
- The model favors realism over ease of use

---

## Design Intent

The jump host enforces a clear separation between:
- External access and internal management
- Human access and system trust
- Convenience and security

This design ensures that administrative access paths are **predictable, observable, and defensible**, supporting both operational security and realistic SOC workflows.
