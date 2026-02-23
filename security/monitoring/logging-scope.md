# Logging Scope and Telemetry Decisions

## Purpose

This document defines **what is logged, why it is logged, and what is intentionally excluded** from the lab’s telemetry scope.

The goal is to balance observability with signal quality, rather than ingesting data indiscriminately.

---

## Logging Principles

- Log what supports detection and investigation
- Avoid noise that does not provide actionable context
- Preserve identity and authentication visibility
- Favor quality over volume

---

## Logged Sources

### Domain Controller
- Windows Security Event Log
- Authentication and authorization events
- Kerberos ticket activity
- Account usage and service interactions

### Firewall
- Allowed and denied traffic at trust boundaries
- Administrative access paths
- Attack simulation traffic visibility

### Jump Host
- Authentication events
- Administrative access attempts

---

## Limited or Excluded Sources

The following are intentionally limited or excluded at this stage:
- Full workstation application logs
- High-volume system performance logs
- Network packet captures

These sources may be introduced later for targeted use cases, but are not required for current detection objectives.

---

## Design Tradeoffs

### Accepted Tradeoffs
- Reduced log volume in exchange for clearer signal
- Some forensic depth sacrificed for simplicity and clarity

### Intentional Constraints
- Logging scope aligns with current detection goals
- Expansion is driven by need, not availability

---

## Design Intent

The logging strategy is designed to:
- Support identity-focused detection
- Enable efficient investigation by analysts
- Avoid overwhelming the SIEM with low-value data

Telemetry scope evolves alongside detection maturity.
