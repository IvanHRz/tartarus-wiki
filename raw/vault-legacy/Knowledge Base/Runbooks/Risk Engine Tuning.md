---
title: Risk Engine Tuning
tags:
  - runbook
  - detection
---

# Risk Engine Tuning

## When to Tune

- Too many false positives (high scores for benign traffic)
- Missing detections (attacks scoring low)
- New attack patterns not covered

## How to Tune

### 1. Review current constants

File: `engine/engine/risk_engine.py`

Key constants:
- `COMMON_PASSWORDS` — 50 common credentials
- `DANGEROUS_COMMANDS` — wget, curl, rm -rf, etc.
- `EXPLOIT_PATHS` — /wp-admin, /.env, /.git, etc.
- `SQLI_PATTERNS`, `TRAVERSAL_PATTERNS`, `XSS_PATTERNS`

### 2. Adjust base scores

```python
# Conservative (fewer alerts):
SSH_BASE = 20   # was 30

# Aggressive (more alerts):
SSH_BASE = 40   # was 30
```

### 3. Add new patterns

```python
DANGEROUS_COMMANDS.append("new_command")
EXPLOIT_PATHS.append("/new/exploit/path")
```

### 4. Verify with test data

```bash
cd engine && python -m pytest tests/ -v -k risk
```

> [!danger] Production Impact
> Changing scores affects dashboard alerts immediately.
> Test with representative data before deploying.

## Related
- [[ADR-003 Risk Scoring Algorithm]]
- [[Attack Flow.canvas]]
