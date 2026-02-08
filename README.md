# Security Homelab – Automated Identity, Segmentation, and Detection

This repository documents the design, build, and evolution of a security-focused home lab intended to mirror **real-world enterprise security patterns**, not flat or tool-driven lab environments.

The lab is designed to explore how **identity systems, network segmentation, automation, and security telemetry** behave under realistic operational constraints — including when systems fail, controls are bypassed, or recovery must occur deliberately.

This is not a static lab. It is a **living environment** built to be deployed, attacked, observed, hardened, and rebuilt.

---

## Core Focus Areas

- Identity-centric security (Active Directory as a control plane)
- Enforced network segmentation and trust boundaries
- Infrastructure as Code and configuration automation
- Observable security behavior through validated telemetry
- Attack → Detect → Respond → Recover workflows
- Documentation of *why* decisions were made, not just *how*

---

## Current State

- Segmented network architecture with enforced trust boundaries
- Routed firewall controlling east/west traffic between VLANs
- Bastion (jump host) administrative access model
- Active Directory (Windows Server 2022) with DNS
- Domain-joined Windows client
- Initial adversary simulation against Active Directory
- Security-relevant logging validated at the source
- Manual build processes documented and repeatable

---

## Near-Term Capstone Direction

The lab is evolving into a **fully automated security capstone** that integrates:

- **Infrastructure as Code**  
  Reproducible deployment of virtual machines, networks, and access paths.

- **Configuration & Security Automation**  
  Baseline hardening, logging enforcement, and incident response actions executed programmatically.

- **Containerized Workloads**  
  Modern application targets deployed via containers to validate detection and response against realistic services.

- **AI-Assisted Security Analysis**  
  Log summarization, alert enrichment, and investigative support to improve analyst efficiency — not replace decision-making.

- **Recovery by Design**  
  Compromised systems are intentionally rebuilt rather than “patched in place” to reinforce immutable infrastructure concepts.

---

## Design Goals

- No implicit trust between zones
- Identity-aware security over perimeter-only controls
- Observable behavior through logs, not assumptions
- Automation over manual intervention where appropriate
- Build → break → detect → respond → rebuild → document

---

## Repository Structure
- `architecture/`     – Network, identity, and access model design decisions
- `ansible/`          – Configuration, hardening, and response automation
- `ai/`               – AI-assisted analysis scripts and workflows
- `attacks/`          – Adversary simulations performed against the lab
- `build-notes/`      – Key implementation details and rationale
- `detections/`       – Detection logic, telemetry validation, and analysis
- `docker/`           – Containerized workloads and security testing targets
- `terraform/`        – Infrastructure as Code definitions (in progress)
- `troubleshooting/`  – Real issues encountered and how they were resolved

---

## Guiding Principle

This repository prioritizes **security thinking and decision-making** over tooling.

Every configuration, attack, detection, and automation exists to answer a question:
> *How does this system actually behave under pressure?*

If something breaks, that failure is documented — not hidden — because understanding failure modes is part of building secure systems.

