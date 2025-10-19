# <Project Title> — STAR Case Study

> **Resume one-liner (STAR)**  
> **S**: <problem/context>. **T**: <goal/criteria>. **A**: <what you built/did>. **R**: <measurable outcomes>.

## 0) Executive Summary
- **Role:** <your role>  
- **Environment:** <platforms/tools>  
- **Outcome:** <1–2 metrics>

## 1) SITUATION
- Context & constraints  
- Initial state/architecture  
- Why it matters for security (risks, blast radius)

## 2) TASK
- Success criteria (SLOs/KPIs)  
- Definition of done (what evidence proves it)

## 3) ACTION
- Key steps you performed (bullet list)  
- **Architecture (Mermaid):**
```mermaid
flowchart LR
  R[Router/Gateway] <--LAN--> P[Hypervisor/Host]
  P --> V[VM/Container: <OS>]
  V --> S[Service: <name>]
  S --> L[(Logs/Telemetry)]
  S --> U[(Upstreams/Deps)]
