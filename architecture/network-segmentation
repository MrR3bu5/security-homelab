# Network Segmentation Design

The lab is segmented into distinct security zones to mirror enterprise trust
boundaries and reduce implicit access.

## Security Zones
- Home Network (management only)
- Jump/Bastion Host
- Servers
- Clients
- Attack

## Access Model
- Administrative access occurs only through the bastion
- Clients may access servers but not attack hosts
- Attack hosts may reach servers for testing, but not clients
- Servers cannot initiate lateral connections

## Rationale
This design enforces least privilege and ensures that identity-based attacks
cannot be mitigated by network controls alone.
