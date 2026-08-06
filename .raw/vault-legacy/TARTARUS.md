---
title: "TARTARUS — IR Deception Platform"
tags: [tartarus, index, overview]
status: active
date: 2026-03-12
version: "0.5.0"
---

# TARTARUS — IR Deception Platform

> Active defense and deception platform. Captures attacker interactions via LLM-powered honeypots, scores risk with heuristics + MITRE ATT&CK, and visualizes attack patterns as a Neural Graph in real-time Canvas.

## Stack

| Layer | Tech |
|-------|------|
| Honeypot | Beelzebub (Go, LLM-powered) |
| Backend | Python 3.12 / FastAPI / Polars |
| Frontend | HTML5 Canvas (sin frameworks) |
| DB | PostgreSQL 15 + Redis 7 |
| Broker | RabbitMQ 3 |
| Real-time | WebSocket (FastAPI nativo) |
| Infra | Docker Compose + OrbStack |

## Quick Start

```bash
cd /Users/ivanhuerta/Documents/Tartarus
make up-dev

# URLs
# UI:       http://localhost:8888
# Engine:   http://localhost:9000
# RabbitMQ: http://localhost:15672
# SSH trap: ssh -p 2222 root@localhost
```

---

## Fases del Proyecto

| Fase | Estado | Descripción |
|------|--------|-------------|
| Fase 1 — Base | ✅ Completada | Consumer RabbitMQ, PostgreSQL schema, health endpoint |
| Fase 2 — Sensors | ✅ Completada | Beelzebub integration, nmap scanner, host discovery |
| Fase 3 — Intelligence | ✅ Completada | Risk engine, MITRE ATT&CK, threat intel, credential analysis |
| Fase 4 — Neural Graph | ✅ Completada (v0.5.2) | WebSocket real-time, Canvas force-directed graph, HiDPI fix, layout stacked, InfraMap, UX polish |
| Fase 5 — Case Management | 🔄 En progreso | Incident cases, tagging, journal entries — backend DuckDB listo |
| Fase 6 — Forensic Export | 🔲 Pendiente | STIX 2.1, PDF reports, IOC export |
| Fase 7 — AI Chat | 🔲 Pendiente | MCP server, LLM-powered deception analysis |

---

## Arquitectura

```
Beelzebub ──► RabbitMQ ──► Consumer ──► PostgreSQL
  (SSH)         │              │
  (HTTP)        │         Risk Engine ──► MITRE ATT&CK
  (TCP)         │         broadcast_event()
  (Telnet)      │              │
                │         WebSocket ──► Neural Graph (Canvas)
                │              │
                └──────────────► Events Feed (REST)
```

---

## Componentes

### Backend
- [[Consumer]] — RabbitMQ → PostgreSQL pipeline
- [[Risk Engine]] — Scoring 0-100 + MITRE mapping
- [[ws_manager]] — WebSocket connection registry

### Frontend
- [[NeuralGraph]] — Force-directed Canvas visualization (per-event, real-time WebSocket)
- [[InfraMap]] — Layered attack topology Canvas (infrastructure overview)

---

## Knowledge Base

### Decisiones de Arquitectura (ADRs)
- [[ADR-001 Canvas Only UI]] — Sin D3, Cytoscape, vis.js
- [[ADR-002 RabbitMQ Event Bus]] — Broker para desacoplar honeypot del engine
- [[ADR-003 Risk Scoring Algorithm]] — Modelo aditivo heurístico 0-100
- [[ADR-004 WebSocket Real-Time]] — WS sobre polling para <100ms latencia

### Runbooks
- [[Docker Dev Setup]] — `make up-dev`, variables de entorno, rebuild
- [[WebSocket Debugging]] — Troubleshooting WS y Neural Graph
- [[Risk Engine Tuning]] — Ajustar constantes de scoring
- [[Adding a Honeypot Service]] — Agregar nuevo protocolo a Beelzebub

### Glosario
- [[Glossary]]

---

## Tests

```bash
cd engine && python -m pytest tests/ -v
# 44/44 passing (v0.5.0)
```

| Suite | Tests | Cobertura |
|-------|-------|-----------|
| `test_consumer.py` | 29 | SHA256, parsing, risk engine, constraints |
| `test_health.py` | 3 | main.py < 500 líneas, no pandas, imports |
| `test_ws.py` | 12 | WebSocket registry, broadcast, formateo de mensajes |

---

## Chronos-DFIR

Este vault también contiene documentación del proyecto hermano:
→ [[Chronos-DFIR Index]]
