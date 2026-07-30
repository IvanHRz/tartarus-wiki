---
title: "ws_manager — WebSocket Connection Registry"
tags: [tartarus, component, websocket, backend, python]
status: active
date: 2026-03-12
file: engine/engine/ws_manager.py
lines: ~90
---

# ws_manager — WebSocket Connection Registry

## Propósito

Módulo independiente que actúa como registry global de conexiones WebSocket. Desacoplado de `main.py` para evitar circular imports con `consumer.py`.

> [!tip] Patrón clave
> `consumer.py` importa de `ws_manager.py`, NO de `main.py`. Esto rompe el círculo `main → consumer → main`.

---

## Estado Global

```python
_clients: set[WebSocket] = set()
_lock    = asyncio.Lock()
```

El set es **módulo-level** — compartido por todos los importadores. `asyncio.Lock` protege mutaciones concurrentes.

---

## API Pública

### `connect(websocket) → None`
Llama `accept()` y registra el cliente.

### `disconnect(websocket) → None`
Elimina del registry. Noop si no existe (idempotente).

### `broadcast(message: dict) → None`
Envía JSON a todos los clientes conectados.
- Toma snapshot del set antes de iterar (evita mutación durante iteración)
- Clientes que lanzan excepción → marcados como "dead" y removidos con `difference_update()`

> [!warning] Importante
> Usar `_clients.difference_update(dead)` en lugar de `_clients -= dead`.
> El operador `-=` hace augmented assignment → Python trata `_clients` como variable local → `UnboundLocalError`.

### `broadcast_event(event: dict) → None`
Wrapper sobre `broadcast()` que formatea el evento de honeypot:
```python
{
    "type": "event",
    "data": {
        "source_ip": str,
        "dest_port": int | None,
        "protocol": str,
        "risk_score": int,
        "mitre_tactic": str | None,
        "mitre_technique": str | None,
        "timestamp": str (ISO 8601),
        "command": str (truncado a 200 chars)
    }
}
```

### `client_count() → int`
Número de clientes actualmente conectados. Usado por `/ws/info` endpoint.

---

## Flujo de Mensajes

```
Beelzebub → RabbitMQ → consumer.py
                           ↓
                      _parse_event()
                           ↓
                      _insert_event() → PostgreSQL
                           ↓
                      broadcast_event(event) → ws_manager
                           ↓
                      broadcast() → todos los WS clients
                           ↓
                      graph.js recibe {"type":"event","data":{...}}
                           ↓
                      NeuralGraph._handleEvent() → nuevo nodo + pulso
```

---

## Mensaje de Keepalive

El endpoint `/ws/events` envía ping cada 30s para mantener conexiones activas en proxies con timeout:
```json
{"type": "ping", "clients": 3}
```

---

## Tests

Ver `engine/tests/test_ws.py` — 12 tests cubriendo:
- Registro/desregistro de clientes
- Broadcast a múltiples clientes
- Cleanup automático de clientes muertos
- Formateo correcto del mensaje de evento
- Truncamiento de comandos largos
- Manejo de eventos con campos faltantes

---

## Relacionado

- [[NeuralGraph]] — Frontend que consume los eventos WS
- [[Consumer]] — Llama `broadcast_event()` post-insert
- [[ADR-004 WebSocket Real-Time]]
- [[Fase 4 Neural Graph + WebSocket]]
