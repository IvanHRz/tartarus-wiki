---
title: "InfraMap — Layered Attack Topology"
tags: [tartarus, component, canvas, visualization, infra]
status: active
date: 2026-03-13
file: "ui/src/js/infra.js"
---

# InfraMap

> Static layered topology canvas visualization of the deception infrastructure and active attackers.

## Purpose

Shows the full attack surface at a glance: which IPs are attacking, which honeypot services they're targeting, and the data flow into the analysis engine. Unlike the [[NeuralGraph]] (force-directed, nodes per-event), InfraMap is a structured layer diagram oriented to infrastructure overview.

## Architecture

```
INTERNET (cloud)
    │
Attacker IPs  (from /api/sessions, up to 6)
    │
Honeypot Services  (SSH:22, HTTP:80, TCP:8080, TELNET:23)
    │
ENGINE (analysis)
```

## Data Sources

| Endpoint | Refresh | Data Used |
|----------|---------|-----------|
| `/api/sessions` | 8s | Attacker IPs, max_risk, event_count, ports_targeted |
| `/api/events/stats` | 8s | total_events, risk_distribution, by_protocol |

## Canvas Rendering

- Pure Canvas2D (no D3, no libraries)
- HiDPI support via `devicePixelRatio`
- Layout is **static** (not force-directed) — fixed Y positions per layer
- Edges drawn as quadratic Bezier curves with midpoint control
- **Flow dots** animated along Bezier paths matching edge geometry

### Node Types

| Type | Shape | Color |
|------|-------|-------|
| `internet` | Rounded rect | `#374151` |
| `attacker` | Rounded rect + glow dot | `riskColor(max_risk)` |
| `service` | Rounded rect | `SERVICE_COLORS[proto]` |
| `engine` | Rounded rect | `#1d4ed8` |

### Edge Encoding

- **Attacker edges**: colored by `riskColor(risk)` + semi-transparent, solid line
- **Engine edges**: `#30363d` dashed — passive data flow, not active attack
- **Line width**: `Math.log(event_count) * 0.8` — proportional to attack volume
- **Flow dots**: spawn on attacker→service edges, travel along Bezier at random speeds

## Metrics Panel

DOM panel updated on every data load:

| Element ID | Content |
|------------|---------|
| `#infraAttackers` | Active session count |
| `#infraTotal` | Total events (localized) |
| `#infraCrit` | Critical risk events |
| `#infraHigh` | High risk events |
| `#infraMed` | Medium risk events |
| `#infraLow` | Low risk events |
| `#infraProtoBars` | Protocol breakdown bars (up to 4) |
| `#infraTopTarget` | Most-hit service + count |
| `#infraStatus` | Badge: "N attackers detected" / "Loading…" |

## Code Location

`ui/src/js/infra.js` — `InfraMap` class, initialized via `DOMContentLoaded` on `#infraCanvas`.

## Related

- [[NeuralGraph]] — per-event force-directed graph (real-time WebSocket)
- [[Risk Engine]] — scoring that drives node colors
- [[Sprint v0.5.2 — UX Polish + InfraMap]]
