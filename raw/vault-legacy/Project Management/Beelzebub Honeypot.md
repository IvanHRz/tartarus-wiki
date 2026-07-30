---
title: Beelzebub Honeypot
tags:
  - service
  - roadmap
service_status: running
port: "2222, 8880"
image: "m4r10/beelzebub:latest"
description: "LLM-powered honeypot (SSH, HTTP, TCP, Telnet)"
status: completed
priority: 1
date: 2026-03-10
---

# Beelzebub Honeypot

LLM-powered honeypot that captures attacker interactions across multiple protocols.

## Protocols

| Protocol | Port | Config |
|----------|------|--------|
| SSH | 2222 | `beelzebub/configurations/services/ssh-22.yaml` |
| HTTP | 8880 | `beelzebub/configurations/services/http-80.yaml` |
| TCP | 8080 | `beelzebub/configurations/services/tcp-8080.yaml` |
| Telnet | 23 | `beelzebub/configurations/services/telnet-23.yaml` |

## Related
- [[Consumer]] — processes events from RabbitMQ
- [[Risk Engine]] — scores captured events
