---
title: "ADR-001: Canvas Only UI"
tags:
  - adr
  - architecture
status: accepted
date: 2026-03-10
---

# ADR-001: Canvas Only UI

## Context

The Tartarus dashboard needs real-time visualization of attack events, network topology, and risk distributions. Options considered: React, D3.js, Cytoscape, pure Canvas.

## Decision

**Pure HTML5 Canvas + vanilla JavaScript.** No frameworks.

- D3, vis.js, Cytoscape, React, Vue are all forbidden (Constraint C3)
- Canvas provides direct pixel control for custom attack visualizations
- Minimal bundle size, no build step needed
- nginx serves static files directly

## Consequences

- Custom rendering code for everything (tables, charts, badges)
- More development effort but zero dependency risk
- Excellent performance for real-time event streaming
- `ui/src/js/main.js` is the single JS file (~519 lines)

## Related
- [[Engine API]] — provides data via REST
