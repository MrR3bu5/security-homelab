# SIEM Deployment Notes

## Purpose

The SIEM is deployed to provide **centralized visibility into authentication, identity activity, and security-relevant events** across the lab environment.

The goal of this deployment is not tool familiarity, but to support **realistic SOC workflows**, including detection validation, investigation, and role-based access control.

---

## Platform Selection

- SIEM Platform: **Wazuh**
- Backend: OpenSearch
- Components:
  - Wazuh Manager
  - Indexer
  - Web Dashboard

Wazuh was selected due to:
- Native Windows event ingestion
- Strong Active Directory visibility
- Support for custom detection logic
- Built-in RBAC capabilities

---

## Deployment Model

- Single-node deployment aligned with lab scale
- Centralized ingestion from:
  - Domain Controller
  - Selected Windows clients
- Network access restricted by firewall policy
- Management access limited to administrative paths

The deployment prioritizes **correct data flow and access control** over horizontal scalability.

---

## Data Sources Ingested

Currently ingested sources include:
- Windows Security Event Logs (Domain Controller)
- Authentication and Kerberos-related events
- Host and source network context

The ingestion scope is intentionally constrained to:
- Preserve signal quality
- Reduce unnecessary noise
- Support focused detection development

---

## Access Model Integration

- SIEM access is role-based
- Analysts operate using **least-privileged read-only accounts**
- Administrative access is restricted and separate from analyst workflows

RBAC enforcement is treated as a core design requirement, not an optional feature.

---

## Design Intent

The SIEM deployment is designed to:
- Support identity-based attack detection
- Preserve investigative context across events
- Enable validation of telemetry before alerting
- Mirror enterprise SOC access patterns

Detection logic is introduced only after telemetry correctness and analyst visibility are confirmed.
