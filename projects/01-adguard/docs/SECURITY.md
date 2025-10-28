# SECURITY.md — AdGuard Home (DNS/DHCP) Security Guide

This document defines the **security baseline, threat model, hardening steps, and validation checks** for the AdGuard Home DNS sinkhole + DHCP server running on a Linux host in a home-lab network.

> **Scope**
> - Host: single Linux VM/box that runs AdGuard Home (systemd service or binary install).
> - Network: LAN `192.168.1.0/24` with router/gateway; no public exposure required.
> - Functions: DNS sinkhole (TCP/UDP 53), DHCP (UDP 67/68), local UI/API (HTTP 80 or 3000), optional SSH (22).

Set helper vars used in commands:

~~~bash
export ADGUARD_IP=192.168.1.10   # adjust for your host
export ROUTER_IP=192.168.1.254   # adjust for your gateway
~~~

---

## 1) Threat model (abridged)

### Assets
- Name resolution integrity/availability for LAN clients.
- DHCP availability and correctness (leases, reservations).
- AdGuard config (`AdGuardHome.yaml`) and query logs (may include sensitive domains).
- Host OS and credentials (SSH/admin).

### Entry points / risks
- Misconfigured firewall exposing UI or DNS to WAN.
- Weak admin password or SSH password auth.
- Rogue/compromised client abusing DNS/DHCP.
- Malicious lists / unsafe upstream resolvers.
- Supply-chain compromise (binaries/containers).
- Excessive logs → privacy leakage.

### Controls (high level)
- Least privilege (ports, users, egress).
- Strong authentication (SSH keys, long admin password).
- Segmentation and deny-by-default firewall.
- Reputable upstream (e.g., Quad9 DoH) + DNSSEC awareness.
- Regular patching & backups.
- Minimal, rotated, and anonymized logs.

---

## 2) Security baseline (checklist)

### A. Host hardening (Linux)
- ✅ System fully patched:
  ~~~bash
  sudo apt update && sudo apt -y upgrade
  sudo apt -y install unattended-upgrades fail2ban ufw
  sudo dpkg-reconfigure --priority=low unattended-upgrades
  ~~~
- ✅ SSH hardened (keys only, limited source):
  ~~~bash
  sudo sed -i -E 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl restart ssh
  ~~~
- ✅ Unique non-root admin with sudo; disable/lock unused accounts.
- ✅ Time sync (chrony or systemd-timesyncd) for log integrity.

### B. Network firewall (UFW)
> **Inbound to AdGuard**: 53/tcp+udp (DNS), 67/68/udp (DHCP), 80/tcp (UI), 22/tcp (SSH—restrict).  
> **Outbound**: permit 443/tcp for DoH & updates; optionally pin to resolver IPs.

~~~bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow proto tcp from 192.168.1.0/24 to $ADGUARD_IP port 80
sudo ufw allow proto tcp from 192.168.1.0/24 to $ADGUARD_IP port 53
sudo ufw allow proto udp from 192.168.1.0/24 to $ADGUARD_IP port 53
sudo ufw allow proto udp from 192.168.1.0/24 to any port 67
sudo ufw allow proto udp from any to 255.255.255.255 port 68
sudo ufw allow proto tcp from 192.168.1.0/24 to $ADGUARD_IP port 22

# Optional strict egress (uncomment & tailor)
# sudo ufw deny out to any
# sudo ufw allow out 443/tcp
# sudo ufw allow out 123/udp
# sudo ufw allow out to $ROUTER_IP

sudo ufw enable
sudo ufw status verbose
~~~

### C. AdGuard configuration hygiene
- ✅ Admin password **≥20 chars**; store in a password manager.
- ✅ UI binds to **LAN address** (`$ADGUARD_IP`) rather than `0.0.0.0` unless required.
- ✅ Upstream DNS: **encrypted** (DoH/DoT). Example DoH: `https://dns10.quad9.net/dns-query`.
- ✅ DNSSEC **aware**: enable when upstream supports and clients expect it (avoid false breaks).
- ✅ Use reputable lists; avoid unknown feeds.
- ✅ DHCP scope narrow and documented; reservations for infra (NAS/Proxmox, etc.).

### D. Logging, privacy & retention
- ✅ Query Log retention **≤ 7 days** (or disabled).
- ✅ Anonymize client IPs if logs needed.
- ✅ Rotate system logs.
- ✅ Never commit raw logs to public repos.

### E. Backup & recovery
- ✅ Take a backup **before** major changes:
  ~~~bash
  TS=$(date +%Y-%m-%d_%H%M)
  sudo systemctl stop AdGuardHome
  sudo tar -C /opt/AdGuardHome -czf "$HOME/adguardhome-$TS.tgz" AdGuardHome.yaml data
  sudo systemctl start AdGuardHome
  ~~~
- ✅ Test restore on a scratch VM periodically.

### F. Supply chain integrity
- ✅ Download from official releases; verify checksums/signatures.
- ✅ If containerized, **pin by digest**.
- ✅ Track dependencies/versions.

---

## 3) Secure-by-default reference rules

~~~bash
# Required inbound
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 67/udp
sudo ufw allow 68/udp
sudo ufw allow 80/tcp
sudo ufw allow from 192.168.1.0/24 to $ADGUARD_IP port 22 proto tcp

# If you proxy the UI on another host, close 80/tcp here and bind UI to loopback.
# sudo ufw delete allow 80/tcp
~~~

**If placing UI behind a reverse proxy**
- TLS (Let’s Encrypt), **HTTP auth** or SSO, IP allow-list.
- Bind AdGuard UI to `127.0.0.1:$port` or `$ADGUARD_IP:$port` reachable only by the proxy.

---

## 4) Operational security (OpSec)

- **Change control**: document every change in `CHANGELOG.md` with rollback notes.
- **Credentials**: no secrets in repo; use env vars or a vault.
- **Access**: SSH keys per admin; rotate monthly; remove unused keys.
- **Segmentation**: guests/IoT can use DNS but cannot reach UI/SSH (VLANs if possible).
- **Exposure audit**: quarterly confirm **no WAN port-forward** to `$ADGUARD_IP`.
- **List hygiene**: quarterly review enabled filters; remove abandoned lists.
- **PII minimization**: short retention & anonymization; prefer aggregates.

---

## 5) Patch & vulnerability management

- **Cadence**: monthly minimum; within 7 days for critical CVEs.
- **Process**:
  1) `sudo apt update && sudo apt -y upgrade`
  2) Review AdGuard release notes; stage in test VM if possible.
  3) Backup → upgrade → validate (see Verification).

- **Automation**: `unattended-upgrades` for OS; scripted AdGuard upgrades with version pin.

---

## 6) Verification (security assertions)

Run after initial setup and after significant changes.

~~~bash
# Service health
systemctl is-enabled AdGuardHome && echo enabled
systemctl is-active  AdGuardHome && echo active
systemctl status --no-pager AdGuardHome | sed -n '1,8p'

# Only expected ports
ss -lntup | egrep '(:53|:67|:68|:80|:22)' || true

# Firewall rules
sudo ufw status numbered

# DNS behavior
dig @$ADGUARD_IP example.com +time=2 +tries=1 +short
dig @$ADGUARD_IP doubleclick.net +time=2 +tries=1 +short

# DHCP leases (if using DHCP)
sudo head -n 20 /opt/AdGuardHome/data/leases.json 2>/dev/null || true

# UI bound host
sudo grep -n 'bind_host' /opt/AdGuardHome/AdGuardHome.yaml || true
~~~

Expected:
- Service **enabled/active**.
- Listeners limited to **53/tcp+udp, 67/68/udp, 80/tcp, 22/tcp**.
- UFW **active**, default-deny inbound; expected rules present.
- `dig` positive resolves; ad domains blocked.
- UI bind host is `$ADGUARD_IP` or `127.0.0.1` (if proxied).

---

## 7) Incident readiness

- Keep `docs/INCIDENTS.md` (P0/P1/P2 playbooks; first 90 seconds; rollback steps).
- Define **RTO** (e.g., P0 ≤ 15 min) and practice restore.
- Prepare **bypass**: temporarily point router/clients to a known good resolver if AdGuard is down.

---

## 8) Data classification & privacy

- **Query logs** = **Confidential**.
- **Retention**: ≤ 7 days; anonymize IPs; never publish raw logs.
- **Backups** containing logs/secrets should be encrypted at rest (LUKS/age/gpg).

---

## 9) Repo hygiene & redaction

- Do **not** commit admin passwords, tokens, **MAC addresses**, WAN IPs, or raw logs.
- Diagrams may show **RFC1918 IPs** and **open ports** only.
- Put secrets in a password manager or vault.

---

## 10) Known decisions & tradeoffs

- UI on HTTP (80) inside trusted LAN is acceptable if bound to `$ADGUARD_IP`.  
  For remote access, use **reverse proxy + TLS + auth**.
- DNSSEC can break some captive portals / bad zones; enable when upstream supports and you can troubleshoot failures.

---

## 11) Quick security self-audit (monthly)

- [ ] OS patched; unattended-upgrades enabled.  
- [ ] AdGuard updated; CHANGELOG updated.  
- [ ] UFW default deny; only required ports open; SSH from LAN only.  
- [ ] Query log retention ≤ 7 days; IP anonymization on (or logs off).  
- [ ] Backups verified (restore test in last 90 days).  
- [ ] No WAN port-forward to `$ADGUARD_IP`.  
- [ ] Filter lists reviewed; remove risky/abandoned feeds.  
- [ ] INCIDENTS.md updated after any outage.

---

## 12) Appendix — example secure reverse-proxy (optional)

If you front the UI with nginx on another host:

~~~nginx
server {
  listen 443 ssl http2;
  server_name adguard.lan;

  ssl_certificate     /etc/letsencrypt/live/adguard.lan/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/adguard.lan/privkey.pem;

  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htpasswd;

  location / {
    proxy_pass http://$ADGUARD_IP:80;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;
  }
}
~~~

Then **close 80/tcp** on the AdGuard host to LAN and bind the UI to `127.0.0.1` or a private interface reachable only by the proxy.

---

**Security owner:** @Saed Mohamud  
**Last reviewed:** 2025-10-28  
**Next review:** 2026-01-26 (+90 days)
