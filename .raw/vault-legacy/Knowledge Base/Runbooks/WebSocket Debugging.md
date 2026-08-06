---
title: "WebSocket Debugging — Tartarus Real-Time Events"
tags: [tartarus, runbook, websocket, debugging, troubleshooting]
status: active
date: 2026-03-12
---

# WebSocket Debugging — Tartarus Real-Time Events

## Síntomas Comunes

### Grafo no aparece / canvas vacío
1. Abrir DevTools → Console → buscar errores de import de `graph.js`
2. Verificar que `<script type="module">` está en el HTML (requerido para ES modules)
3. El canvas necesita que el parent tenga dimensiones — `.graph-panel` hereda height de `.intel-panel { height: 540px }`

### WS status siempre "Connecting…"
El indicador `#graph-ws-status` permanece amarillo. Causas:

```bash
# 1. Verificar que el engine está levantado
curl http://localhost:9000/health

# 2. Verificar que el endpoint WS existe
curl http://localhost:9000/ws/info
# → {"connected_clients": 0}

# 3. Probar WS directamente (necesita wscat: npm i -g wscat)
wscat -c "ws://localhost:9000/ws/events"
# Debe conectar y recibir {"type":"ping"} cada 30s

# 4. Via nginx proxy (UI)
wscat -c "ws://localhost:8888/api/ws/events"
```

### Nodos no aparecen al llegar ataques
```bash
# 1. Verificar que consumer procesa eventos
docker logs tartarus-engine --tail 50 | grep "Ingested"

# 2. Verificar client count en tiempo real
watch -n 2 "curl -s localhost:9000/ws/info"
# Debe mostrar 1+ cuando tienes la UI abierta
```

### Grafo se congela
- `requestAnimationFrame` pausa cuando la pestaña está en background — normal
- Volver a la pestaña reanuda automáticamente
- Si el canvas queda en 0×0 → refrescar con Cmd+R

---

## Diagnóstico Completo

```bash
# Estado general
curl -s localhost:9000/health | python3 -m json.tool

# Sesiones (lo que seedea el grafo al cargar)
curl -s localhost:9000/sessions | python3 -m json.tool

# WS connections activas
curl -s localhost:9000/ws/info
```

### Checklist rápido
- [ ] `curl :9000/health` → `"status":"ok"`
- [ ] `curl :9000/ws/info` responde
- [ ] `wscat -c ws://localhost:9000/ws/events` conecta
- [ ] Ping llega dentro de 30s
- [ ] Con SSH event (`ssh -p 2222 root@localhost`), wscat recibe `{"type":"event",...}`
- [ ] DevTools Network → WS frame visible en UI

---

## Generar Eventos de Prueba

```bash
# SSH brute force → nodos SSH:22 + IPs en grafo
for i in $(seq 1 5); do
    sshpass -p "admin" ssh -p 2222 -o StrictHostKeyChecking=no root@localhost 2>/dev/null
done

# HTTP probe → nodo HTTP:8880
curl -s http://localhost:8880/wp-admin
curl -s "http://localhost:8880/api?id=1' OR 1=1--"

# TCP connect → nodo TCP
nc -z localhost 8080
```

Cada comando genera un nodo en el grafo dentro de ~100ms.

---

## Errores Conocidos

> [!danger] `UnboundLocalError: cannot access local variable '_clients'`
> **Causa**: `_clients -= dead` — augmented assignment crea variable local en Python.
> **Fix**: Usar `_clients.difference_update(dead)` (in-place, sin assignment).
> **Archivo**: `engine/engine/ws_manager.py`

> [!warning] `WebSocketDisconnect` al cerrar pestaña
> Comportamiento normal. El bloque `finally: await disconnect(websocket)` en `main.py` limpia automáticamente.

---

## Relacionado

- [[ws_manager]]
- [[NeuralGraph]]
- [[ADR-004 WebSocket Real-Time]]
- [[Docker Dev Setup]]
