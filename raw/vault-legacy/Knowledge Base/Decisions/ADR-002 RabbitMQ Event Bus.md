---
title: "ADR-002: RabbitMQ Event Bus"
tags:
  - adr
  - architecture
status: accepted
date: 2026-03-10
---

# ADR-002: RabbitMQ Event Bus

## Context

Beelzebub generates events at variable rates (bursts during brute-force attacks). The consumer needs to process events asynchronously without blocking the honeypot.

## Decision

**RabbitMQ as message broker** between Beelzebub and the Python consumer.

- Queue: `event` — single consumer
- Beelzebub publishes JSON events via AMQP
- Consumer (`engine/consumer.py`) processes asynchronously via `aio-pika`
- Decouples honeypot from processing pipeline

## Consequences

- Events are never lost (RabbitMQ persistence)
- Consumer can be restarted without losing events
- Processing pipeline can be scaled independently
- Management UI at port 15672 for monitoring

## Related
- [[Consumer]] — the RabbitMQ consumer
- [[System Overview.canvas]] — architecture diagram
