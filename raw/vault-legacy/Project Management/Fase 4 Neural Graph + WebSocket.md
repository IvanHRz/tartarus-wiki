---
title: "Fase 4 — Neural Graph Canvas + WebSocket Real-Time"
tags: [tartarus, phase, neural-graph, websocket, canvas, frontend]
status: completed
date: 2026-03-13
version: "0.5.1"
tests_passing: 44
---

# Fase 4 — Neural Graph Canvas + WebSocket Real-Time

> [!success] Fase completada
> 44/44 tests passing. Engine v0.5.1. Neural Graph en producción.

## Contexto

La Fase 3 entregó risk scoring, MITRE ATT&CK, threat intel, credential analysis, y session correlation. Sin embargo, el dashboard seguía siendo solo tablas y texto — sin visualización. El `CLAUDE.md` promete explícitamente **"Neural Graph in real-time Canvas"** y prohíbe D3, Cytoscape, y vis.js.

**Problema**: Polling de 5 segundos + sin visualización = no hay "deception platform", solo un SIEM básico.

**Solución**: WebSocket para push real-time + Neural Graph HTML5 Canvas puro.

---

## Cambios Entregados

### Backend

#### `engine/engine/ws_manager.py` (NUEVO)
Connection registry desacoplado. `_clients: set[WebSocket]` compartido entre `main.py` y `consumer.py` sin circular imports. Funciones:
- `connect(ws)` — acepta y registra cliente
- `disconnect(ws)` — elimina del registry
- `broadcast(msg)` — push a todos, limpia clientes muertos automáticamente
- `broadcast_event(event)` — formatea y envía evento de honeypot
- `client_count()` — número de clientes activos

#### `engine/main.py` — WebSocket Endpoint
```
WS  /ws/events     Push de eventos + keepalive ping cada 30s
GET /ws/info       Número de clientes conectados actualmente
```

#### `engine/engine/consumer.py`
Después de cada `INSERT` exitoso → `await broadcast_event(event)` push inmediato a todos los clientes WS.

### Frontend

#### `ui/src/js/graph.js` (NUEVO, ~430 líneas)
Clase `NeuralGraph` completa. Canvas puro con `requestAnimationFrame`.

| Feature | Implementación |
|---------|---------------|
| Force-directed layout | Repulsión Coulomb + Spring Hooke + gravedad central + damping |
| Nodos | Tipo `attacker` (IP) y `service` (SSH:22, HTTP:80, etc.) |
| Edges | Grosor = log(event_count), color = max risk level del edge |
| Animaciones | Pulso viajero (punto que viaja del attacker al service, 700ms) |
| High-risk glow | `shadowBlur` animado con `sin()` para nodos críticos (≥80) |
| Interactividad | Hover tooltip, click → intel popover, drag, zoom/pan |
| WebSocket | Cliente integrado, auto-reconecta en 4s si se cierra |
| Seed histórico | Llama `/api/sessions` al cargar para poblar con datos existentes |

#### Layout 2 paneles
```
┌──────────────────────┬────────────────────┐
│   NEURAL GRAPH       │   LIVE EVENTS FEED  │
│   Canvas (flex 1)    │   Tabla 420px        │
│                      │   6 columnas         │
│   [Force physics]    │   [Time|IP|Proto]    │
│   [Pulse animations] │   [Risk|Cmd|MITRE]   │
└──────────────────────┴────────────────────┘
```

### Tests
`engine/tests/test_ws.py` — 12 tests nuevos:
- `test_connect_registers_client`
- `test_disconnect_removes_client`
- `test_broadcast_sends_to_all_clients`
- `test_broadcast_removes_dead_client` (dead client cleanup automático)
- `test_broadcast_noop_when_no_clients`
- `test_broadcast_event_formats_correctly`
- `test_broadcast_event_truncates_long_command`
- `test_broadcast_event_handles_missing_fields`

---

## Archivos Modificados

| Archivo | Tipo | Cambio |
|---------|------|--------|
| `engine/engine/ws_manager.py` | NUEVO | Connection registry + broadcast |
| `engine/main.py` | MODIFICADO | `/ws/events` + `/ws/info` + import ws_manager |
| `engine/engine/consumer.py` | MODIFICADO | `broadcast_event()` post-insert |
| `ui/src/js/graph.js` | NUEVO | NeuralGraph class completa |
| `ui/src/index.html` | MODIFICADO | Layout 2 paneles, canvas, v0.5.0 |
| `ui/src/js/main.js` | MODIFICADO | ES module, initGraph(), showIntelPopoverAt() |
| `ui/src/css/tartarus.css` | MODIFICADO | `.intel-panel`, `.graph-panel`, `.feed-panel` |
| `engine/tests/test_ws.py` | NUEVO | 12 tests WebSocket |

---

## Verificación

```bash
# Tests
cd engine && python -m pytest tests/ -v
# Resultado: 44/44 passed

# WS endpoint
wscat -c ws://localhost:9000/ws/events
# Espera ping cada 30s

# WS via nginx proxy
wscat -c ws://localhost:8888/api/ws/events

# Generar evento real
ssh -p 2222 root@localhost
# → Nodo aparece en grafo en <1s

# Info endpoint
curl localhost:9000/ws/info
# {"connected_clients": N}
```

---

## v0.5.1 — UI Redesign (2026-03-13)

### Cambios
1. **Layout stacked** — Eliminado grid `1fr 420px` side-by-side. Ahora: Graph full-width (580px) encima + Live Events full-width (max 300px) debajo. Tabla de events con columnas expandidas y legibles.
2. **HiDPI / Retina fix** — `_resize()` aplica `devicePixelRatio`. Canvas físico = lógico × dpr. `_render()` escala ctx por dpr. Canvas nítido en Apple Silicon M4 (DPR 2×).
3. **Label pills** — Texto de nodo con fondo `rgba(13,17,23,0.72)` + `roundRect`, font `11px -apple-system`. Legible sobre cualquier fondo.
4. **Glow para risk 60–79** — Glow estático 7px para nodos "high" (además del glow animado para "critical" ≥80).
5. **Fix CSS vars** — `var(--surface)` → `var(--bg2)`, `var(--surface2)` → `var(--bg3)` (nunca estaban definidas en `:root`).

---

## Métricas

| Métrica | Valor |
|---------|-------|
| Tests passing | 44/44 (+12 vs Fase 3) |
| Latencia evento→grafo | <100ms (vs 5000ms polling) |
| graph.js LOC | ~650 líneas |
| ws_manager.py LOC | ~90 líneas |
| main.py LOC | 370 líneas (bajo límite 500) |
| Dependencias nuevas | 0 (FastAPI WebSocket ya incluido) |

---

## Relacionado

- [[ADR-004 WebSocket Real-Time]]
- [[ws_manager]]
- [[NeuralGraph]]
- [[WebSocket Debugging]]
- [[Fase 3 Risk Engine + Intelligence]]
