# Active Directory Design and Security Considerations

## Purpose
Active Directory was intentionally introduced only after network segmentation,
firewall policy enforcement, and access controls were validated.

This sequencing ensured that identity behavior could be observed within clearly
defined trust boundaries rather than a flat, permissive network.

The goal was to study how identity systems behave when network assumptions are
explicitly enforced.

---

## Role of Active Directory in the Lab
Active Directory serves as the central identity authority for the lab.

It provides:
- Authentication and authorization
- Service identity (via SPNs)
- Trust relationships between systems
- A realistic attack surface independent of network controls

Once introduced, identity immediately became the dominant security factor in the environment.

---

## Domain Design
The lab uses a single Active Directory forest and domain:

- Forest: Single
- Domain: `lab.local`
- Domain Controller: Windows Server 2022
- DNS: Integrated with AD

This design mirrors common small-to-mid enterprise environments and avoids
unnecessary complexity while preserving realistic behavior.

---

## Identity Trust Assumptions
One of the most important observations after deploying Active Directory was the
number of implicit assumptions it makes about the environment:

- Reliable DNS resolution
- Consistent network reachability
- Trusted internal clients
- Legitimate use of authentication protocols

When these assumptions are challenged through segmentation or attack simulation,
unexpected behavior and failures surface quickly.

---

## Client Integration
A Windows client was joined to the domain across segmented networks.

This validated:
- Correct DNS and DHCP dependency handling
- Controlled identity traffic flow
- Firewall policy alignment with authentication requirements

Successful domain joins did not require broad network access, reinforcing that
identity systems can function within constrained environments when dependencies
are well understood.

---

## Service Accounts and Attack Surface
Service accounts were introduced to support realistic application behavior.

These accounts:
- Operate outside interactive user workflows
- Commonly have long-lived credentials
- Are frequently misconfigured in real environments

The presence of service accounts immediately expanded the attack surface,
enabling identity-based attacks without exploiting software vulnerabilities.

---

## Security Observations
After deploying Active Directory, the lab demonstrated that:

- Network segmentation does not prevent identity abuse
- Legitimate authentication mechanisms can be weaponized
- Firewalls provide no visibility into credential misuse
- Security telemetry must include identity context

This shifted the focus of the lab from “can traffic reach a system” to
“should this identity be performing this action.”

---

## Defensive Implications
From a defensive perspective, Active Directory introduces the need for:

- Identity-aware logging
- Behavioral analysis of authentication events
- Monitoring service account usage
- Correlating identity activity with system context

These considerations directly informed the decision to add centralized logging
and SIEM capabilities in later phases of the lab.

---

## Conclusion
Active Directory transformed the lab from a segmented network environment into
a true identity-centric security platform.

It highlighted the limitations of network-only controls and reinforced the
importance of visibility, context, and detection when protecting modern
enterprise environments.

