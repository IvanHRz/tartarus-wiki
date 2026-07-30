---
title: Engine API
tags:
  - service
  - roadmap
service_status: running
port: "9000"
image: "python:3.12-slim"
description: "FastAPI backend — events, intel, scanning"
status: completed
priority: 1
date: 2026-03-10
---

# Engine API

FastAPI server providing event access, intelligence enrichment, and scan orchestration.

## Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Infrastructure checks |
| `/events` | GET | Filtered event stream |
| `/events/stats` | GET | Summary statistics |
| `/events/attack-summary` | GET | Dashboard data |
| `/intel/{ip}` | GET | IP enrichment (Shodan + GeoIP) |
| `/credentials/stats` | GET | SSH credential patterns |
| `/sessions` | GET | Attack sessions |
| `/scan` | POST | Queue nmap job |

## Constraints
- `engine/main.py` < 500 lines (currently 346)
- Zero pandas
- Async-first (asyncpg, aio-pika)

## Related
- [[System Overview.canvas]]
- [[ADR-002 RabbitMQ Event Bus]]
