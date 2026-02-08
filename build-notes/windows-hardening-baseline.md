# Windows Hardening Baseline

## Purpose

This document describes the **baseline security posture** applied to Windows systems in the lab environment.

Hardening decisions are made deliberately to balance realism, attack simulation, and detection visibility.

---

## Baseline Scope

The baseline applies to:
- Domain Controller
- Domain-joined Windows clients

Hardening is applied consistently where it supports:
- Predictable behavior
- Reliable telemetry
- Meaningful attack simulation

---

## Applied Controls

### Audit Policy
- Security auditing enabled for authentication events
- Kerberos-related activity logged
- Account usage and service ticket requests visible

### Account Management
- Service accounts used intentionally for testing
- Privileged accounts limited in number
- Clear distinction between user and service identities

---

## Intentionally Relaxed Controls

Certain controls are intentionally **not fully hardened** to support detection testing:
- Service account configurations that allow Kerberoasting
- Authentication behaviors that mirror common enterprise misconfigurations

These decisions are documented and revisited as detection capability matures.

---

## Detection-First Considerations

Hardening is evaluated not only on prevention, but on:
- Whether attacker behavior remains observable
- Whether identity abuse generates detectable telemetry
- Whether changes reduce or improve detection fidelity

---

## Design Intent

The Windows baseline is not designed to represent a fully hardened environment.

Instead, it is designed to:
- Support realistic identity-based attacks
- Preserve investigative visibility
- Enable iterative improvement through detection and tuning

Hardening decisions evolve as detection capabilities improve.
