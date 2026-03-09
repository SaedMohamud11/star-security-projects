# Phase 01 – Infrastructure Stabilization

## Objective

Establish a stable, production-style SOC lab foundation capable of:

- Hosting Elastic SIEM
- Ingesting endpoint logs
- Supporting AI orchestration layer
- Maintaining controlled network segmentation

This phase focuses strictly on infrastructure reliability before AI integration.

---

## Environment Overview

### Hypervisor
- Proxmox VE (bare metal)

### Virtual Machines

- **VM 200 – SOC-MGMT**
  - AI orchestration node
  - Documentation + automation control

- **VM 201 – Elastic Node**
  - Elasticsearch
  - Kibana
  - Fleet Server

- **VM 202 – Ubuntu Endpoint**
  - Primary log source
  - Elastic Agent installed

---

## Design Philosophy

Infrastructure must be:

- Isolated
- Reproducible
- Scalable
- Documented
- Evidence-driven

No AI logic is introduced until infrastructure is verified stable.

---
## Network Architecture (High-Level)

### Network Goals

- Keep Elastic components reachable from endpoints
- Keep management access restricted (admin-only)
- Avoid exposing services directly to the public internet
- Allow controlled remote access (VPN / Tailscale)

---

### Current Topology (Logical)

    LAN / Router
        |
    Proxmox Host
        |
    vmbr0 (bridge)
        |
    +----------------------------------+
    | VM 200 | VM 201  | VM 202        |
    | SOC    | Elastic | Ubuntu EP     |
    | MGMT   | Node    | Endpoint      |
    +----------------------------------+

---

### Access Model

- **Admin access:** SSH + Proxmox console (primary), VPN optional
- **Elastic access:** Kibana from trusted admin machine / trusted LAN path only
- **Endpoint egress:** Endpoint can reach Elastic ingestion services

> Principle: If something does not require inbound access, it should not have it.

---
## Definition of Done (Phase 01)

Phase 01 is complete only when the following are verified:

### Infrastructure Stability
- Proxmox host is stable and accessible
- All VMs boot without errors
- VM resource allocation is documented
- No unnecessary services exposed externally

### Elastic Stack Operational
- Elasticsearch service running
- Kibana accessible from trusted admin path
- Fleet Server operational
- No critical cluster health errors

### Endpoint Connectivity
- Ubuntu endpoint reachable
- Elastic Agent installed
- Agent successfully enrolled in Fleet
- Logs visible in Kibana

---

## Validation Commands

These commands were used to verify system health.

### On Elastic Node

    sudo systemctl status elasticsearch
    sudo systemctl status kibana
    sudo systemctl status elastic-agent

---

### Cluster Health Check

    curl -k -u elastic https://localhost:9200/_cluster/health?pretty

Expected result:
- Status should be `green` or `yellow`
- Status must NOT be `red`

---

### On Ubuntu Endpoint

    sudo systemctl status elastic-agent

Verification:
- Agent shows as **Healthy** inside Fleet
- Logs visible in Kibana → Discover

---

## Evidence Collection

Evidence for Phase 01 must include the following:

- Screenshot of Proxmox VM status (all VMs running)
- Screenshot of Kibana → Fleet showing agent health
- Screenshot of logs appearing in Discover
- Screenshot of cluster health response

All evidence files are stored in:

    projects/02-ai-assisted-soc-lab/evidence/

---

## Engineering Discipline Note

Phase 01 is not considered complete based on assumption.

It is complete only when:

- Services are running
- Logs are visible
- Health checks are validated
- Evidence is documented

Infrastructure must be proven stable before AI integration begins.

---
