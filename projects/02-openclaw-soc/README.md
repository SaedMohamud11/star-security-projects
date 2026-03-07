# AI-Assisted SOC Lab

A home SOC environment built on **Elastic SIEM** with a **custom AI triage and reporting layer** powered by **OpenAI**, supporting alert triage, investigation assistance, and executive-style reporting through WhatsApp.

---
## 1️⃣ Situation

Traditional Security Operations Centers (SOCs) rely heavily on manual triage, repetitive alert review, and slow operator workflows.

I built this lab to simulate a modern AI-assisted SOC environment capable of structured detection, triage support, investigation assistance, and executive reporting.

This environment runs inside my self-hosted Proxmox home lab.

### Infrastructure

- **Proxmox VE Host**
- **VM 200** – SOC Management Node (Python automation + AI triage + reporting)
- **VM 201** – Elastic SIEM Node
- **VM 202** – Ubuntu Endpoint (primary log source)
- **Elastic Stack (Fleet + Kibana)**
- **Custom AI Triage & Reporting Layer**
- **Twilio WhatsApp Integration**
- **ngrok HTTPS Tunnel for webhook testing**

---
## 2️⃣ Task

Design and implement a structured, AI-assisted SOC workflow that includes:

- Centralized log ingestion from endpoint to Elastic
- Detection engineering for security-relevant endpoint activity
- AI-assisted alert triage and readable investigation output
- Executive-style SOC summaries delivered through WhatsApp
- Portfolio-ready documentation and evidence tracking

The objective is not just detection, but operational workflow improvement through controlled AI assistance.

---
## 3️⃣ Architecture Overview

### Log and Response Flow

    Endpoint activity
        ↓
    Elastic Agent
        ↓
    Elasticsearch logs
        ↓
    Detection rules trigger alerts
        ↓
    elastic_poller.py queries alerts
        ↓
    Alert checked against SQLite memory
        ↓
    If new → send to AI analysis
        ↓
    AI generates SOC explanation
        ↓
    Flask API formats response
        ↓
    Twilio sends WhatsApp message
        ↓
    User receives SOC alert

This architecture separates responsibilities clearly:

- **Detection** → Elastic SIEM
- **Triage Assistance** → `elastic_poller.py` + OpenAI API
- **State Tracking** → SQLite alert memory
- **Operator Interaction** → Flask webhook + Twilio WhatsApp
- **Executive Reporting** → AI-generated SOC summary workflow

---
## 4️⃣ Implemented AI Workflow

### 🔹 AI Triage Layer

Responsibilities:

- Query open and recent alerts from Elastic
- Retrieve recent endpoint event context from `logs-*`
- Generate readable explanations for alerts using `gpt-4o-mini`
- Produce short investigation notes for analyst review
- Prevent duplicate alert reporting through SQLite tracking

Restrictions:

- Does not close cases
- Does not change alert severity
- Does not override Elastic as the source of truth
- Produces recommendations only

---

### 🔹 Executive Reporting Layer

Responsibilities:

- Receive inbound WhatsApp commands through Twilio
- Route commands through Flask webhook logic
- Return:
  - `check alerts`
  - `soc summary`
  - `last alert`
  - `investigate`
- Deliver concise security summaries in mobile-friendly format
- Split long responses safely for readability

Restrictions:

- Does not make final analyst decisions
- Does not replace case management
- Acts as a reporting and interaction layer only

> Human analyst remains the final decision authority.

---
## 5️⃣ Current Phase Progress

- **Phase 1:** Infrastructure stabilization (Proxmox + VM setup)
- **Phase 2:** Elastic integration and detection engineering
- **Phase 3:** AI triage layer integration
- **Phase 4:** Executive reporting automation

This project is being built in phases to reflect realistic SOC maturity: first visibility, then detections, then triage support, then operator-facing reporting.

---

## 6️⃣ Skills Demonstrated

- SIEM deployment and configuration (Elastic Stack)
- Endpoint log ingestion and telemetry flow design
- Detection engineering for Linux security events
- Virtualization and lab architecture (Proxmox)
- Python automation for SOC workflows
- OpenAI API integration for security triage support
- SQLite-based state tracking for duplicate suppression
- Flask webhook development
- Twilio WhatsApp workflow integration
- Executive-style reporting and documentation discipline

---

## 7️⃣ Long-Term Vision

- Expand from command-based triage to broader analyst workflow automation
- Add structured case management integration
- Add deeper multi-step investigation support
- Build human-reviewed closure workflow
- Produce recurring executive security posture reports automatically

This lab is designed not just as a learning project, but as a professional SOC architecture showcase grounded in real implementation.

---

## 🧾 Evidence — SOC Pipeline Validation

### 1️⃣ Infrastructure Running (Proxmox)

![Proxmox VM Status](./evidence/proxmox-vm-status.png)

**Proves:**
- SOC-MGMT (VM 200) running
- Elastic Node (VM 201) running
- Ubuntu Endpoint (VM 202) running

---

### 2️⃣ Elastic Agent Healthy (Fleet)

![Fleet Agent Healthy](./evidence/fleet-agent-healthy.png)

**Proves:**
- Ubuntu endpoint successfully enrolled
- Agent policy applied
- Agent communicating with Elastic
- Logs & metrics enabled

---

### 3️⃣ Logs Ingested (Discover — logs-*)

![Logs Visible](./evidence/logs-visible-discover.png)

**Proves:**
- Logs successfully indexed
- Data view operational
- Host-based filtering works
- Real-time ingestion confirmed

---

### 4️⃣ Security Telemetry (system.auth)

![Security Auth Logs](./evidence/security-auth-logs-discover.png)

**Proves:**
- Authentication events captured
- Successful and session events visible
- SOC visibility into endpoint activity
- Security-relevant telemetry operational

---

### 5️⃣ Detection Engineering Validation

See:
- `./phases/phase-02-detection-engineering.md`

**Proves:**
- Detection logic was implemented and tested
- Multiple security-relevant rules were validated
- Alert generation from endpoint activity was confirmed

---

### 6️⃣ AI Triage Layer Validation

See:
- `./phases/phase-03-ai-triage-layer-integration.md`

**Proves:**
- Elastic alerts can be queried from the SOC management node
- AI-generated alert explanations were successfully produced
- Investigation notes and summaries are grounded in real Elastic data
- SQLite duplicate suppression logic was implemented

---

### 7️⃣ Executive Reporting Validation

See:
- `./phases/phase-04-executive-reporting-automation.md`

**Proves:**
- WhatsApp command-driven SOC interaction was implemented
- Flask, ngrok, Twilio, and Elastic were integrated end-to-end
- Operator-facing executive summaries and alert outputs were delivered successfully
