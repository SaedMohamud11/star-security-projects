# Phase 03 – AI Triage Layer Integration

## Objective

Integrate a custom AI-assisted triage layer on top of the validated Elastic detection stack built in Phases 01 and 02.

This phase focuses on:

- Querying Elastic alerts directly from the SOC management node
- Enriching alert output with structured Python logic
- Using OpenAI `gpt-4o-mini` for concise SOC-oriented explanations
- Preventing duplicate alert notifications through SQLite state tracking
- Creating command-driven analyst outputs for rapid triage
- Proving end-to-end alert retrieval and AI explanation generation

This phase does not introduce autonomous decision-making or case closure logic.

The goal is to create a controlled AI triage assistant that helps interpret detection output while keeping the human analyst as the final authority.

---

## AI Triage Environment Overview

The AI triage layer was implemented on **VM 200 – SOC-MGMT** and connected to **VM 201 – Elastic Node** over the internal lab network.

### Core Components

- **Python 3**
- **OpenAI API**
- **Model:** `gpt-4o-mini`
- **Elasticsearch REST queries over HTTPS**
- **SQLite local tracking database**
- **Custom Python script:** `elastic_poller.py`

### Data Sources Queried

- Alert index: `.alerts-security.alerts-default`
- Log index pattern: `logs-*`

### Purpose of the Triage Layer

The triage layer converts raw Elastic detections into readable SOC outputs by:

1. Pulling current or recent alert data from Elasticsearch
2. Extracting key fields such as rule name, severity, host, timestamp, message, source IP, and user
3. Sending structured prompt context to OpenAI
4. Returning short, readable analyst-style output for operator review

---

## Design Philosophy

AI triage must be:

- Controlled
- Explainable
- Evidence-driven
- Non-destructive
- Human-reviewed

The model is not used as a source of truth.

Instead, Elastic remains the source of truth, and the AI layer is used strictly to:

- summarize
- explain
- organize
- prioritize analyst attention

This prevents the project from overstating AI autonomy and keeps the workflow aligned to realistic SOC operations.

> Principle: AI may assist triage, but validated detections remain the foundation of the SOC.

---

## Core Triage Functions Implemented

The following functions were implemented inside `elastic_poller.py`.

### `check_alerts()`

Purpose:

- Retrieve currently open alerts from Elastic
- Compare returned alert IDs against the SQLite notification database
- Return only alerts that are still open and have not already been reported

Operational value:

- Prevents repeated noise in analyst messaging
- Preserves state across alert checks
- Simulates basic alert memory for triage workflow

---

### `last_alert()`

Purpose:

- Pull the most recent alert from Elastic
- Extract rule, severity, host, status, process, user, source IP, and message
- Generate a concise AI explanation suitable for quick analyst review

Operational value:

- Provides a readable explanation of the latest detection
- Helps translate raw alert fields into analyst-ready wording

---

### `investigate()`

Purpose:

- Pull the latest alert from Elastic
- Ask the AI model to generate a short analyst note with investigation guidance

Operational value:

- Produces fast first-pass investigation support
- Suggests next validation steps without claiming final judgment

---

### `soc_summary()`

Purpose:

- Pull recent alerts and recent endpoint events from the last 24 hours
- Generate a concise AI-written SOC summary for operator visibility

Operational value:

- Creates a management-style summary from both alerts and endpoint activity
- Bridges tactical detections to broader operational awareness

---

## SQLite Alert Memory

A local SQLite database was introduced to prevent duplicate alert notifications.

### Database File

`processed_alerts.db`

### Table Used

`notified_alerts`

### Stored Fields

- `alert_id`
- `notified_at`
- `rule_name`
- `host_name`
- `severity`

### Operational Purpose

This database allows the triage layer to remember which alerts have already been surfaced to the operator.

Without this memory layer, repeated polling would resend the same alert output and reduce usability.

---

## High-Level Triage Flow

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
    Output returned to calling application

---

## Definition of Done (Phase 03)

Phase 03 is complete only when the following are verified:

### Elastic-to-Triage Connectivity

- SOC-MGMT can successfully query Elasticsearch
- Alert data is returned from `.alerts-security.alerts-default`
- Relevant endpoint event data is returned from `logs-*`
- No blocking connectivity issue exists between VM 200 and VM 201

### AI Triage Functionality

- OpenAI API authentication works from the SOC-MGMT node
- `gpt-4o-mini` returns readable SOC explanations
- Output is cleaned into WhatsApp-friendly plain text
- Alert summaries remain concise and understandable

### State Tracking Verified

- SQLite database is created successfully
- Alert IDs are recorded after notification
- Previously reported open alerts are not repeatedly re-sent
- New open alerts still surface correctly

### Command Logic Verified

- `check_alerts()` returns current open alert state
- `last_alert()` returns the latest alert explanation
- `investigate()` returns a short analyst note
- `soc_summary()` returns a recent SOC environment briefing

---

## Validation Steps

The following checks were used to validate the AI triage layer.

### Test 01 – Elastic Alert Retrieval

Validate that `elastic_poller.py` can retrieve alerts from the Elastic alert index.

Expected Result:
- Alert data is returned successfully
- No authentication or query failure occurs
- Recent alert fields are visible to the script

---

### Test 02 – Recent Endpoint Event Retrieval

Validate that recent endpoint activity can be pulled from `logs-*`.

Expected Result:
- Recent `system.auth` or `system.syslog` events are returned
- Event messages are available for AI summarization
- Host context is preserved

---

### Test 03 – Latest Alert Explanation

Trigger or reference a recent Elastic alert and run the latest alert workflow.

Expected Result:
- The AI returns a readable explanation of the alert
- Output includes host and alert context
- Response is concise and operationally useful

---

### Test 04 – Investigation Output

Run the investigation workflow on the latest alert.

Expected Result:
- The AI returns a short analyst-style note
- Output includes suggested next review steps
- The response remains recommendation-only

---

### Test 05 – Duplicate Alert Suppression

Run repeated alert checks against the same open alert set.

Expected Result:
- Previously reported alert IDs are not re-sent
- Only new open alerts appear in subsequent checks
- SQLite state persists correctly

---

## Evidence Collection

Evidence for Phase 03 must include the following:

- Screenshot of `soc_bot.py` or related service calling the triage layer successfully
- Screenshot showing successful POST requests to `/whatsapp`
- Screenshot of `last alert` response
- Screenshot of `investigate` response
- Screenshot or diagram of the triage flow from Elastic alert to AI explanation
- Screenshot showing the project files on the SOC management node if needed for implementation proof

All evidence files are stored in:

    projects/02-ai-assisted-soc-lab/evidence/phase-03-ai-triage-layer-integration/

---

## Engineering Discipline Note

Phase 03 is not considered complete just because an LLM response appears on screen.

It is complete only when:

- Elastic detections are already validated
- AI output is grounded in actual retrieved alert data
- Duplicate notification behavior is controlled
- Triage output is readable and operationally useful
- Human review remains the final decision point
- Evidence is documented and stored

AI assistance without validated detection logic is theater.

Validated detections plus controlled AI triage is an actual SOC workflow improvement.
