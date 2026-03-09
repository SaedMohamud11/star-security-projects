# Phase 01 – Infrastructure

## 1. Phase Objective

Establish the base lab environment required for the rest of the project by bringing the core SOC components online, enrolling the primary Linux endpoint into Elastic, and validating that security-relevant telemetry is visible in Kibana.

This phase was focused on infrastructure readiness, not AI behavior. The objective was to prove that the lab could reliably support endpoint visibility, centralized logging, and future detection engineering work before any higher-layer automation was introduced.

---

## 2. Environment Overview at the Time of the Phase

At the time of this phase, the lab consisted of three primary virtual machines running on Proxmox:

- **VM 200 – soc-mgmt**  
  Management node used for administration, project documentation, and later Python-based SOC automation

- **VM 201 – elastic-node**  
  Elastic stack node responsible for log ingestion, search, Fleet management, and analyst visibility through Kibana

- **VM 202 – ubuntu-endpoint-1**  
  Primary monitored endpoint used to generate Linux system and authentication telemetry

### Core infrastructure components

- **Proxmox VE** as the virtualization platform
- **Elastic Stack** for ingestion, visibility, and later alerting
- **Elastic Agent / Fleet** for endpoint enrollment and telemetry collection
- **Ubuntu endpoint telemetry**, especially `system.auth`, as the initial security-relevant data source

This phase established the minimum viable operating baseline for the rest of the project: the infrastructure had to be running, the endpoint had to be enrolled, and the logs had to be visible in a usable analyst workflow.

---

## 3. Design Philosophy

This phase followed a simple principle: **visibility before detections, and detections before automation**.

The design decisions in this phase were intentionally conservative:

- infrastructure had to be stable before adding more moving parts
- the endpoint had to be visible in Fleet before detection logic was created
- authentication logs had to be confirmed in Discover before any security engineering claims were made
- each milestone needed evidence, not assumption

The project was also kept intentionally narrow at this stage. Rather than onboarding many endpoints at once, I used a single Ubuntu endpoint as the first controlled telemetry source so that validation could remain clean and traceable.

---

## 4. Definition of What Makes the Phase Done

Phase 01 is considered complete only when all of the following conditions are true:

- the required project VMs are online in Proxmox
- the Ubuntu endpoint is enrolled into Fleet successfully
- Elastic Agent reports as healthy
- logs from the Ubuntu endpoint are visible in Kibana Discover
- security-relevant authentication telemetry is visible through the `system.auth` dataset
- the environment is stable enough to proceed into detection engineering

This definition matters because the later phases depend entirely on this one. If the infrastructure is not healthy, then any detection or automation work built on top of it is untrustworthy.

---

## 5. Validation Commands or Tests

The following validation activities were used to confirm the phase was complete.

### Test 1 — Confirm core virtual machines are running

Reviewed the Proxmox VM inventory to verify that the management node, Elastic node, and Ubuntu endpoint were powered on and available.

This validated that the base environment required for the project was online.

### Test 2 — Confirm endpoint enrollment and agent health

Verified in Fleet that `ubuntu-endpoint-1` was enrolled and reporting a healthy status.

This validated:

- agent enrollment success
- policy application
- active communication between endpoint and Elastic
- availability of logs and metrics collection

### Test 3 — Confirm general log visibility in Discover

Queried Discover with the `logs-*` data view and filtered on:

    host.name : "ubuntu-endpoint-1"

This validated that the endpoint was sending logs into Elastic and that the analyst workflow for reviewing endpoint telemetry was functioning.

### Test 4 — Confirm security-relevant authentication telemetry

Queried Discover for the `system.auth` dataset using:

    host.name : "ubuntu-endpoint-1" AND event.dataset : "system.auth"

This validated that security-relevant Linux authentication activity was being collected successfully and would be available for later detection engineering work.

---

## 6. Evidence Collection / Screenshots

### 6.1 Proxmox VM status

![Proxmox VM Status](../evidence/phase-01-infrastructure/proxmox-vm-status.png)

**What this proves**
- the core project VMs existed and were powered on
- the environment was active at the virtualization layer
- the required management, Elastic, and endpoint systems were available for the lab

### 6.2 Fleet agent healthy

![Fleet Agent Healthy](../evidence/phase-01-infrastructure/fleet-agent-healthy.png)

**What this proves**
- `ubuntu-endpoint-1` was successfully enrolled into Fleet
- Elastic Agent was healthy and actively checking in
- the endpoint was ready to provide telemetry for security operations work

### 6.3 General logs visible in Discover

![Logs Visible in Discover](../evidence/phase-01-infrastructure/logs-visible-discover.png)

**What this proves**
- logs from the Ubuntu endpoint were successfully indexed
- the analyst could search and filter endpoint data in Kibana
- the `logs-*` data view was operational for day-to-day review

### 6.4 Authentication logs visible in Discover

![Security Auth Logs in Discover](../evidence/phase-01-infrastructure/security-auth-logs-discover.png)

**What this proves**
- the `system.auth` dataset was being ingested successfully
- security-relevant authentication events were visible
- the lab had the specific telemetry needed for the Linux detection work in the next phase

---

## 7. Engineering Discipline Note

This phase was intentionally treated as a gate, not a formality.

It would have been easy to rush ahead into detection logic or AI features, but that would have created a weak foundation. Instead, I required visible proof that the infrastructure was operating correctly before moving forward.

That discipline matters for two reasons:

- later detections are only credible if the source telemetry is confirmed first
- later automation is only useful if it is built on top of a stable and observable environment

Phase 01 therefore served as the technical baseline for the rest of the project: infrastructure online, endpoint enrolled, logs visible, and security telemetry confirmed.

