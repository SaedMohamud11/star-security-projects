# INCIDENTS.md — AdGuard Home (DNS/DHCP) Incident Playbooks

> Purpose: fast, repeatable steps to **detect, triage, mitigate, and recover** from common DNS/DHCP issues in the homelab.  
> Stack: AdGuard Home on Linux (DNS sinkhole + optional DHCP) for LAN `192.168.1.0/24`, upstream DoH (e.g., Quad9).  
> Targets: **RTO** P0 ≤ 15 min, P1 ≤ 60 min, P2 ≤ 24 hr. **RPO**: query logs ≤ 24 hr.

Set helper vars used below:
~~~bash
export ADGUARD_IP=192.168.1.10      # <- adjust for your host
export ROUTER_IP=192.168.1.254      # <- adjust for your gateway
~~~

---

## 0) How to use this file

- Find the symptom below that best matches reality and jump to that playbook.  
- Always run **Universal First Steps** (≤ 90s) unless safety dictates otherwise.  
- **Mitigate first, then diagnose**. During P0/P1, favor temporary bypass/restoration.  
- Capture evidence as you go (logs/commands/screens) into `projects/01-adguard/evidence/runs/YYYY-MM-DD/`.

---

## 1) Severity levels (homelab)

- **P0 – Outage**: DNS lookups fail or DHCP unavailable for many clients.  
- **P1 – Major degradation**: high latency/timeout bursts; UI down but DNS OK; DHCP partial.  
- **P2 – Minor**: single site/app broken by filtering; intermittent slowness.  
- **P3 – Advisory/Maint**: planned changes, upgrades, tuning.

(If you’re solo: you’re both Incident Lead and Scribe. Otherwise: Lead executes; Scribe records timeline, commands, outcomes in `docs/incidents/notes-YYYYMMDD.md`.)

---

## 2) Universal First Steps (≤ 90s)

1. **Declare/timebox**: “Triage start $(date -Is) – Symptom: <one line>”
2. **Host reachability**
   ~~~bash
   ping -c2 $ADGUARD_IP || echo "Host unreachable"
   ~~~
3. **Quick dig from a client**
   ~~~bash
   dig @$ADGUARD_IP example.com +time=1 +tries=1 +short || echo "dig failed"
   dig @$ADGUARD_IP doubleclick.net +time=1 +tries=1 +short
   ~~~
4. **Service & ports**
   ~~~bash
   systemctl is-active AdGuardHome || true
   ss -lntup | egrep '(:53|:67|:68|:80|:443|:3000|:22)' || true
   ~~~
5. **Recent logs**
   ~~~bash
   journalctl -u AdGuardHome -n 100 --no-pager
   ~~~
6. Decide severity → jump to playbook.

---

## 3) Playbooks

### P0.A — Total DNS outage (timeouts / SERVFAIL / no answers)

**Signals**
- `dig @$ADGUARD_IP example.com` → `connection timed out` or `SERVFAIL`.
- Multiple users report “no internet” (name resolution fails).

**Mitigation (2–5 min)**
1. **Client-side emergency DNS** (keep working): set device DNS to `9.9.9.9` (or `1.1.1.1`) temporarily.
2. **Or LAN-wide bypass**: set router to forward DNS to public resolver until AdGuard is healthy.
3. **Restart & re-check**
   ~~~bash
   sudo systemctl restart AdGuardHome
   sleep 3; systemctl is-active AdGuardHome
   ss -lntup | egrep ':53|:80'
   ~~~
4. **Firewall sanity (UFW)**
   ~~~bash
   sudo ufw status numbered
   # Allow where appropriate: 53/udp,53/tcp,80/tcp,67/udp,68/udp,22/tcp
   ~~~
5. If still failing: go to **P1.C Upstream DoH/DNSSEC** and test fallbacks.

**Recovery**
- Remove the bypass (router/clients) and verify:
  ~~~bash
  dig @$ADGUARD_IP example.com +short
  ~~~
- Log what changed.

---

### P0.B — DHCP outage (clients fail to get IP/renew)

**Signals**
- Devices stuck on `169.254.x.x` (APIPA), or leases not renewing.

**Mitigation (3–10 min)**
1. **Static rescue IP** on your admin box (`192.168.1.200/24`, gw `$ROUTER_IP`) to keep access.
2. **Ensure DHCP enabled** in UI (*Settings → DHCP*); scope sane (`.100–.200`).
3. **Bounce service & inspect leases**
   ~~~bash
   sudo systemctl restart AdGuardHome
   sudo head -n 30 /opt/AdGuardHome/data/leases.json || true
   ~~~
4. **Emergency fallback**: temporarily enable router’s DHCP until AdGuard fixed.

**Diagnosis**
- **Port binding**
  ~~~bash
  ss -lunp | grep ':67 ' || echo 'nothing on 67/udp'
  ~~~
- **Interface mismatch**: LAN NIC in AdGuard DHCP config changed after an update?

**Recovery**
- Disable router fallback DHCP; confirm new leases issued by AdGuard; remove static rescue IP.

---

### P1.A — High latency / intermittent timeouts

**Signals**
- Avg processing time > 80–100 ms, sporadic SERVFAIL; users feel “slow.”

**Actions (10–20 min)**
1. **Measure**
   ~~~bash
   for i in {1..10}; do dig @$ADGUARD_IP cloudflare.com +stats | awk '/Query time/{print $4" ms"}'; done
   ~~~
2. **Compare upstreams**
   ~~~bash
   dig @9.9.9.9 cloudflare.com +stats
   dig @1.1.1.1 cloudflare.com +stats
   ~~~
3. **Resource pressure**
   ~~~bash
   vmstat 2 5
   free -h
   df -h /
   ~~~
4. **Link errors**
   ~~~bash
   ip -s link
   # ethtool counters (if supported):
   sudo ethtool -S <lan-nic> | egrep 'err|drop|fail' || true
   ~~~
5. **Mitigate**
   - Temporarily disable heavy filter lists or **DNSSEC**; add a second upstream; ensure LAN NIC is not power-saving.

**Post-fix**
- Record new latency baseline; consider adding a second AdGuard instance (HA).

---

### P1.B — UI unreachable, DNS still works

**Signals**
- `http://$ADGUARD_IP/` fails but clients resolve normally.

**Actions (5–10 min)**
1. **Is :80 bound?**
   ~~~bash
   ss -lntup | grep ':80 ' || echo 'no one listening on :80'
   ~~~
2. **Firewall**
   ~~~bash
   sudo ufw status numbered
   ~~~
3. **Logs**
   ~~~bash
   journalctl -u AdGuardHome -n 100 --no-pager
   ~~~
4. **Fix**
   - Allow `80/tcp` in UFW.
   - Stop any conflicting web server (Nginx/Apache) binding to `:80`.

---

### P1.C — Upstream DoH failure / DNSSEC validation issues

**Signals**
- Many domains return `SERVFAIL`; disabling DNSSEC “fixes” it; or DoH endpoint unreachable.

**Actions (5–10 min)**
1. **Temporary fallback to plain DNS (restore service)**
   - UI → *Settings → DNS settings*  
     Upstreams: `https://dns10.quad9.net/dns-query`  
     Fallbacks: `9.9.9.10`, `149.112.112.10`
2. **Optionally disable DNSSEC** briefly to confirm.
3. **Validate**
   ~~~bash
   dig @$ADGUARD_IP example.com +dnssec +cdflag +short
   ~~~
4. **If DoH cert/endpoint down**: keep plain fallbacks enabled until upstream recovers.

**Post-fix**
- Re-enable DNSSEC; keep at least two upstreams (DoH + plain).

---

### P2.A — False positive (site/app blocked)

**Signals**
- Site or app works when bypassing AdGuard; blocked via filter list.

**Actions (3–5 min)**
1. Reproduce and **inspect Query Log**; note exact domain(s)/CNAME chain.
2. **Allowlist** the minimum required domain(s).
3. **Verify**
   ~~~bash
   dig @$ADGUARD_IP <problem.domain> +short
   ~~~
4. Update `CHANGELOG.md` with allowlist reason.

---

### P1.D — Post-upgrade failure / won’t start

**Signals**
- Service crashes on start; YAML parse errors; ports not binding.

**Actions (5–15 min)**
1. **Logs**
   ~~~bash
   journalctl -u AdGuardHome -n 200 --no-pager
   ~~~
2. **Quick YAML check**
   ~~~bash
   python3 - <<'PY'
import yaml,sys
try:
  yaml.safe_load(open("/opt/AdGuardHome/AdGuardHome.yaml"))
  print("YAML OK")
except Exception as e:
  print("YAML ERROR:", e)
PY
   ~~~
3. **Rollback** (known-good backup)
   ~~~bash
   sudo systemctl stop AdGuardHome
   sudo tar -C / -xzf /opt/AdGuardHome-YYYY-MM-DD.tgz   # or restore yaml+data
   sudo systemctl start AdGuardHome
   ~~~
4. Document the regression and pin the known-good version.

---

### P1.E — Disk full / memory pressure

**Signals**
- “No space left on device” in logs; OOM kills.

**Actions (5–10 min)**
~~~bash
df -h
sudo journalctl --vacuum-time=7d
sudo du -h /opt/AdGuardHome | sort -h | tail
free -h
~~~
- Prune old query logs if enabled; grow disk/VM allocation as needed.

---

### P1.F — Tailscale / overlay DNS interference

**Signals**
- Only VPN-joined devices mis-resolve or skip AdGuard.

**Actions (5–10 min)**
- In Tailscale admin, ensure **MagicDNS** and **nameservers** do not override LAN clients unintentionally.  
- Configure **Split DNS** for homelab domains to point to `$ADGUARD_IP`.

---

### P0.C — Security event / suspected compromise

**Signals**
- Unexpected open ports, binary hash mismatch, spikes to malicious domains.

**Immediate (0–5 min)**
1. **Isolate** from WAN (keep LAN mgmt if safe) or power down.
2. **Volatile evidence** (only if safe):
   ~~~bash
   date -Is | tee /tmp/incident-start.ts
   ss -tupan        | tee /tmp/sockets.txt
   ps auxf          | tee /tmp/ps.txt
   sha256sum /opt/AdGuardHome/AdGuardHome | tee /tmp/bin.sha256
   ~~~
3. **Switch DNS** for clients to public resolvers (temporary).
4. **Rebuild from trusted media**, restore only known-good configs; rotate credentials/tokens.

---

## 4) Evidence capture (text bundle)

Save to a dated folder alongside screenshots used in `EVIDENCE.md`:

~~~bash
RUN="evidence/runs/$(date +%F)"; mkdir -p "$RUN"
{
  echo "=== TIMESTAMP ==="; date -Is
  echo "=== HOST ==="; hostnamectl
  echo "=== SERVICE ==="; systemctl status --no-pager AdGuardHome
  echo "=== PORTS ==="; ss -lntup | egrep '(:53|:67|:68|:80|:443|:3000|:22)'
  echo "=== UFW ==="; ufw status verbose || true
  echo "=== LOG last 200 ==="; journalctl -u AdGuardHome -n 200 --no-pager
  echo "=== DIG ok ==="; dig @$ADGUARD_IP example.com +time=1 +tries=1 +short
  echo "=== DIG ad ==="; dig @$ADGUARD_IP doubleclick.net +time=1 +tries=1 +short
} | tee "$RUN/incident.txt"
~~~

---

## 5) Communications

**Initial status**

    [INCIDENT] AdGuard DNS disruption – <P0|P1|P2>
    Start: 2025-10-28 14:07 local
    Symptom: <timeouts/SERVFAIL/no DHCP/etc>
    Impact: <# clients/segments>
    Mitigation: <bypass/rollback/restart> in progress
    Next update: +15 min

**Resolved**

    [RESOLVED] AdGuard DNS – <root symptom>
    Cause: <brief root cause or suspected>
    Fix: <actions taken / changes rolled back>
    Prevention: <1–2 bullets>
    Evidence: docs/evidence/runs/YYYY-MM-DD/*


---

## 6) Post-Incident Review (PIR)

Create `docs/incidents/PIR-YYYYMMDD.md` using:

    # PIR – AdGuard <short label> – YYYY-MM-DD
    Incident #: ADG-<seq>
    Severity: P0 | P1 | P2
    Start (detected): …
    End (resolved): …
    MTTR: …
    User impact: …
    What happened (timeline):
    - …
    Root cause (technical):
    - …
    What went well:
    - …
    What needs improvement:
    - …
    Actions (owner → due):
    1) Add second upstream (plain DNS) as fallback → Me → +3d
    2) Re-enable DNSSEC after 48h stability window → Me → +2d
    3) Add UFW rule test to pre-deploy checklist → Me → +1d
    Attachments: evidence/runs/YYYY-MM-DD/, logs, screenshots


---

## 7) Preventive controls checklist

- [ ] **Two upstreams** configured (DoH + plain DNS fallback).
- [ ] **DNSSEC** enabled (with safe fallback plan).
- [ ] **UFW** allows required ports; deny by default otherwise.
- [ ] **Backups**: nightly `AdGuardHome.yaml` + `data/` tarball.
- [ ] **Change control**: update `CHANGELOG.md` for every tweak.
- [ ] **Resource monitoring**: CPU/mem/disk checks monthly.
- [ ] **Second resolver** (optional) on separate host/VPS for resilience.


---

## 8) Handy commands appendix

**Positive/negative dig**

    dig @$ADGUARD_IP example.com +short
    dig @$ADGUARD_IP doubleclick.net +short

**Flush client DNS caches**

    # macOS
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

    # Windows (admin)
    ipconfig /flushdns

    # systemd-resolved (Linux)
    sudo resolvectl flush-caches   # or: systemd-resolve --flush-caches

**Service ops**

    sudo systemctl restart AdGuardHome
    sudo systemctl status --no-pager AdGuardHome
    journalctl -u AdGuardHome -n 100 --no-pager

**Typical file locations**

    /opt/AdGuardHome/AdGuardHome.yaml
    /opt/AdGuardHome/data/
    /opt/AdGuardHome/AdGuardHome          # binary

**Quick backup/restore**

    # Backup
    sudo tar -C /opt/AdGuardHome -czf "$HOME"/adguardhome-$(date +%F).tgz AdGuardHome.yaml data

    # Restore
    sudo systemctl stop AdGuardHome
    sudo tar -C /opt/AdGuardHome -xzf ~/adguardhome-YYYY-MM-DD.tgz
    sudo systemctl start AdGuardHome


---

**That’s it — use these templates to communicate clearly, close the loop with a PIR, harden with the checklist, and keep a small toolbox of commands handy for the next incident.**

