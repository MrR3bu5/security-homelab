# Security Homelab – Identity, Segmentation, and Detection

This repository documents the design, build, and evolution of a security-focused
home lab intended to mirror real-world enterprise patterns rather than flat,
tool-driven lab environments.

The focus of this lab is understanding how identity systems, network segmentation,
and security telemetry behave under realistic constraints — including when things
break and must be debugged deliberately.

## Current State
- Segmented network architecture with enforced trust boundaries
- Routed firewall controlling east/west traffic
- Bastion (jump host) administrative access model
- Active Directory (Windows Server 2022) with DNS
- Domain-joined Windows client
- Initial adversary simulation against Active Directory
- Security-relevant logging validated at the source

## Design Goals
- No implicit trust between zones
- Identity-aware security over perimeter-only controls
- Observable behavior through logs, not assumptions
- Build → break → fix → document

## Repository Structure
- `architecture/` – Network and access model design decisions
- `build-notes/` – Key implementation details and rationale
- `attacks/` – Adversary simulations performed against the lab
- `detections/` – Detection logic and security observations
- `troubleshooting/` – Real issues encountered and how they were resolved

This repository prioritizes **why decisions were made** as much as **how systems
were configured**.
