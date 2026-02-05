# OPNsense Firewall Design and Policy Decisions

## Purpose
The firewall in this lab is not used as a perimeter-only control, but as an
enforcement point for trust boundaries between network segments.

Rather than relying on flat access or implicit trust, OPNsense is used to
explicitly define which systems may communicate, in which direction, and
under what conditions.

---

## Interface-Based Policy Model
Firewall rules are applied on a per-interface basis, with each interface
representing a distinct security zone.

This approach ensures that:
- Rules are evaluated in the context of traffic origin
- East/west traffic is explicitly controlled
- Policy intent remains clear and auditable

Rules are written to allow only what is required and deny everything else
by default.

---

## Segmentation Strategy
The lab is segmented into multiple VLAN-backed zones, including:

- Management / Home
- Bastion (Jump Host)
- Servers
- Clients
- Attack

Each zone has:
- Explicit ingress rules
- Limited egress permissions
- No implicit lateral access

Segmentation is enforced at Layer 3, not through host-based assumptions.

---

## Bastion-First Access Model
Administrative access to internal systems is intentionally restricted.

- Direct access from the home network to internal VLANs is denied
- Management traffic is permitted only via a dedicated jump host
- The jump host acts as a choke point for administrative activity

This mirrors common enterprise patterns and enables clearer logging and
accountability.

---

## Rule Evaluation and Ordering
OPNsense evaluates rules on a first-match basis.

This required careful attention to:
- Rule ordering
- Explicit allow rules before broader deny rules
- Logging on both allow and deny paths

Several early issues in the lab were traced back to rule evaluation order
rather than missing rules.

---

## NAT and Traffic Flow Awareness
One of the most significant learning points was understanding pre-NAT vs
post-NAT traffic evaluation.

Key observations:
- Firewall rules are evaluated before NAT translation
- Destination NAT does not bypass interface policy
- Logging must be interpreted with NAT context in mind

Debugging NAT-related issues required validating:
- Rule matching interfaces
- Original source/destination addresses
- Post-translation behavior

---

## Logging Strategy
Firewall logging is enabled selectively to support troubleshooting and
learning without generating excessive noise.

Logging is used to:
- Validate rule matches
- Confirm expected traffic flows
- Correlate network behavior with identity-based logs

Firewall logs are treated as supporting evidence rather than primary
detection signals.

---

## Security Takeaways
- Network segmentation reduces attack surface but does not stop identity abuse
- Firewalls enforce boundaries, not intent
- Visibility and correctness matter more than rule count
- Understanding traffic evaluation order is critical for accurate troubleshooting

---

## Conclusion
OPNsense serves as a foundational enforcement layer in this lab, providing
clear trust boundaries and traffic control.

However, the lab intentionally demonstrates that network controls alone are
insufficient against identity-based attacks, reinforcing the need for
identity-aware logging and detection.

