# Network Segmentation Design

This lab is segmented into distinct security zones to mirror enterprise trust
boundaries, reduce implicit access, and force reliance on **identity-aware
controls and detection**, not flat network trust.

Segmentation is enforced through firewall policy and validated through
connectivity testing and log visibility.

---

## Security Zones

- **Home Network**
  - Management access only
  - No direct access to internal lab segments

- **Jump / Bastion Host**
  - Sole administrative ingress point
  - SSH key–based access only
  - Used to reach internal management services

- **Servers**
  - Domain Controller
  - Infrastructure and application services
  - No outbound lateral initiation by default

- **Clients**
  - Domain-joined user systems
  - Limited access to required server services

- **Attack**
  - Dedicated adversary simulation network
  - No access to clients
  - Restricted, intentional access to servers for testing

---

## Access Model

| Source | Destination | Access | Purpose |
|------|------------|--------|--------|
| Home | Bastion | Allowed | Administrative entry point |
| Bastion | Servers | Allowed | Management and administration |
| Clients | Servers | Allowed (scoped) | Business-like access patterns |
| Attack | Servers | Allowed (intentional) | Adversary simulation |
| Attack | Clients | Denied | Prevent uncontrolled lateral spread |
| Servers | Any | Denied (by default) | Reduce implicit trust |

All access paths are **explicitly defined** and logged.

---

## Design Intent

This segmentation model is intentionally **not designed to stop identity-based
attacks outright**.

Instead, it is designed to:

- Prevent uncontrolled lateral movement
- Force attackers to rely on legitimate authentication paths
- Ensure malicious behavior is observable in logs
- Validate that detection logic works across trust boundaries

Identity abuse (e.g., Kerberoasting) is expected to succeed at the network
layer and be addressed through **telemetry, detection, and response**.

---

## Operational Validation

The following behaviors have been validated in practice:

- Firewall rules enforce directional trust
- DNS and authentication dependencies are explicitly permitted
- Attack traffic generates detectable authentication events
- Segmentation failures surface immediately as identity or logging issues

This confirms the segmentation model supports **realistic attack simulation**
and **SOC-style detection workflows**.

---

## Rationale

Flat networks hide identity abuse.
Over-segmentation hides telemetry.

This design balances isolation with observability, enforcing least privilege
while preserving realistic enterprise behavior.
