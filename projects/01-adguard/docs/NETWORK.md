# NETWORK.md — AdGuard Home (DNS/DHCP) Network Reference

This document captures the **authoritative network view** for the AdGuard Home project: addressing, flows, ports, firewalls, dependencies, and the exact commands to verify the paths end-to-end.

> **Scope**
> - Single LAN (`192.168.1.0/24`) with a consumer router as WAN edge/gateway.
> - One AdGuard host providing **DNS (53/tcp+udp)** and **DHCP (67/68/udp)** to LAN clients.
> - Optional infra peers (NAS, Proxmox, reverse-proxy VM) and **Tailscale overlay** for future growth.
>
> **Source of truth diagrams**: see `projects/01-adguard/diagrams/` (SVG/PNG).

Set helper vars for all commands:

~~~bash
export LAN_CIDR=192.168.1.0/24
export ROUTER_IP=192.168.1.254
export ADGUARD_IP=192.168.1.10
export NAS_IP=192.168.1.20
export PROXMOX_IP=192.168.1.50
export VNGINX_IP=192.168.1.60
export MBP_IP=192.168.1.101
export IPHONE_IP=192.168.1.102
export DHCP_RANGE_START=192.168.1.100
export DHCP_RANGE_END=192.168.1.200
~~~

---

## 1) Topology at a glance

- **Internet ⟷ Router (NAT/WAN Edge)**  
  Router performs NAT for LAN → Internet and is the **default gateway** `($ROUTER_IP)`.
- **LAN `($LAN_CIDR)` segment**  
  - **AdGuard Home** `($ADGUARD_IP)` → DNS 53/tcp+udp, DHCP 67/68/udp, UI 80/tcp, SSH 22/tcp.  
  - **Clients** (MacBook `($MBP_IP)`, iPhone `($IPHONE_IP)`, etc.) query AdGuard for DNS and receive DHCP from it.  
  - **Infra** (NAS `($NAS_IP)`, Proxmox `($PROXMOX_IP)`, VM nginx `($VNGINX_IP)`).
- **Upstream DNS (encrypted)**  
  AdGuard → Quad9 DoH (`https://dns10.quad9.net/dns-query`).
- **Tailscale overlay** (optional)  
  Out-of-band access path; **does not** replace default gateway.

> Detailed lines/labels (DNS, DHCP, DoH, mgmt, SMB/NFS/HTTP[S]) are shown in the SVG/PNG diagram.

---

## 2) Addressing plan

| Role            | Hostname (suggested) | IP              | Notes                         |
|-----------------|----------------------|-----------------|-------------------------------|
| Gateway/Router  | `router.lan`         | `$ROUTER_IP`    | NAT to Internet; default GW   |
| AdGuard Home    | `adguard.lan`        | `$ADGUARD_IP`   | DNS/DHCP/UI/SSH               |
| NAS/File        | `nas.lan`            | `$NAS_IP`       | SMB 445/tcp, NFS 2049/tcp     |
| Proxmox Host    | `proxmox.lan`        | `$PROXMOX_IP`   | Web 8006/tcp, SSH 22/tcp      |
| VM nginx (RP)   | `v-nginx.lan`        | `$VNGINX_IP`    | HTTP 80/tcp, HTTPS 443/tcp    |
| MacBook         | `mac.lan`            | `$MBP_IP`       | Client                         |
| iPhone          | `iphone.lan`         | `$IPHONE_IP`    | Client                         |

**DHCP scope**: `$DHCP_RANGE_START` – `$DHCP_RANGE_END`  
**Reservations (recommended)**: AdGuard, NAS, Proxmox, VM nginx → **static**.

---

## 3) Port & flow matrix (authoritative)

| Source → Dest        | Protocol/Port     | Purpose                          | Allowed? |
|----------------------|-------------------|----------------------------------|---------:|
| Client → AdGuard     | UDP/TCP 53        | DNS recursion / sinkhole         | ✅ |
| Client ↔ AdGuard     | UDP 67/68         | DHCP (discover/offer/req/ack)    | ✅ |
| Admin → AdGuard      | TCP 80            | Local UI (LAN only)              | ✅ (LAN) |
| Admin → AdGuard      | TCP 22            | SSH mgmt (keys only; LAN)        | ✅ (LAN) |
| AdGuard → Quad9      | TCP 443           | DNS over HTTPS (upstream)        | ✅ (egress) |
| Client → VM nginx    | TCP 80/443        | App reverse proxy (optional)     | ✅ |
| Client ↔ NAS         | TCP 445 / 2049    | SMB/NFS                          | ✅ |
| LAN → Router         | any → NAT         | Internet access                   | ✅ |
| WAN → AdGuard        | *none*            | **No WAN exposure**               | ❌ |

---

## 4) DNS architecture

- **Clients point to AdGuard** (`$ADGUARD_IP`) for all DNS.
- **AdGuard upstream**: Quad9 DoH (primary). Optional plain DNS fallbacks are acceptable for break-glass only.
- **DNSSEC**: enable when upstream supports; be prepared to troubleshoot SERVFAIL on broken zones.
- **Policy**: Filtering lists block ad/tracker domains; custom allow/deny lists maintained in repo `docs/`.

Verification:

~~~bash
# Positive (A/AAAA expected)
dig @$ADGUARD_IP example.com +time=2 +tries=1 +short

# Negative (blocked)
dig @$ADGUARD_IP doubleclick.net +time=2 +tries=1 +short

# Upstream reachability (AdGuard host)
curl -I https://dns10.quad9.net/dns-query | head -n1
~~~

---

## 5) DHCP configuration

- **Authoritative** DHCP on AdGuard.  
- Scope: `$DHCP_RANGE_START`–`$DHCP_RANGE_END`, mask `/24`, **Router option** `$ROUTER_IP`, **DNS option** `$ADGUARD_IP`.  
- Fixed reservations for infra MACs (document in `docs/CHANGELOG.md` when added/changed).

Validation:

~~~bash
# On AdGuard host (leases snapshot)
sudo head -n 20 /opt/AdGuardHome/data/leases.json

# Sniff a lease exchange (short burst)
sudo tcpdump -ni any port 67 or port 68 -c 10
~~~

---

## 6) Routing & NAT

- **Default route** for all LAN nodes: `$ROUTER_IP`.
- Router performs NAT (LAN → Internet). No inbound port-forwards to `$ADGUARD_IP`.

Check:

~~~bash
ip route | egrep "default|$LAN_CIDR"
ping -c1 $ROUTER_IP
traceroute -m 3 1.1.1.1 || true
~~~

---

## 7) Firewall policy snapshot (UFW on AdGuard)

- **Inbound allowed**: 53/tcp+udp, 67/68/udp, 80/tcp, 22/tcp (LAN only).
- **Outbound**: allow 443/tcp (DoH), NTP 123/udp; optionally restrict further.

List/verify:

~~~bash
sudo ufw status numbered
ss -lntup | egrep '(:53|:67|:68|:80|:22)'
~~~

---

## 8) Operational checks (network layer)

Quick, repeatable probes:

~~~bash
# 1) AdGuard service listener health
for p in 53/tcp 53/udp 67/udp 68/udp 80/tcp 22/tcp; do echo "== $p =="; sudo ss -lunp | grep -E ":${p%/*}\b" || true; done

# 2) DNS latency sample (10x)
for i in {1..10}; do dig @$ADGUARD_IP cloudflare.com +stats | awk '/Query time:/{print $4 " ms"}'; done

# 3) UI reachable from a client (HTTP 80)
curl -sI http://$ADGUARD_IP/ | head -n1

# 4) DHCP discover visibility (run briefly)
sudo tcpdump -ni any port 67 or port 68 -c 5
~~~

Expected results:
- Listeners present on required ports only.
- Median DNS time consistent (tens of ms on LAN).
- UI returns `HTTP/1.1 200 OK` (or similar).
- DHCP traffic observed on correct ports when a client renews.

---

## 9) Dependency map (plain text)

- **Power/Link** → Router ↔ Internet (ISP)  
- **AdGuard** → Linux OS (systemd), local disk, **egress 443/tcp** to DoH  
- **Clients** → AdGuard (DNS/DHCP), Router (default GW)  
- **Optional Apps** → VM nginx ↔ NAS ↔ Proxmox storage  
- **Overlay** → Tailscale peers (mgmt only; no change to default GW)

---

## 10) Growth plan & capacity

- **More clients**: expand DHCP pool (`$DHCP_RANGE_END`), or segment guests/IoT into separate VLANs with ACLs so only 53/67/68 reach AdGuard.
- **High availability**: stage a warm-standby AdGuard (disabled DHCP, DNS only). Use router DHCP to fail over, or VRRP on advanced gear.
- **Performance**: consider `unbound` local caching upstream or AdGuard cache tuning if QPS grows.

---

## 11) Failure modes & quick triage

| Symptom                                | Likely cause                                   | First check / command                                  |
|----------------------------------------|-------------------------------------------------|--------------------------------------------------------|
| All DNS lookups fail                   | AdGuard down or listener blocked                | `systemctl status AdGuardHome`; `ss -lntup | :53`      |
| Only ad-domains fail (good)            | Filters working                                 | Query log shows `BLOCKED`; diagram policy arrows       |
| DHCP not handing leases                | Scope off / conflict with router DHCP           | Ensure router DHCP **disabled**; `tcpdump 67/68`       |
| Some sites SERVFAIL                    | DNSSEC/Upstream issue                           | Toggle DNSSEC; test `dig +cdflag`; check DoH egress    |
| UI unreachable                         | UFW/UI bind mismatch                            | `ufw status`; `grep bind_host AdGuardHome.yaml`        |

---

## 12) Naming & conventions

- Hostnames: `adguard.lan`, `router.lan`, `nas.lan`, `proxmox.lan`, `v-nginx.lan`.  
- Reserve `.10`, `.20`, `.50`, `.60` for infra; keep `.100–.200` for clients.  
- Update the **diagram** and `docs/CHANGELOG.md` for any addition/removal.

---

## 13) Verification after any network change (one-pass)

~~~bash
# Routes and default GW
ip r

# Firewalls & listeners
sudo ufw status numbered
ss -lntup | egrep '(:53|:67|:68|:80|:22)'

# DNS positive / negative
dig @$ADGUARD_IP example.com +time=2 +tries=1 +short
dig @$ADGUARD_IP doubleclick.net +time=2 +tries=1 +short

# Upstream DoH reachable
curl -sI https://dns10.quad9.net/dns-query | head -n1
~~~

---

## 14) Change log hook

Record **what/why/when/who** for any addressing, DHCP scope, firewall, or upstream resolver change in `docs/CHANGELOG.md` with a short rollback note.

---

**Owner:** @you @Saed Mohamud 
**Last validated:** 2025-10-28  
**Next review:** 2026-01-26 (+90 days)
