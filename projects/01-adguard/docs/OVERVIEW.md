# Overview

AdGuard Home runs on `192.168.1.10` and acts as:

- **DNS sinkhole** for the LAN (blocks trackers/ads at DNS).
- **Authoritative DHCPv4** for the LAN (hands out `192.168.1.100–200`).
- **DoH upstream** to Quad9 with fallbacks.
- **Single-pane UI** for allow/deny lists, logs, and settings.

## Architecture (at a glance)

- **LAN 192.168.1.0/24**
  - Clients (e.g., Mac `192.168.1.101`, iPhone `192.168.1.102`) → **AdGuard** for DNS & DHCP
  - AdGuard → **Quad9 DoH** for recursion
  - Router `192.168.1.254` = default gateway/NAT to Internet
- **Security**
  - UFW allows only: 53/tcp+udp, 67/udp, 68/udp, 80/tcp, 22/tcp (from LAN)
  - Optional DNSSEC and ECS off/on per policy
- **Why this design**
  - Central control, privacy, predictable names, easy troubleshooting
  - Evidence-driven verification (see `/evidence/EVIDENCE.md`)
