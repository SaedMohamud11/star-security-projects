# CHANGELOG.md — AdGuard Home (DNS/DHCP) Project

Single source of truth for **what changed, when, why, and how it was validated**.  
Newest entries at the top. Each entry includes a **rollback hint** and links to **evidence** and **runbook** checks.

---

## How to use this file (2-minute rules)

- **Log every change** that can alter *reachability, security, performance,* or *state*: DNS/DHCP options, upstreams, filters/policies, firewall, addressing, reservations, system updates, service config, hardware.
- **Before you change**: capture a quick snapshot (see `../evidence/EVIDENCE.md` and Runbook probes).  
- **After you change**: run validation steps and paste outputs/links.  
- **Rollback plan**: write it *before* the change; confirm success/failure after.

**Tags** (use in bullets): `[Added] [Changed] [Fixed] [Removed] [Security] [Deprecated]`

Cross-refs:
- Evidence pack: `../evidence/EVIDENCE.md`
- Runbook: `../docs/RUNBOOK.md`
- Incidents playbooks: `../docs/INCIDENTS.md`
- Network reference: `../docs/NETWORK.md`

Time format: **local date** `YYYY-MM-DD`. Keep **one entry per cohesive change**.

---

## 2025-10-28 — Docs & Diagrams Published (no functional change)

**Author:** Saed  
**Risk:** None

**What changed**
- `[Added]` Project diagrams:
  - `../diagrams/adguard-homelab-2025-10-28.svg`
  - `../diagrams/adguard-homelab-2025-10-28.png`
- `[Added]` Operational docs: `RUNBOOK.md`, `INCIDENTS.md`, `SECURITY.md`, `NETWORK.md`, `DEPLOYMENT.md`, and this `CHANGELOG.md`.

**Why**
- Establish a repeatable, auditable operational baseline with clear procedures.

**Validation**
- Visual inspection; cross-checked labels/ports/subnets vs `NETWORK.md`.  
- No service restarts or config edits.

**Rollback**
- Not required (docs only). Revert the commit if needed.

**Follow-ups**
- Add DHCP reservations table to `NETWORK.md` when MACs are finalized.

---

## 2025-10-21 — Initial Bring-Up: AdGuard Home + DoH + DHCP + UFW

**Author:** Saed  
**Risk:** Medium (authoritative DHCP migration to AdGuard)

**What changed**
- `[Added]` **AdGuard Home** service on **`192.168.1.10`** providing:
  - **DNS** on **53/tcp, 53/udp**.
  - **DHCP** on **67/udp, 68/udp**.
- `[Added]` Upstream resolver set to **Quad9 DoH**: `https://dns10.quad9.net/dns-query`.
- `[Added]` **DHCP scope** `192.168.1.100–200` with **router/GW** `192.168.1.254` and **DNS** `192.168.1.10`.
- `[Security]` **UFW inbound allow**: `53/tcp, 53/udp, 67/udp, 68/udp, 80/tcp (UI), 22/tcp (SSH)`; default-deny others.
- `[Removed]` Disabled router’s built-in **DHCP** to prevent dual-DHCP conflict.

**Why**
- Centralized ad/tracker sinkhole and policy control; encrypted upstream (DoH) to reduce on-path visibility.

**Pre-change snapshots**
- Router DHCP state (note/screenshot).
- Client resolver snapshot (e.g., macOS `scutil --dns`, Windows `ipconfig /all`).
- UFW baseline: `sudo ufw status numbered`.

**Change summary**
1. Installed/started AdGuard Home.
2. Configured **DoH** upstream → Quad9.
3. Enabled **DHCPv4** scope and options (GW/DNS).
4. Added UFW allows for DNS/DHCP/HTTP/SSH.
5. Disabled DHCP on router; confirmed only one DHCP server responds.

**Validation (post-change)**
- Full **evidence pack** captured (see files list below and `../evidence/EVIDENCE.md`).
- Runbook quick probes:
  ```bash
  dig @$ADGUARD_IP example.com +time=2 +tries=1 +short
  dig @$ADGUARD_IP doubleclick.net +time=2 +tries=1 +short
  curl -sI https://dns10.quad9.net/dns-query | head -n1
  sudo ufw status numbered
  
**Observed results**
- Positive domains resolve with low latency; ad domains return **NXDOMAIN/blocked**.
- Clients receive leases from AdGuard; router remains default gateway.

**Rollback**
1) Re-enable router DHCP; disable AdGuard DHCP.  
2) Push clients back to router DNS via DHCP option or manual setting.  
3) If necessary, stop service:
   ```bash
   sudo systemctl stop AdGuardHome
   ```
4) Revert UFW rule additions (or `ufw reset` and re-apply prior baseline).

**Follow-ups**
- Add static reservations (NAS/Proxmox/VM nginx) and document MACs in `NETWORK.md`.
- Consider enabling **DNSSEC** after one week of stable operation.

---

## Template — Copy for future changes

### YYYY-MM-DD — <Short title of change>
**Author:** <name>  
**Risk:** Low / Medium / High

**What changed**
- `[Added]/[Changed]/[Fixed]/[Security]/[Removed]` …

**Why**
- <Motivation: bug, performance, security, maintenance>

**Pre-change snapshots**
- <commands/links: current config, UFW status, leases.json head, screenshots>

**Change steps (summary)**
- Step 1 …
- Step 2 …

**Validation (post-change)**
- <commands/outputs / links to `evidence/` images>  
- <runbook checks invoked>

**Observed results**
- <latency, correctness, absence of errors, etc.>

**Rollback (quick)**
- <clear steps>  
- <verification after rollback>

**Follow-ups**
- <tickets, reminders, next actions>

---

## Quick index of evidence (2025-10-21 run)

All paths are relative to this file.

- `../evidence/runs/2025-10-21/dig-latency-20251021.png`  
- `../evidence/runs/2025-10-21/dig-tests-20251021.png`  
- `../evidence/runs/2025-10-21/mac-dns-servers-20251021.png`  
- `../evidence/runs/2025-10-21/ufw-rules-added-20251021.png`  
- `../evidence/runs/2025-10-21/adguard-yaml-20251021.png`  
- `../evidence/runs/2025-10-21/dhcp-leases-20251021.png`  
- `../evidence/runs/2025-10-21/ports-listening-20251021.png`  
- `../evidence/runs/2025-10-21/adguard-service-20251021.png`  
- `../evidence/runs/2025-10-21/ufw-status-20251021.png`  
- `../evidence/runs/2025-10-21/querylog-block-hit-20251021.png`  
- `../evidence/runs/2025-10-21/dhcp-scope-20251021.png`  
- `../evidence/runs/2025-10-21/settings-dns-20251021.png`  
- `../evidence/runs/2025-10-21/dashboard-20251021.png`

---

