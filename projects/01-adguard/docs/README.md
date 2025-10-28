# 01 — AdGuard Home | Documentation Index

> Centralized DNS sinkhole + DHCP for the homelab. See `/evidence` for reproducible proof and `/diagrams` for the network map.

## Quick links

- **Overview** → [OVERVIEW.md](./OVERVIEW.md)
- **How to deploy / re-deploy** → [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Runbook (day-2 ops)** → [RUNBOOK.md](./RUNBOOK.md)
- **Incident playbooks** → [INCIDENTS.md](./INCIDENTS.md)
- **Security & threat model** → [SECURITY.md](./SECURITY.md)
- **Network details** → [NETWORK.md](./NETWORK.md)
- **Changelog** → [CHANGELOG.md](./CHANGELOG.md)
- **References** → [REFERENCES.md](./REFERENCES.md)

## Project pointers

- Host: `192.168.1.10`
- Roles: DNS(53 TCP/UDP), DHCP(67/68 UDP), HTTP UI(80 TCP), SSH(22 TCP)
- DHCP scope: `192.168.1.100–200`, Gateway `192.168.1.254`
- Upstream: Quad9 DoH (`https://dns10.quad9.net/dns-query`)
- Evidence pack: `/projects/01-adguard/evidence/EVIDENCE.md`
- Diagram(s): `/projects/01-adguard/diagrams/`
