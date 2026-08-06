---
title: "ADR-003: Risk Scoring Algorithm"
tags:
  - adr
  - detection
status: accepted
date: 2026-03-10
---

# ADR-003: Risk Scoring Algorithm

## Context

Each honeypot event needs a severity score (0-100) for dashboard prioritization and alerting.

## Decision

**Additive scoring model** in `engine/risk_engine.py`:

### Base Scores
| Protocol | Base |
|----------|------|
| SSH | 30 |
| HTTP | 20 |
| TCP | 25 |

### Modifiers
| Pattern | Score |
|---------|-------|
| Dangerous commands (wget, curl, rm -rf) | +25 |
| Privilege escalation (sudo, /etc/passwd) | +20 |
| Exploit paths (/wp-admin, /.env) | +30 |
| SQL injection patterns | +35 |
| XSS patterns | +25 |
| Brute-force indicator | +10 |
| Lateral movement | +15 |
| External IP | +5 |

### MITRE Mapping
Each scored event gets a `mitre_tactic` and `mitre_technique` assigned.

## Consequences

- Simple, deterministic, explainable
- Easy to tune (just adjust constants)
- Scores capped at 100
- No ML required — pattern matching only

## Related
- [[Risk Engine]] — implementation details
- [[Attack Flow.canvas]] — kill chain visualization
