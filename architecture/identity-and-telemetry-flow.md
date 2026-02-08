# Identity and Telemetry Flow

This document describes how authentication activity, identity decisions,
and security telemetry move through the lab.

---

## Identity Flow

- Authentication requests originate from clients or attack hosts
- Domain controllers perform Kerberos validation
- Successful abuse generates legitimate authentication events

---

## Telemetry Generation

- Domain controllers log authentication activity
- Events are forwarded to the SIEM
- Logs retain identity, host, and network context

---

## Detection Implications

- Identity-based attacks are observable, not blocked
- Network segmentation enforces boundaries but preserves visibility
- Detection depends on correct logging, not perimeter denial

---

## Design Intent

This lab prioritizes observability over false prevention, ensuring that
identity abuse techniques can be detected, analyzed, and tuned.
