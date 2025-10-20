# AdGuard Home — STAR Case Study (Project 01)

> **Resume one-liner (STAR)**  
> **S**: Home network lacked centralized DNS control/visibility.  
> **T**: Deploy DNS filtering (and optional DHCP) with clear SLOs for latency, block rate, and zero-downtime cut-over.  
> **A**: Built a hardened Debian 13 VM on Proxmox running AdGuard Home; designed IP plan, UFW rules, safe cut-over/rollback; captured metrics and detections.  
> **R**: p95 DNS latency ~**11 ms** (avg **5.8 ms**) via AdGuard; confirmed ad/tracker blocking; DHCP running with active leases.

## 0) Executive Summary
- **Role:** Designer & implementer (solo)  
- **Environment:** Proxmox VE on HP ProDesk (bare metal), Debian 13, AdGuard Home  
- **Outcome:** Centralized DNS filtering + DHCP; measurable latency; evidence captured

---

## 1) SITUATION
- **Gateway:** `192.168.1.254` (ISP router)  
- **Proxmox host:** `192.168.1.200` (static), bridge `vmbr0` → NIC `enp1s0`  
- **AdGuard VM:** `192.168.1.10/24` (interface `ens18`)  
- **FQDN:** `adguard.saed-server.local`  
- **Risk:** malvertising/phishing domains; no DNS visibility/policy

## 2) TASK
- **SLOs/KPIs**
  - DNS latency **≤ 20 ms p95** on LAN  
  - Block rate **≥ 30%** baseline  
  - Cut-over impact **< 5 min** with tested rollback  
  - Query logs retained **14–30 days**, privacy-conscious
- **Definition of done**
  - Metrics table populated; screenshots in `./evidence`; rollback tested/logged

## 3) ACTION
- Created Debian 13 VM on Proxmox; enabled QEMU guest agent  
- Static IP `192.168.1.10/24`, GW `192.168.1.254`  
- Installed AdGuard Home; enabled DHCP; configured blocklists  
- **UFW**: allowed DNS (53 TCP/UDP), DHCP (67/68 UDP), SSH (22); UI on 80  
- Validated with client tests (`dig`, latency loop); captured outputs

### Architecture (Mermaid)
~~~mermaid
flowchart LR
  R[Router 192.168.1.254] <--LAN--> P[Proxmox Host 192.168.1.200]
  P --> V[VM: Debian 13 @ 192.168.1.10]
  V --> A[AdGuard Home (DNS + DHCP)]
  A --> U[(Upstreams)]
  A --> L[(Logs / Metrics)]
~~~

### Configs (sanitized)
- **Network (VM):** `192.168.1.10/24`, GW `192.168.1.254`  
- **UFW (key rules):**
  - `53/tcp, 53/udp` **ALLOW IN** from LAN  
  - `67/udp, 68/udp` **ALLOW IN** (DHCP)  
  - `22/tcp` **ALLOW IN** from `192.168.1.0/24` and `OpenSSH`  
  - `80/tcp` **ALLOW IN** (UI) *(will restrict later)*
- **AdGuard YAML highlights** (`/opt/AdGuardHome/AdGuardHome.yaml`):
  - `protection_enabled: true`  
  - `enable_dnssec: false` *(will add validating resolver later)*  
  - `dhcp: true` with active v4 leases

### Automation/IaC
- `scripts/dns_latency_test.sh` (below) to sample DNS latency  
- *(Future)* Ansible role to provision Debian + AdGuard + UFW

## 4) RESULT
**Metrics (initial):**
| Metric | Before | After | How measured |
|---|---:|---:|---|
| DNS latency avg (ms) | — | **5.8** | `dig` 10× to `cloudflare.com` |
| DNS latency p95 (ms) | — | **~11** | 10-sample set |
| Block behavior | — | `doubleclick.net → 0.0.0.0` | `dig` to AdGuard |
| DHCP leases (#) | — | **27** (at time of capture) | AdGuard logs |

- Reliability/perf notes: consistent 3–11 ms responses on LAN.  
- Learning: DNSSEC not yet validated locally (upstream may set `ad` flag).

## 5) DETECTIONS & RUNBOOKS
- **Threat model:** mitigates malvertising/phishing/trackers at DNS layer; won’t stop in-app ads over E2E APIs.  
- **Detection ideas:**
  - Spike in blocked domains vs. baseline (possible malware beaconing / misconfig)
  - Top blocked domain by client; repeated NXDOMAIN bursts
- **Runbook RB-01 — DNS Block Spike**
  1. Confirm spike window & client in AdGuard logs  
  2. Pivot on domain to intel (VT/open-source lists)  
  3. Inspect device change history; isolate (VLAN/port) if needed  
  4. Decide allow/deny; document false positives  
  5. Post-event metrics update & notes
- **(Optional) MITRE:** T1071.004 (DNS C2)

## 6) SECURITY DECISIONS & TRADE-OFFS
- **Logging vs privacy:** retain 14–30 days; aggregate after  
- **TLS/admin surface:** UI currently on 80/tcp; restrict to admin IP and add TLS later  
- **HA:** single DNS/DHCP; add secondary or router fallback later  
- **IPv6:** align blocking before enabling network-wide

## 7) OPERATIONS
- **Backups:** Proxmox snapshot pre-change; export AdGuard config weekly  
- **Health checks:** `systemctl status AdGuardHome`, latency script (cron)  
- **Rollback:** re-enable router DNS/DHCP → stop AdGuard → flush client DNS caches — *(tested: date/result)*

## 8) REPRODUCE
- **Prereqs:** Proxmox host; Debian 13 VM (1 vCPU, 1–2 GB RAM)  
- **Steps:** install AdGuard → set upstreams/blocklists → UFW rules → router DNS→ AdGuard → validate with `dig`  
- **Validation:** see `./metrics/latency-YYYY-MM-DD.csv` and screenshots in `./evidence`

## 9) EVIDENCE
- `evidence/` — dashboard, DNS settings, DHCP page, terminal outputs  
- `metrics/` — latency CSV (10 samples), exports  
- `evidence/adguard_vm_check_*.txt` — captured VM details

## 10) FUTURE WORK
- Add **Unbound + DNSSEC** at `127.0.0.1#5335` and switch AdGuard upstream to it  
- TLS for admin (Caddy/Traefik) + restrict UI to admin IP only  
- Secondary DNS for HA + failover drill
