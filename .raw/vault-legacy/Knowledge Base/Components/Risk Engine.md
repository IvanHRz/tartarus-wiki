---
title: Risk Engine
tags:
  - component
  - detection
---

# engine/risk_engine.py — Event Risk Scorer

**Lines**: 224
**Role**: Scores events 0-100 with MITRE ATT&CK mapping

## Scoring Model

Returns tuple: `(risk_score, mitre_tactic, mitre_technique)`

### Base Scores
- SSH: 30, HTTP: 20, TCP: 25

### Key Patterns
- `DANGEROUS_COMMANDS`: wget, curl, rm -rf, cat /etc/passwd
- `EXPLOIT_PATHS`: /wp-admin, /phpmyadmin, /.env, /.git
- `SQLI_PATTERNS`, `XSS_PATTERNS`, `TRAVERSAL_PATTERNS`
- `COMMON_PASSWORDS`: 50 common credentials

## Related
- [[ADR-003 Risk Scoring Algorithm]]
- [[Risk Engine Tuning]]
- [[Consumer]] — calls `calculate_risk()`
