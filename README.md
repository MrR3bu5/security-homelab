# Security Homelab, Automated Identity, Segmentation, and Detection

This repository documents the design and evolution of a security focused home lab built to reflect enterprise security patterns instead of flat or tool driven environments.

The lab explores how identity, segmentation, automation, and security telemetry behave under operational pressure. Systems are deployed, tested, monitored, hardened, and rebuilt to validate detection and response workflows.

This is a living environment. The goal is continuous iteration through deployment, testing, observation, and recovery.

---

## Core Focus Areas

- Identity centric security with Active Directory as a control plane
- Enforced network segmentation and defined trust boundaries
- Infrastructure as Code and configuration automation
- Observable security behavior through validated telemetry
- Attack, detect, respond, recover workflows
- Documentation focused on decision making and tradeoffs

---

## Current State

- Segmented network architecture with enforced trust boundaries
- Routed firewall controlling east west traffic between VLANs
- Bastion host model for administrative access
- Active Directory on Windows Server 2022 with integrated DNS
- Domain joined Windows client systems
- Initial adversary simulation against identity services
- Security logging validated at the source
- Manual build processes documented and repeatable

---

## Near Term Capstone Direction

The lab is evolving into a fully automated security capstone that integrates:

### Infrastructure as Code
Reproducible deployment of virtual machines, networks, and access paths through Terraform.

### Configuration and Security Automation
Baseline hardening, logging enforcement, and response actions executed through automation.

### Containerized Workloads
Modern service targets deployed in containers to validate detection and response against realistic applications.

### AI Assisted Security Analysis
Log summarization, alert enrichment, and investigative support designed to improve analyst efficiency while preserving human decision making.

### Recovery by Design
Compromised systems are rebuilt instead of patched in place to reinforce immutable infrastructure practices.

---

## Design Goals

- No implicit trust between network zones
- Identity aware security instead of perimeter only controls
- Observable behavior through telemetry and logs
- Automation used where it improves consistency and reliability
- Build, break, detect, respond, rebuild, document

---

## Repository Structure

- `architecture/`     Network, identity, and access model decisions  
- `ansible/`          Configuration, hardening, and response automation (Moved to IaC Repo)
- `ai/`               AI assisted analysis workflows (Moved to AI Repo)
- `attacks/`          Adversary simulations performed against the lab  
- `build-notes/`      Implementation details and design rationale  
- `detections/`       Detection logic and telemetry validation  
- `docker/`           Container workloads and testing targets
- `terraform/`        Infrastructure as Code definitions (Moved to IaC Repo)
- `troubleshooting/`  Issues encountered and documented resolutions  

---

## Guiding Principle

This repository prioritizes security thinking and operational decision making over individual tools.

Each configuration, attack simulation, and detection exists to answer a single question:

> How does this system behave under real operational pressure?

Failures are documented as part of the process. Understanding failure modes is essential to building resilient and defensible systems.
