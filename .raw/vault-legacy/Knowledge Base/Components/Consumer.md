---
title: Consumer
tags:
  - component
  - backend
---

# engine/consumer.py — RabbitMQ Event Consumer

**Lines**: 224
**Role**: Processes Beelzebub events from RabbitMQ → PostgreSQL

## Data Flow

1. Connects to RabbitMQ queue `"event"`
2. Parses Beelzebub JSON into standardized dict
3. Computes SHA256 (chain of custody)
4. Calls `calculate_risk()` for scoring
5. Inserts into PostgreSQL `events` table

## Field Mapping

| Beelzebub | PostgreSQL |
|-----------|-----------|
| `DateTime` | `timestamp` |
| `RemoteAddr` / `SourceIp` | `source_ip` |
| `Protocol` | `protocol` |
| `Command` | `command` |
| HTTP: `HTTPMethod + RequestURI` | `command` |

## Related
- [[ADR-002 RabbitMQ Event Bus]]
- [[Risk Engine]]
- [[System Overview.canvas]]
