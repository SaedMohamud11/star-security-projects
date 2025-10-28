# Deployment Guide

> Target host: **Ubuntu Server** on `192.168.1.10` (adjust if different).

This guide installs AdGuard Home as a systemd service, configures DoH upstreams and DHCP, applies host-firewall rules, and shows how to verify and back up the setup.

---

## 0) Prerequisites

- Static IP on the AdGuard host (example):  
  - IP: `192.168.1.10/24`  
  - Gateway: `192.168.1.254`
- Router is set to **not** run DHCP (AdGuard will be the DHCP server).
- You can SSH into the host with an admin user (`sudo`).

---

## 1) Install AdGuard Home (systemd)

Option A — **Official installer**:

~~~bash
cd /opt
curl -fsSL https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh
# The first-run wizard appears on http://<host>:3000
# After finishing, the service binds to :80 (UI) and :53/:67/:68 (DNS/DHCP)
~~~

Option B — **Manual extract** (also systemd):

~~~bash
# Download the latest linux_amd64 tarball from AdGuard Home releases
tar xzf AdGuardHome_*_linux_amd64.tar.gz
sudo mv AdGuardHome /opt/AdGuardHome
sudo /opt/AdGuardHome/AdGuardHome -s install
sudo systemctl enable --now AdGuardHome
~~~

Check status:

~~~bash
systemctl status AdGuardHome --no-pager
~~~

---

## 2) Minimal UI configuration

1. Open **http://192.168.1.10** (after first-run; use your IP).
2. **Upstream DNS** → add a DoH resolver (Quad9 in this project): https://dns10.quad9.net/dns-query

Optional fallbacks (plain DNS):
- 9.9.9.10
- 149.112.112.10

- Leave **EDNS Client Subnet** **disabled** for privacy (enable only if you want geo-targeted answers).
- DNSSEC can be enabled if desired; document the choice in `SECURITY.md`.

3. **DHCP (IPv4)**:
- **Gateway**: `192.168.1.254`
- **Range**: `192.168.1.100 – 192.168.1.200`
- **Lease time**: `86400` seconds
- Click **Save** and ensure **DHCP server is enabled**.

4. **Filters**:
- Enable the default filter lists. Add others later if needed.

---

## 3) Host firewall (UFW)

Allow only what AdGuard needs **from the LAN**:

~~~bash
# Default deny inbound; allow essential services from LAN only
sudo ufw default deny incoming

sudo ufw allow from 192.168.1.0/24 to any port 53 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 53 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 67 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 68 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp

sudo ufw enable
sudo ufw status verbose
~~~

> If your LAN is not `192.168.1.0/24`, adjust the CIDR accordingly.

---

## 4) Router & clients

- **Disable** the router’s built-in DHCP so AdGuard is the **only** DHCP server.
- Reconnect clients or refresh leases:
- Windows: `ipconfig /renew`
- macOS/iOS: toggle Wi-Fi off/on

---

## 5) Verification (CLI)

Latency sanity (10 samples):

~~~bash
for i in {1..10}; do
dig @192.168.1.10 cloudflare.com +stats | awk '/Query time/{print $4 " ms"}'
done
~~~

Positive/negative tests:

~~~bash
dig @192.168.1.10 example.com +short
dig @192.168.1.10 doubleclick.net +short   # should be blocked / NXDOMAIN
~~~

Service & sockets:

~~~bash
systemctl is-active --quiet AdGuardHome && echo "AdGuard: ACTIVE" || echo "AdGuard: INACTIVE"
ss -lntup | egrep ':(53|67|68|80|22)\b'
~~~

DHCP check (UI and file):

- UI → **Settings → DHCP settings** (leases should appear)
- File head:
~~~bash
sudo head -n 20 /opt/AdGuardHome/data/leases.json
~~~

For full reproducible screenshots/commands, see:  
`../evidence/EVIDENCE.md`

---

## 6) Backups (config + data)

Create an archive of YAML + data directory:

~~~bash
sudo tar -C /opt -czf /root/adguardhome-backup-$(date +%F).tgz \
AdGuardHome/AdGuardHome.yaml AdGuardHome/data
echo "Backup at /root/adguardhome-backup-$(date +%F).tgz"
~~~

(Optional) Weekly cron:

~~~bash
sudo bash -lc 'cat >/etc/cron.weekly/adguardhome-backup <<EOF
#!/usr/bin/env bash
tar -C /opt -czf /root/adguardhome-backup-\$(date +%F).tgz AdGuardHome/AdGuardHome.yaml AdGuardHome/data
EOF
chmod +x /etc/cron.weekly/adguardhome-backup'
~~~

---

## 7) What’s next

- Operate the service using the **RUNBOOK** (`../docs/RUNBOOK.md`).
- Review **SECURITY** (`../docs/SECURITY.md`) to decide on DNSSEC, admin exposure, and backups.
- Network details and ports: `../docs/NETWORK.md`
- Diagrams: `../diagrams/` (SVG/PNG)

> If you ever re-deploy on a new IP/subnet, update the UFW rules and DHCP scope to match.
