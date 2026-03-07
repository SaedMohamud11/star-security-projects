# Phase 04 – Executive Reporting Automation

## Objective

Extend the AI triage layer into a usable executive reporting and operator messaging workflow.

This phase focuses on:

- Exposing a Flask webhook for inbound WhatsApp commands
- Integrating Twilio WhatsApp messaging with the SOC management node
- Using ngrok to securely tunnel the local Flask service for webhook testing
- Returning command-driven SOC outputs to a mobile device
- Delivering concise alert summaries, investigation notes, and executive briefings through WhatsApp
- Proving end-to-end communication from user request to SOC response

The purpose of this phase is not to automate final analyst judgment.

The purpose is to make validated Elastic detections and AI-assisted summaries available in a fast, operator-friendly format.

---

## Executive Reporting Environment Overview

The executive reporting workflow was implemented on **VM 200 – SOC-MGMT** and connected the following components:

- **Flask application**
- **Twilio WhatsApp Sandbox / Messaging**
- **ngrok HTTPS tunnel**
- **Custom command router in `soc_bot.py`**
- **AI triage functions imported from `elastic_poller.py`**

### Primary Script

` soc_bot.py `

### Supported Commands

- `check alerts`
- `soc summary`
- `last alert`
- `investigate`

### Webhook Route

- `/whatsapp`

---

## Design Philosophy

Security outputs are only valuable if they can be delivered clearly and quickly.

This phase was designed around three principles:

- readability
- responsiveness
- operator control

The delivery layer does not replace Elastic, and it does not replace analyst decision-making.

Instead, it acts as the presentation and interaction layer for the existing SOC workflow.

This keeps the architecture grounded:

- Elastic remains the detection platform
- Python remains the orchestration layer
- OpenAI remains the summarization layer
- Twilio WhatsApp becomes the operator delivery layer

> Principle: Reporting automation should reduce friction, not reduce analyst ownership.

---

## Messaging Workflow Implemented

The following workflow was implemented and validated:

1. User sends a WhatsApp command
2. Twilio forwards the inbound message to the Flask webhook
3. ngrok tunnels the HTTPS request to the SOC management node
4. `soc_bot.py` parses the command
5. The matching function in `elastic_poller.py` is executed
6. Elastic data is retrieved and optionally summarized by OpenAI
7. Flask builds the outbound response
8. Twilio returns the message back to WhatsApp
9. The operator receives the SOC output on mobile

---

## Core Reporting Functions

### Flask Webhook Handling

The Flask application listens for POST requests at:

`/whatsapp`

The webhook receives the inbound WhatsApp message body and normalizes it for command matching.

Operational value:

- Creates a live interaction point for the SOC workflow
- Allows mobile-first command execution
- Keeps the interface simple and easy to demonstrate

---

### Command Routing

The bot routes inbound text commands to the correct backend function.

Mapped commands:

- `check alerts` → `check_alerts()`
- `soc summary` → `soc_summary()`
- `last alert` → `last_alert()`
- `investigate` → `investigate()`

Operational value:

- Gives the operator predictable command-driven access
- Keeps the interface intentionally small and testable
- Supports future expansion without changing the delivery model

---

### Message Splitting Logic

A `split_message()` helper was implemented to keep outgoing responses readable and within practical message length constraints.

Behavior:

- preserve formatting where possible
- split on paragraph breaks, line breaks, or spaces
- keep responses under the configured character limit

Operational value:

- Prevents large outputs from becoming unreadable
- Improves reliability of message delivery
- Makes summaries suitable for phone-based review

---

### ngrok Tunnel Exposure

An ngrok tunnel was used to expose the local Flask app running on port `5000` to Twilio over HTTPS.

Operational value:

- enabled rapid webhook testing without public infrastructure
- allowed the SOC-MGMT node to receive live external webhook traffic
- made it possible to validate the WhatsApp workflow end-to-end

---

## High-Level Executive Reporting Flow

    User sends WhatsApp command
        ↓
    Twilio receives inbound message
        ↓
    ngrok forwards request to SOC-MGMT
        ↓
    Flask webhook receives POST /whatsapp
        ↓
    soc_bot.py routes command
        ↓
    elastic_poller.py retrieves and analyzes data
        ↓
    Response is formatted and split if needed
        ↓
    Twilio sends WhatsApp reply
        ↓
    User receives SOC report on phone

---

## Definition of Done (Phase 04)

Phase 04 is complete only when the following are verified:

### Webhook Delivery Verified

- Flask is reachable locally on port `5000`
- ngrok exposes the local Flask app over HTTPS
- Twilio is configured to send inbound WhatsApp requests to the ngrok URL
- POST requests successfully reach `/whatsapp`

### Command Execution Verified

- `check alerts` returns the expected open-alert output
- `soc summary` returns a recent SOC executive briefing
- `last alert` returns the most recent alert explanation
- `investigate` returns a short analyst note

### Mobile Messaging Verified

- Responses are visible in WhatsApp
- Message text is readable on mobile
- Long responses are split safely when needed
- No malformed command output is returned

### End-to-End Integration Verified

- Twilio, ngrok, Flask, and Elastic all operate together
- AI-generated summaries are returned successfully
- The operator can issue commands from a phone and receive valid SOC responses
- The workflow is suitable for demonstration and documentation purposes

---

## Validation Steps

The following checks were used to validate the executive reporting automation layer.

### Test 01 – Flask Service Running

Start the Flask application on the SOC-MGMT node.

Expected Result:
- Flask binds to `0.0.0.0:5000`
- The app is reachable locally
- No startup errors prevent webhook handling

---

### Test 02 – ngrok Tunnel Active

Launch ngrok against local port `5000`.

Expected Result:
- A public HTTPS forwarding URL is created
- Incoming requests are visible in the ngrok session
- The tunnel forwards traffic to the local Flask app

---

### Test 03 – Twilio Webhook POST Delivery

Send a WhatsApp message to the Twilio-connected number.

Expected Result:
- Twilio issues a POST request to `/whatsapp`
- Flask logs a successful `200` response
- The command body is received correctly by the application

---

### Test 04 – Command Response Validation

Execute each supported command from WhatsApp.

Commands tested:

- `check alerts`
- `soc summary`
- `last alert`
- `investigate`

Expected Result:
- Each command maps to the correct backend function
- A valid response is returned to WhatsApp
- Outputs remain concise and readable

---

### Test 05 – Executive Summary Delivery

Run the `soc summary` command against recent alert and endpoint data.

Expected Result:
- A management-style SOC summary is returned
- The output includes date/time and relevant environment context
- The summary is suitable for quick operational review on mobile

---

## Evidence Collection

Evidence for Phase 04 must include the following:

- Screenshot of Flask running `soc_bot.py`
- Screenshot of ngrok showing active forwarding to port `5000`
- Screenshot of successful POST requests to `/whatsapp`
- Screenshot of WhatsApp response for `check alerts`
- Screenshot of WhatsApp response for `soc summary`
- Screenshot of WhatsApp response for `last alert`
- Screenshot of WhatsApp response for `investigate`

All evidence files are stored in:

    projects/02-openclaw-soc/evidence/phase-04-executive-reporting-automation/

---

## Engineering Discipline Note

Phase 04 is not complete just because a chatbot replies on a phone.

It is complete only when:

- the webhook path is functioning reliably
- the reported content is grounded in real Elastic data
- command routing is deterministic
- response formatting is readable
- delivery is validated end-to-end
- evidence is preserved for demonstration and review

A messaging bot without validated SOC content is just a UI demo.

A messaging bot that returns validated SOC output is an operational reporting layer.
