# REFERENCES.md — AdGuard Home (DNS/DHCP) Project

Curated sources used to design, deploy, secure, test, and operate this homelab AdGuard Home stack. Links are grouped by topic for quick lookup. (Verified as of 2025-10-28.)

---

## 1) Official product docs

- **AdGuard Home**
  - Overview & installation: https://github.com/AdguardTeam/AdGuardHome
  - User guide & settings: https://adguard-dns.io/kb/adguard-home/
  - DHCP server feature: https://adguard-dns.io/kb/adguard-home/advanced/dhcp-server/
  - Query log & statistics: https://adguard-dns.io/kb/adguard-home/overview/#query-log
  - Backups & export: https://adguard-dns.io/kb/adguard-home/overview/#backup

- **Quad9 (DoH / DoT)**
  - Resolver privacy policy: https://www.quad9.net/service/privacy/
  - **DoH endpoint:** `https://dns10.quad9.net/dns-query`  
    (Resolver list & anycast details: https://www.quad9.net/service/service-addresses-and-features/)
  - Threat-blocking & performance notes: https://www.quad9.net

---

## 2) Core standards (RFCs)

- DNS basics: RFC **1034**, RFC **1035**  
- DHCP for IPv4: RFC **2131**  
- DNS over HTTPS (DoH): RFC **8484**  
- DNS over TLS (DoT): RFC **7858**  
- DNSSEC intro/terminology: RFC **4033–4035**, RFC **8499**  
- EDNS Client Subnet (privacy considerations): RFC **7871**  
- IANA Service Name & Port registry (53/67/68/80/443/22): https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml

---

## 3) OS & networking commands (reference)

- **`dig` (BIND tools)**
  - Manpage: https://manpages.debian.org/bind9-dnsutils/dig.1.en.html
  - Homebrew (macOS) package: https://formulae.brew.sh/formula/bind

- **Name server discovery on clients**
  - macOS: `scutil --dns` — https://ss64.com/osx/scutil.html  
  - Linux (systemd-resolved): `resolvectl` — https://www.freedesktop.org/software/systemd/man/resolvectl.html  
  - Windows: `Get-DnsClientServerAddress`, `Resolve-DnsName` — https://learn.microsoft.com/powershell/module/dnsclient/

- **Flush client DNS cache**
  - macOS: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`  
  - Windows (Admin): `ipconfig /flushdns`  
  - Linux (systemd-resolved): `sudo resolvectl flush-caches`

- **Sockets / ports**
  - `ss(8)` (Linux): https://man7.org/linux/man-pages/man8/ss.8.html

- **Firewall & services (Ubuntu/Debian)**
  - UFW: https://help.ubuntu.com/community/UFW  
  - `systemd` services: https://www.freedesktop.org/software/systemd/man/systemctl.html  
  - `journalctl`: https://www.freedesktop.org/software/systemd/man/journalctl.html

---

## 4) Security & hardening

- **SSH hardening (OpenSSH):** https://www.ssh.com/academy/ssh/sshd_config  
- **CIS Benchmarks (Ubuntu/Debian)** — general guidance: https://www.cisecurity.org/cis-benchmarks  
- **AdGuard Home privacy & security notes:**  
  - DNSSEC in AdGuard: https://adguard-dns.io/kb/adguard-home/overview/#dns-settings  
  - Upstreams & bootstrap DNS: https://adguard-dns.io/kb/adguard-home/overview/#dns-upstreams  
- **Quad9 privacy and threat feed model:** https://www.quad9.net/service/privacy/

> Practical hardening reminders used in this repo:
> - Keep AdGuard UI **only** on LAN; no inbound WAN NAT.  
> - Prefer **DoH** upstreams (with plain-DNS fallbacks only if needed).  
> - Disable **EDNS Client Subnet** (ECS) for better privacy unless you explicitly need geo-targeted answers.

---

## 5) Troubleshooting & validation

- **DNS latency / correctness**
  - `dig @<server> example.com +stats` (baseline positive)  
  - `dig @<server> doubleclick.net +short` (ad domain → NXDOMAIN/sink IP)

- **AdGuard query log filtering:** https://adguard-dns.io/kb/adguard-home/overview/#query-log  
- **Leases location & format:** https://adguard-dns.io/kb/adguard-home/advanced/dhcp-server/#leases-file

---

## 6) Diagrams & documentation tooling

- **Mermaid (diagram syntax):** https://mermaid.js.org/intro/  
- **Mermaid flowcharts reference:** https://mermaid.js.org/syntax/flowchart.html  
- **Mermaid live editors:**  
  - Mermaid Live: https://mermaid.live  
  - MermaidChart: https://www.mermaidchart.com  
- **Draw.io / diagrams.net (manual diagramming):** https://app.diagrams.net  
- **SVG optimization (optional):** https://github.com/svg/svgo

> The `diagrams/` folder stores an **SVG** (lossless, editable) and a **PNG** (fast preview) export for each network diagram.

---

## 7) Useful AdGuard lists & community references

- **Filter list overview:** https://kb.adguard.com/en/general/adguard-ad-filters  
- **Host-style lists curation (StevenBlack):** https://github.com/StevenBlack/hosts  
- **Common allowlists for breakage:**  
  - YouTube/Google troubleshooting threads (varies)  
  - AdGuard community forum: https://forum.adguard.com/

> Always validate breakage via **Query Log** before adding allow rules; prefer **narrow** allowlists (domain/path/regex) over global disables.

---

## 8) Example commands (quick copy)

```bash
# Positive resolution (baseline)
dig @$ADGUARD_IP example.com +time=2 +tries=1 +short

# Negative (ad) domain should be NXDOMAIN / sinked
dig @$ADGUARD_IP doubleclick.net +time=2 +tries=1 +short

# Check DoH upstream is reachable (Quad9)
curl -sI https://dns10.quad9.net/dns-query | head -n1

# Show listening ports on AdGuard host
ss -lntup | egrep '(:53|:67|:68|:80|:443|:22)'

# Service & firewall
systemctl status --no-pager AdGuardHome
sudo ufw status numbered
```

---

## 9) Change management & ops

- **Keep evidence:** screenshots and command outputs under `projects/01-adguard/evidence/runs/<YYYY-MM-DD>/`  
- **Document changes:** `projects/01-adguard/docs/CHANGELOG.md`  
- **Runbooks & incidents:** `projects/01-adguard/docs/RUNBOOK.md`, `INCIDENTS.md`

---

### Attribution

All trademarks and product names (AdGuard, Quad9, etc.) belong to their respective owners. Links provided for educational and operational reference within a personal homelab context.
