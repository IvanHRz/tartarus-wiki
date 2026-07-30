---
title: "ADR-004 — WebSocket sobre Polling para Real-Time Events"
tags: [tartarus, adr, websocket, architecture, decision]
status: accepted
date: 2026-03-12
---

# ADR-004 — WebSocket sobre Polling para Real-Time Events

## Estado

**Accepted** — Implementado en Fase 4 (v0.5.0)

## Contexto

Hasta Fase 3, la UI usaba `setInterval(loadEvents, 5000)` — polling REST cada 5 segundos. Esto implica:
- **Latencia**: hasta 5s desde que ocurre un ataque hasta que se ve en pantalla
- **Carga innecesaria**: queries PostgreSQL cada 5s aunque no haya eventos nuevos
- **No escalable**: múltiples pestañas = múltiples timers de polling
- **No compatible con Neural Graph**: el grafo necesita push para animar en tiempo real

El `CLAUDE.md` define TARTARUS como una plataforma que "visualizes attack patterns as a Neural Graph in real-time Canvas". Eso requiere latencia <1s.

## Decisión

Agregar **FastAPI WebSocket endpoint** (`/ws/events`) con un registry de conexiones desacoplado (`ws_manager.py`). El consumer hace push de cada evento inmediatamente después del INSERT.

## Alternativas Consideradas

### Server-Sent Events (SSE)
- ✅ Más simple que WS, unidireccional
- ❌ No soportado por todos los proxies nginx (require config especial)
- ❌ No permite keepalive ping/pong nativo

### WebSocket con Redis Pub/Sub
- ✅ Escala horizontalmente (múltiples instancias)
- ❌ Complejidad innecesaria para instancia única (dev + prod actual)
- ❌ Introduce dependencia extra

### Long Polling
- ✅ Más compatible
- ❌ Latencia similar al polling regular
- ❌ No es "real-time"

### WebSocket directo (elegido)
- ✅ Latencia <100ms (en LAN)
- ✅ FastAPI lo soporta nativamente (Starlette)
- ✅ Sin dependencias extras
- ✅ Auto-reconnect en frontend (4s backoff)
- ✅ Keepalive ping cada 30s (evita timeout de proxies)

## Consecuencias

### Positivas
- Eventos aparecen en el grafo en tiempo real
- Sin polling → CPU del servidor baja durante idle
- Base para futuros eventos bidireccionales (e.g., comandos de respuesta)

### Negativas / Trade-offs
- No escala a múltiples instancias del engine sin Redis Pub/Sub
- El `_clients` set es in-memory: si el engine se reinicia, todos los clientes reconectan (auto-handled)
- Cuidado con `_clients -= dead` (augmented assignment → UnboundLocalError). **Usar `difference_update()`**.

## Implementación

```
engine/engine/ws_manager.py  ← Registry global compartido
engine/main.py              ← @app.websocket("/ws/events")
engine/engine/consumer.py   ← broadcast_event(event) post-INSERT
ui/src/js/graph.js          ← NeuralGraph.connectWS()
```

## Relacionado

- [[ws_manager]]
- [[NeuralGraph]]
- [[Fase 4 Neural Graph + WebSocket]]
