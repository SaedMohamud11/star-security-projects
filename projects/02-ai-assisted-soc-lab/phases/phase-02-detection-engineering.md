# Phase 02 – Detection Engineering

## Objective

Implement structured, production-style detection capabilities on top of the stabilized SOC infrastructure built in Phase 01.

This phase focuses on:

- Enabling Elastic Security detection engine
- Engineering multiple custom Linux detection rules
- Simulating adversary behavior in a controlled lab environment
- Validating alert generation end-to-end
- Performing rule tuning to reduce false positives
- Demonstrating real-world SOC detection workflow

No AI orchestration is introduced in this phase. The goal is to establish reliable and validated detection capability before automation.

---

## Detection Environment Overview

Detection capabilities were implemented using the Elastic Security application on the Elastic Node (VM 201).

### Detection Engine

- Elastic Security enabled
- Custom Query-based detection rules created
- Data source index pattern: `logs-system.auth*`
- Query language: KQL (Kibana Query Language)

### Rule Execution Configuration

- Execution interval: 1 minute
- Look-back window: 1 minute
- Maximum alerts per execution: 100

This configuration enables near real-time alerting while maintaining controlled execution and manageable alert volume.

---

## Design Philosophy

Detection engineering must be:

- Evidence-driven
- Testable
- Tunable
- Controlled
- Aligned to realistic attack behavior

Rules were not blindly enabled from prebuilt templates.

Instead, each detection rule was:

1. Designed based on observed endpoint telemetry
2. Tested using controlled lab activity
3. Validated in Security → Alerts
4. Tuned where necessary to reduce false positives
5. Re-tested after refinement

Raw journald/system authentication logs were inspected to understand field mappings and log structure before finalizing detection logic.

> Principle: Detection must be engineered and validated — not assumed.

---

## Detection Rules Implemented

The following custom Linux detection rules were engineered, tested, and validated during Phase 02.

---

### Rule 01 – Linux Sudo Usage Monitoring

**Purpose:** Detect sudo session usage on the Ubuntu endpoint.

**Detection Logic (Initial):**  
`event.dataset: "system.auth" AND host.os.type: "linux" AND process.name: "sudo" AND event.action: "logged-on"`

**Tuned Logic (Noise Reduction Applied):**  
`event.dataset: "system.auth" AND host.os.type: "linux" AND process.name: "sudo" AND event.action: "logged-on" AND NOT message: "*by saed(uid=*"`

**Goal:** Monitor privilege usage activity while reducing expected administrative noise.

---

### Rule 02 – Failed SSH Authentication Attempts

**Purpose:** Detect brute force or unauthorized SSH login attempts.

**Detection Logic:**  
`event.dataset: "system.auth" AND message: "Failed password"`

**Goal:** Detect authentication failures that may indicate credential abuse or brute force attempts.

---

### Rule 03 – New User Account Creation

**Purpose:** Detect potential persistence via creation of new local user accounts.

**Detection Logic (Process-Based):**  
`event.dataset: "system.auth" AND process.name: "useradd"`

**Alternate Pattern Observed:**  
`event.dataset: "system.auth" AND message: "new user"`

**Goal:** Detect privilege escalation or persistence through account creation.

---

### Rule 04 – User Deletion Monitoring

**Purpose:** Detect account removal that may indicate anti-forensics behavior or cleanup activity.

**Detection Logic:**  
`event.dataset: "system.auth" AND process.name: "userdel"`

**Goal:** Detect suspicious user removal events.

---

### Rule 05 – Refined Sudo Privilege Escalation Detection

This rule represents the final tuned version of sudo monitoring with noise reduction applied.

**Detection Logic (Final Version):**  
`event.dataset: "system.auth" AND host.os.type: "linux" AND process.name: "sudo" AND event.action: "logged-on" AND NOT message: "*by saed(uid=*"`

**Goal:** Detect privilege escalation activity while excluding trusted administrative behavior.

---

## Definition of Done (Phase 02)

Phase 02 is complete only when the following are verified:

### Detection Engine Operational

- Elastic Security application enabled
- All custom rules successfully created
- Rule execution status shows “Succeeded”
- No rule execution failures observed

### Alert Generation Validated

- Controlled test activity triggers alerts
- Alerts visible in Security → Alerts
- Alerts contain correct host association
- Severity and risk scores reflect escalation impact

### Rule Tuning Verified

- Initial noise identified where applicable
- Detection logic refined to reduce false positives
- Alerts still trigger under simulated suspicious activity

### Endpoint State Restored

- Test accounts created during validation removed
- Sudo group modifications reverted
- Endpoint returned to clean baseline state

---

## Validation Steps

The following controlled tests were performed to validate detection capability.

### Test 01 – Failed SSH Login

Simulated failed SSH authentication attempts.

Expected Result:
- Event visible in Discover
- Alert generated under Failed SSH Authentication rule

---

### Test 02 – User Creation

    sudo useradd labtestuser

Expected Result:
- Event visible in Discover
- Alert generated under New User Account Creation rule

---

### Test 03 – User Deletion

    sudo userdel labtestuser

Expected Result:
- Event visible in Discover
- Alert generated under User Deletion rule

---

### Test 04 – Sudo Group Privilege Escalation

    sudo usermod -aG sudo eviluser1

Expected Result:
- Event visible in Discover
- Alert generated under privilege escalation monitoring

---

### Test 05 – Sudo Session Activity

    sudo ls

Expected Result:
- Alert generated under Sudo Monitoring rule
- After tuning, alert suppressed for trusted administrative activity

---

## Evidence Collection

Evidence for Phase 02 must include the following:

- Screenshot of each detection rule configuration (all five rules)
- Screenshot of alert triggered for each rule
- Screenshot of Security → Alerts view showing rule metadata
- Screenshot showing rule execution status (“Succeeded”)
- Screenshot of Discover view validating raw event structure

All evidence files are stored in:

    projects/02-ai-assisted-soc-lab/evidence/phase-02-detection-engineering/

---

## Engineering Discipline Note

Phase 02 is not considered complete based on alert creation alone.

It is complete only when:

- Detection rules execute successfully
- Alerts are validated in Security → Alerts
- Raw logs are inspected and understood
- Noise is analyzed and tuned responsibly
- Alert lifecycle workflow is verified
- Evidence is documented and stored

Detection must be proven functional before AI automation is introduced.

A SOC without validated detection logic is not operational.
