---
tipo: modulo
creado: 2026-08-06
actualizado: 2026-08-06
commit_ref: 0085c31
tags: [consumer, ingesta, rabbitmq, flocks]
---

# Módulo: Consumer

> Verificado contra `0085c31` el 2026-08-06. Si el HEAD actual difiere mucho, esta página miente.
> Comprobar: `bash tools/stale_modules.sh`

## Responsabilidad

El pipeline de ingesta: consume el JSON de Beelzebub desde RabbitMQ, lo parsea a filas
de `events`, estampa el flock, corre Sigma/YARA, y hace push a las capas en vivo
(WebSocket, kill-chain tracer). `engine/engine/consumer.py`. God-node `_parse_event()`.

## Entradas / salidas

- **In:** mensajes AMQP de la cola `event` (`QUEUE_NAME`). JSON con `SourceIp`, `Protocol`,
  `HandlerName`, `Command`, `HostHTTPRequest`, etc.
- **Out:** filas en `events` (+ `detections`), `broadcast_event()` al WS, `tracer.record_event()`,
  incremento de `consumer:events_total` en Redis.

## Invariantes

- **Un solo consumer** sobre la cola `event`. No hay competing consumers.
- Todo evento recibe `flock_id` (vía `flock_resolver`, `NULL=Default`) antes del INSERT
  — ver [[0002-multi-tenancy-flocks]].
- Las detecciones heredan el `flock_id` de su evento (Fase 4).

## Trampas conocidas

> [!danger] La cola es `durable=False` (`consumer.py:444`)
> Los eventos **no** sobreviven un reinicio del broker. Contradice la promesa de
> [[0008-rabbitmq-event-bus]]. Beelzebub crea la cola non-durable; el consumer se adapta.

> [!warning] `honeypot_id` = `HandlerName`, que llega vacío (issue `#11`)
> `consumer.py:280` lee `raw.get("HandlerName")`, pero Beelzebub emite `Handler` (vacío),
> no `HandlerName`. Resultado: `events.honeypot_id` siempre NULL → no hay join a
> `sensor_registry`. Ver [[0005-attack-map-contexto-de-despliegue]].

> [!warning] El protocolo se re-clasifica por puerto
> `_PORT_PROTOCOL_MAP` (`consumer.py:177`): telnet y mcp llegan a Beelzebub como
> `ssh`/`http` y se corrigen por `dest_port`/`ServerAddr` (23→TELNET, 3000→MCP,
> 2112/2113→PROMETHEUS). Cambiar puertos sin tocar este mapa rompe la clasificación.

> [!danger] Fiabilidad de la conexión — issue `#10`
> El canal AMQP de Beelzebub se cae por inactividad y la ingesta muere en silencio.
> No es del consumer (que espera conectado), sino del publisher. Bloqueante de despliegue.

## Grafo

God-nodes de este módulo: `_parse_event()` (30 edges), `calculate_risk()` (67, ver
[[risk-engine]]). Estructura completa: `bash tools/graph_query.sh "_parse_event"`.
