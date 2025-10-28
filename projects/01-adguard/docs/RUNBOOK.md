# RUNBOOK — AdGuard Home (DNS + DHCP)

**Service:** AdGuard Home  
**Host:** `192.168.1.10` (adjust if different)  
**Scope:** DNS sinkhole (port 53 TCP/UDP), DHCPv4 (ports 67/68 UDP), Web UI (80/TCP), SSH (22/TCP)

> Tip: set a helper var when running commands:
> ```bash
> export ADGUARD_IP=192.168.1.10
> ```

---

## 1) Quick Links

- Web UI: `http://$ADGUARD_IP/`
- Evidence & reproducible checks: `../evidence/EVIDENCE.md`
- Deployment steps: `../docs/DEPLOYMENT.md`
- Network/ports summary: `../docs/NETWORK.md`
- Security & hardening notes: `../docs/SECURITY.md`

---

## 2) SLO / SLI

| Objective | SLI | Target |
|---|---|---|
| Availability | DNS port 53 reachable from LAN | ≥ 99.9% monthly |
| Correctness | Successful answers for benign domains | ≥ 99.95% |
| Performance | Median DNS query time (LAN client → AdGuard → upstream) | ≤ 50 ms median, ≤ 150 ms p95 |
| DHCP continuity | New/renewing clients get leases | 100% during business hours |

**Alerting heuristics (manual for now):**
- Two or more clients report DNS resolution failures.
- `dig` to benign domains fails or latency drifts > 2× baseline for 10 consecutive probes.
- No new DHCP leases in the last 8 hours while devices are joining the network.

---

## 3) Daily & Weekly Checks

> Helper var used below (run once per shell):
>
> ```bash
> export ADGUARD_IP=192.168.1.10
> ```

### Daily (30–60s)

1. **Dashboard glance (UI)**
   - Visit `http://$ADGUARD_IP/` → **Dashboard**.
   - Check there are **no error banners**.
   - **Average processing time** ≲ _your baseline_ (e.g., ≤ 50 ms on LAN).
   - **% Blocked** looks normal for your household; unexpected spikes/drops may mean a filter or upstream issue.

2. **Positive lookup from a client**
   ```bash
   dig @$ADGUARD_IP example.com +time=2 +tries=1 +short
   ```
   _Expect:_ an A/AAAA address; **not** `SERVFAIL`/`REFUSED`.

3. **Negative (ad) lookup from a client**
   ```bash
   dig @$ADGUARD_IP doubleclick.net +time=2 +tries=1
   ```
   _Expect:_ `status: NXDOMAIN` **or** sink address (e.g., `0.0.0.0`/`::`) depending on your filter mode.

4. **Client really uses AdGuard**
   - **macOS:** `scutil --dns | awk '/nameserver\[[0-9]+\]/{print $3}' | head -1`
   - **Linux:** `grep -E '^nameserver ' /etc/resolv.conf`  (or `nmcli dev show | grep -i dns`)
   - **Windows (PowerShell):** `Get-DnsClientServerAddress | ? {$_.ServerAddresses} | ft InterfaceAlias,ServerAddresses -Auto`
   _Expect:_ first resolver = `$ADGUARD_IP`.

---

### Weekly (3–5 min)

1. **Latency sanity (10 samples)**
   ```bash
   for i in {1..10}; do
     dig @$ADGUARD_IP cloudflare.com +stats | awk '/Query time/{print $4 " ms"}'
   done
   ```
   - Record median; alert yourself if it drifts >2× your baseline.

2. **Blocklist spot-audit**
   - UI → **Query Log**: filter by `blocked` and scan the top 10 blocked domains.
   - Confirm there are **no false positives** (e.g., CDN for apps you use). If you find any, add an allowlist rule with justification.

3. **Filters & upstreams health**
   - UI → **Filters**: ensure lists updated recently; no download failures.
   - UI → **Settings → DNS**: verify upstream DoH endpoint is reachable (use **Test upstreams**).

4. **DHCP lease health (if AdGuard runs DHCP)**
   - UI → **Settings → DHCP**: confirm address pool utilization (<70% is healthy).
   - Spot duplicate hostnames/MACs or abnormal churn.

5. **Host quick checks**
   ```bash
   ss -lntup | egrep '(:53|:67|:68|:80|:443|:22)'
   sudo ufw status | sed -n '1,50p'
   systemctl is-active --quiet AdGuardHome && echo ACTIVE || echo INACTIVE
   ```
   - Ports present as expected; UFW **active** and rules unchanged; service **ACTIVE**.

6. **Lightweight config backup**
   ```bash
   sudo tar -C /opt/AdGuardHome -czf "$HOME/adguardhome-weekly-$(date +%F).tgz" AdGuardHome.yaml data
   ```

---

## 4) Monthly Maintenance (10–20 min)

1. **Full backup (config + data)**
   ```bash
   sudo systemctl stop AdGuardHome
   sudo tar -C /opt/AdGuardHome -czf "$HOME/adguardhome-full-$(date +%F).tgz" .
   sudo systemctl start AdGuardHome
   ```

2. **Binary & OS security updates (non-prod window)**
   - Check AdGuard Home release notes; update if security/bug fixes apply.
   - Apply OS updates; reboot if kernel/openssl/glibc updated.
   - Post-update smoke test: steps from **Daily**.

3. **Validate filter set**
   - Remove obviously redundant lists (keep quality over quantity).
   - Run canary tests on a few sites/apps you use (streaming, banking, work SSO).

4. **Review DHCP scope & reservations**
   - Ensure static reservations (router, NAS, Proxmox, AdGuard) remain outside the dynamic pool.
   - Adjust pool size if utilization consistently >75%.

5. **Snapshot (VM/host)**
   - If AdGuard runs as a VM/container, create a snapshot/checkpoint after updates & tests.

6. **Security posture**
   ```bash
   sudo grep -En 'protection_enabled|^dhcp:|^[[:space:]]*v4' /opt/AdGuardHome/AdGuardHome.yaml
   ss -lntup | grep -vE '127\.0\.0\.1|::1'   # look for unexpected listeners
   sudo grep -i "error\|panic" /var/log/syslog | tail -n 50
   ```

---

## 5) Troubleshooting

> Use this flow to narrow cause → fix → verify.

### A) All clients cannot resolve anything
1. **Service & port checks**
   ```bash
   systemctl status --no-pager AdGuardHome
   ss -lntup | egrep '(:53|:80)'
   ```
   - If service is down, restart: `sudo systemctl restart AdGuardHome`.

2. **Upstream failure**
   - UI → **Settings → DNS → Test upstreams** (e.g., `https://dns10.quad9.net/dns-query`).
   - Temporarily add plain DNS fallbacks (remove later):
     ```
     9.9.9.10
     149.112.112.10
     ```
   - If this restores resolution, the DoH endpoint or outbound egress is blocked.

3. **Firewall**
   ```bash
   sudo ufw status numbered
   ```
   - Ensure LAN is allowed to `53/udp,tcp` and UI `80/tcp` (if needed).

4. **Rule corruption / quick reset**
   ```bash
   sudo systemctl restart AdGuardHome
   ```
   - Re-test **Daily** steps.

### B) Some clients work; others don’t
1. **Client resolver points elsewhere**
   - Check the client’s DNS server (see **Daily → step 4**).
   - If using DHCP, verify the handed-out DNS = `$ADGUARD_IP`.

2. **Lease conflicts**
   - UI → **Settings → DHCP**: duplicate IP/MAC? Reclaim & reassign.

3. **Local firewall on the client**
   - Ensure client isn’t blocking outbound `53/udp`.

### C) Slow lookups / high latency
1. **Measure on the wire**
   ```bash
   for i in {1..10}; do dig @$ADGUARD_IP google.com +stats | awk '/Query time/{print $4 " ms"}'; done
   ```
2. **Upstream or list bloat**
   - Temporarily switch to a different upstream (e.g., alternate Quad9/Cloudflare).
   - Disable large/duplicate lists and re-test.

3. **Host pressure**
   ```bash
   top -b -n1 | head -n5
   free -h
   iostat -xz 1 3
   ```
   - CPU/IO pressure can increase response time.

### D) UI reachable but blocking doesn’t happen
1. **Protection toggle off?** Dashboard: ensure **ON**.
2. **Filters disabled/failed to update?** **Filters** page → re-enable/re-fetch.
3. **Upstream bypass on client?** Client might be using hard-coded DNS (e.g., app/OS profile). Force via router ACL if needed.

### E) DHCP not issuing leases (if enabled)
1. **AdGuard DHCP active on correct interface** (UI → **DHCP**).
2. **Scope not exhausted**; raise pool or shorten lease.
3. **Another DHCP on LAN** (router/AP) – disable it or move AdGuard to different subnet/VLAN.

---

## 6) Health Metrics to Track

Create a simple log (CSV/MD) and update weekly:

| Metric                         | Target / Baseline | Alert Threshold                     | Notes                                  |
|-------------------------------|-------------------|-------------------------------------|----------------------------------------|
| Avg query time (ms)           | ≤ 50              | ≥ 2× baseline for 2+ days           | From Dashboard or `dig` loop           |
| % blocked                     | Household-normal  | ±10 pp swing vs 4-week average      | Large drift → filter/upstream issue    |
| Queries / day                 | Household-normal  | ≥ 50% change sustained              | Sudden drop → clients not using AGH    |
| Upstream success rate         | ~100%             | Failures / timeouts seen in logs    | UI “Test upstreams” + logs             |
| DHCP pool utilization         | < 70%             | > 85%                               | Expand pool / trim leases              |
| Host CPU / RAM                | Low/moderate      | Sustained > 80%                     | Check lists, upstream, host pressure   |

---

## 7) Change Log Template (for `docs/CHANGELOG.md`)

```md
# Changelog — AdGuard Home

## [YYYY-MM-DD] — <short title>
### Added
- …

### Changed
- …

### Fixed
- …

### Security
- …

### Rollback
- To revert this change:
  1) …
  2) …
```

---

## 8) Appendix — Handy Commands

### Positive/negative dig
```bash
dig @$ADGUARD_IP example.com +short
dig @$ADGUARD_IP doubleclick.net
```

### Flush client DNS caches
- **macOS:** `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
- **Windows (Admin):** `ipconfig /flushdns`
- **systemd-resolved:** `sudo resolvectl flush-caches` (or `systemd-resolve --flush-caches`)

### Safe service ops
```bash
sudo systemctl restart AdGuardHome
sudo systemctl status --no-pager AdGuardHome
journalctl -u AdGuardHome -n 100 --no-pager
```

### File locations (typical)
```
/opt/AdGuardHome/AdGuardHome.yaml
/opt/AdGuardHome/data/
/opt/AdGuardHome/AdGuardHome    # binary
```

### Quick backup/restore
```bash
# Backup (hot, quick)
tar -C /opt/AdGuardHome -czf "$HOME/adguardhome-$(date +%F).tgz" AdGuardHome.yaml data

# Restore (example)
sudo systemctl stop AdGuardHome
sudo tar -C /opt/AdGuardHome -xzf ~/adguardhome-YYYY-MM-DD.tgz
sudo systemctl start AdGuardHome
```

---

> **Note:** Run the Daily/Weekly checks, perform Monthly maintenance, and update the changelog with each change so you can roll back confidently.
