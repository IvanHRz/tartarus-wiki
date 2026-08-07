---
tipo: postmortem
creado: 2026-08-07
actualizado: 2026-08-07
commit_ref: 0085c31
tags: [rabbitmq, amqp, consumer, ingesta, "#10", deploy-blocking]
---

# Postmortem — Ingesta AMQP ciega (#10)

> Bug bloqueante de despliegue. Reproducido en **dos sesiones** distintas. Detección y
> auto-reconexión implementadas 2026-08-07 (pendiente verificación E2E con el stack).

## Impacto

Los honeypots capturaban ataques pero el dashboard mostraba **0 eventos** — indistinguible de
"no me atacan". En un despliegue de campo (Raspberry en red del cliente) esto significa que la
plataforma queda **ciega en producción sin ninguna señal de alarma**. Un ataque real de 116 sondas
produjo 0 filas en `events` hasta reiniciar Beelzebub.

## Timeline

1. Beelzebub arranca, publica a RabbitMQ (cola `event`, `durable=False`), el consumer ingiere OK.
2. Tras un periodo de inactividad, el **canal publisher de Beelzebub** muere
   (`channel/connection is not open`).
3. `aio_pika.connect_robust` del consumer mantiene viva la **conexión**, así que no hay error del
   lado consumer: `queue.iterator()` simplemente **se queda esperando** mensajes que ya no llegan.
4. `consumer:status` sigue en `connected`, `/health` reporta `ok` (sólo checaba pg/redis/consumer).
5. Nadie se entera hasta que un humano nota el dashboard en 0 y reinicia Beelzebub manualmente.

## Causa raíz

Dos capas independientes, ninguna observando la **frescura de la ingesta**:
- **Publisher (Beelzebub):** su canal AMQP muere por inactividad y no se recupera solo.
- **Observabilidad (engine):** `/health` medía *liveness de dependencias* (pg/redis/consumer vivo),
  no *que estén entrando eventos*. Un consumer "vivo pero mudo" pasaba como sano.

Relacionado: [[0008-rabbitmq-event-bus]] — la promesa "los eventos nunca se pierden" era mito
(cola no-durable + este canal caído).

## Fix (commit 0085c31 + working-tree 2026-08-07)

- **Detección** — `engine/engine/ingestion_health.py` (`ingestion_status`, predicado puro) + el
  consumer estampa `consumer:last_event_ts` en cada evento (`consumer.py`). `/health` (`main.py`)
  ahora expone `checks.ingestion` = `ok | stale | idle | unknown` y marca el body `degraded` cuando
  la ingesta lleva > `INGESTION_STALE_SECONDS` (600s por defecto) detenida habiendo tenido tráfico.
  La liveness (200/503) la siguen gobernando pg/redis — la ingesta muerta **no** tumba el engine
  (el culpable es Beelzebub), sólo lo marca degradado. 7 tests en `test_ingestion_health.py`.
- **Auto-reconexión** — el consumer envuelve la espera de mensajes con
  `asyncio.wait_for(..., CONSUMER_IDLE_RECONNECT_SECONDS=300)`: si no llega nada en ese lapso,
  cicla la conexión AMQP para forzar un **canal fresco** (recupera el publisher muerto o el
  iterador atascado).

> [!warning] Verificación E2E pendiente
> La detección está probada en unit tests. La reconexión por inactividad y el flip a
> `degraded/ingestion_stale` requieren el stack Docker arriba para validarse extremo a extremo.

## Cómo lo detectamos

Un humano notó el dashboard en 0 tras lanzar un ataque simulado. **Ese es exactamente el fallo**:
la única "detección" era ojo humano. El fix convierte eso en una señal de `/health`.

## Qué lo habría prevenido

- Un **healthcheck de frescura de ingesta** desde el día 1 (lo que ahora hace `/health`).
- `restart: unless-stopped` en Beelzebub (ya presente) **no basta**: el proceso no muere, sólo su
  canal. Hace falta o el ciclado de conexión del consumer (implementado) o un healthcheck de
  Beelzebub que reinicie ante canal muerto.
- Es criterio de [[deploy-checklist]]: no se despliega sin este check verde.

## Enlaces
- [[0008-rabbitmq-event-bus]] · [[consumer]] · [[deploy-checklist]] · [[v0.6.2]]
