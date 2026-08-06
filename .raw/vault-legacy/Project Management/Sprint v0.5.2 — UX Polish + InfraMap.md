---
title: "Sprint v0.5.2 — UX Polish + Infrastructure Map"
tags: [tartarus, sprint, ux, inframap, risk-engine]
status: completed
date: 2026-03-13
version: "0.5.2"
---

# Sprint v0.5.2 — UX Polish + Infrastructure Map

## Summary

Five targeted improvements identified from visual review of the UI, plus a new Infrastructure Map visualization.

---

## Changes

### 1. Zoom Sensitivity Fix (`ui/src/js/graph.js`)

**Problem**: Scroll/trackpad zoom was too aggressive — 10% per event made fine positioning impossible.

**Fix**: Normalized deltaY for trackpad vs mouse wheel:
```javascript
const norm   = Math.sign(e.deltaY) * Math.min(Math.abs(e.deltaY), 50);
const factor = 1 + norm * -0.0012;  // ~6% max per event
```
Trackpad sends many small deltaY values; mouse sends few large ones. `Math.min(abs, 50)` caps both to the same effective range.

---

### 2. Live Events Page Size (`ui/src/js/main.js`)

**Problem**: `PAGE_SIZE = 50` but the feed panel has `max-height: 300px` — only ~5 rows visible without scrolling.

**Fix**: `PAGE_SIZE = 15`. At ~22px per row, 15 rows ≈ 330px — fills the panel naturally with scroll available for more.

---

### 3. Deception Risk Baseline (`engine/engine/risk_engine.py`)

**Problem**: Base score of 10 was too low. On a deception platform, no legitimate access exists — any connection is an attack.

**Philosophy**: Any touch to a honeypot = unauthorized by definition.

**Changes**:
- Global baseline: `score = 10` → `score = 30`
- HTTP base: `+10` → `+20` (any HTTP to honeypot = active reconnaissance)
- TCP base: `+10` → `+15` (raw TCP probe = network scanning)

**Risk badge** (`riskBadge()` in `main.js`) now shows labels + deception tooltip:
- `≥80` → `CRIT` (red)
- `≥60` → `HIGH` (orange)
- `≥30` → `MED` (yellow)
- `<30` → `LOW` (green)

---

### 4. Credential Analysis Labels (`ui/src/js/main.js`)

**Problem**: `"2x (1 IPs)"` was compact but ambiguous.

**Fix**:
- Top Combos: `"N attempts · N source IPs"`
- Top Usernames: `"N attempts"`
- Top Passwords: `"N attempts"`
- Credential Reuse: `"N unique IPs — coordinated!"`

Card subtitles added (`index.html`):
- **Top Combos** — "Most-used username:password pairs"
- **Top Usernames** — "Attempted login names"
- **Top Passwords** — "Attempted passwords"
- **Credential Reuse** — "Same credentials from multiple IPs = coordinated attack"

---

### 5. Infrastructure Map (NEW — `ui/src/js/infra.js`)

New `#infraSection` with a pure Canvas layered topology visualization.

**Layout**: Canvas (60%) + Metrics panel (40%)

**Data sources**: `/api/sessions` + `/api/events/stats` — refreshes every 8s

**Canvas layers** (top to bottom):
```
Layer 0: [☁ INTERNET]          y=36
Layer 1: [IP1] [IP2] [IP3]     y=110  ← from /api/sessions
Layer 2: [SSH:22] [HTTP:80]... y=195  ← services derived from ports_targeted
Layer 3: [⚙ ENGINE]            y=272
```

**Visual features**:
- Animated flow dots along quadratic Bezier attack paths
- Node color = risk level of attacker
- Edge thickness = `log(event_count)`
- Colored left accent bar on every node
- Status glow dot on attacker nodes
- HiDPI canvas support (`devicePixelRatio`)

**Metrics panel** (DOM):
- Active Attackers count
- Total Events
- Risk distribution (CRITICAL / HIGH / MED / LOW)
- Protocol breakdown with animated fill bars
- Top targeted service

---

## Files Modified

| File | Change |
|------|--------|
| `ui/src/js/graph.js` | Zoom sensitivity normalization |
| `ui/src/js/main.js` | PAGE_SIZE 15, riskBadge labels, credential text |
| `ui/src/js/infra.js` | **NEW** — InfraMap class (layered topology canvas) |
| `ui/src/index.html` | `#infraSection` HTML, credential subtitles, v0.5.2 |
| `ui/src/css/tartarus.css` | InfraMap styles, `.cred-card-sub` |
| `engine/engine/risk_engine.py` | Baseline 10→30, HTTP +20, TCP +15 |

---

## Next Phase

→ [[Fase 5 — Case Management Frontend]]
- Backend: `engine/case_db.py` + `engine/case_router.py` already implemented with DuckDB
- Frontend: Sidebar panel + journal UI + case tagging
