# <Project Title> — STAR Case Study

> **Resume one-liner (STAR)**  
> **S**: <problem/context>. **T**: <goal/criteria>. **A**: <what you built/did>. **R**: <measurable outcomes>.

## 0) Executive Summary
- **Role:** <your role>  
- **Environment:** <platforms/tools>  
- **Outcome:** <1–2 metrics>

---

## 1) SITUATION
- Context & constraints  
- Initial state/architecture  
- Why it matters for security (risks, blast radius)

## 2) TASK
- Success criteria (SLOs/KPIs)  
- Definition of done (what evidence proves it)

## 3) ACTION
- Key steps you performed (bullet list)

### Architecture (Mermaid)
~~~mermaid
flowchart LR
  R[Router/Gateway] <--LAN--> P[Hypervisor/Host]
  P --> V[VM/Container: <OS>]
  V --> S[Service: <name>]
  S --> L[(Logs/Telemetry)]
  S --> U[(Upstreams/Dependencies)]
~~~

### Configs (sanitized)
- Network
- Firewall
- App/service

### Automation/IaC
- Scripts
- Ansible/Terraform links

## 4) RESULT
**Metrics (before/after):**
| Metric | Before | After | How measured |
|---|---:|---:|---|
| <e.g., latency ms> |  |  |  |
| <e.g., block %> |  |  |  |

- Reliability & performance notes  
- What didn’t work and why (learning)

## 5) DETECTIONS & RUNBOOKS
- **Threat model:** what this reduces vs. does not  
- **Detection ideas:** queries/rules you wrote  
- **Runbook(s):** triage steps, rollback, comms  
- **(Optional) MITRE ATT&CK mapping:** IDs/techniques

## 6) SECURITY DECISIONS & TRADE-OFFS
- Logging vs privacy; performance vs depth; single vs HA  
- Hardening checklist (patching, auth, backups)

## 7) OPERATIONS
- Backups/restore steps  
- Health checks & monitoring  
- Rollback plan (tested? date, result)

## 8) REPRODUCE
- Prereqs (CPU/RAM/OS)  
- Commands or steps to deploy  
- Validation tests (commands/screenshots)

## 9) EVIDENCE
- Put screenshots/exports in `./evidence`  
- Diagram sources in `./diagrams`  
- Metrics CSVs in `./metrics`

## 10) FUTURE WORK
- Next improvements & rationale

---
**Repo hygiene:** keep a `CHANGELOG.md` in the project folder and tag a release when complete.
