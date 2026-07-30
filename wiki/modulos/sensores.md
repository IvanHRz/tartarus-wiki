---
tipo: modulo
creado: 2026-07-10
actualizado: 2026-07-10
commit_ref: 6f584b7
tags: [sensores, networking, schema]
---

# Módulo: sensores

> Verificado contra `6f584b7` el 2026-07-10. Si el HEAD actual difiere mucho, esta página miente.
> Comprobar: `bash tools/stale_modules.sh`

## Responsabilidad

Registro, bootstrap y telemetría de los nodos que emiten eventos: Beelzebub (×5), OpenCanary, icmp-canary, scanner.

## Estado del schema — dos tablas, una viva

| Tabla | Origen | Filas | Escritores |
|---|---|---|---|
| `sensor_registry` | Sprint 2 (BUG-022) | 6 | `sensor_registry_router.py` |
| `remote_sensors` | pre-Sprint 2 (Phase 14) | **0** | ninguno |

`remote_sensors` está muerta pero **no huérfana**: la leen `sensor_router.py`, `deploy_router.py:290`, `schema.py:40`, `docs/generate_report.py:553` y un test. Ver [[0001-arquitectura-de-sensores]].

## Endpoints

| Path | Router | Tabla |
|---|---|---|
| `GET/POST /sensors`, `POST /sensors/{id}/heartbeat`, `DELETE /sensors/{id}` | `sensor_router.py` | `remote_sensors` (vacía) |
| `POST /sensors/heartbeat` (HMAC) | `sensor_registry_router.py` | `sensor_registry` |
| `GET /sensors/status`, `GET /sensors/topology` | `sensor_registry_router.py` | `sensor_registry` |

> [!warning] Trampa: `GET /sensors` devuelve vacío
> Es el router legacy. El endpoint real es `GET /sensors/status`. Esto ya causó `BUG-033` (el widget ACTIVE SENSORS apuntaba a `/api/deploy/status`). Hay un test de contrato que lo vigila: `engine/tests/test_active_sensors_widget.py`.

## Bootstrap — dos semánticas

- `KNOWN_SENSORS` (5 Beelzebub): se inserta **solo si la tabla está vacía**. Preserva el borrado por operador.
- `POST_SEED_SENSORS` (1 icmp-canary): se inserta **en cada boot** vía `ON CONFLICT DO NOTHING`. **No** preserva el borrado.

Edge case no documentado en código: `KNOWN_SENSORS` preserva el operator-delete solo mientras quede ≥1 sensor en la tabla. Si se borran todos, re-bootstrapea. Semántica "todo o nada".

## Networking

Todo el stack en bridge `tartarus_default`. Consecuencias:

- **scanner** ve solo `192.168.97.x` (subred docker), no la LAN del operador → inútil en un engagement real.
- **icmp-canary** no recibe paquetes a las ghost IPs `192.168.10.247` / `.248` (hardcoded en `sensors/icmp_canary/config.yml`, no expandidas por env var) → cero ingest E2E en Lab/Demo Mac.

Salir del bridge rompería el DNS interno (`postgres`, `redis`, `broker`). Ese es el nudo que [[0001-arquitectura-de-sensores]] desata.

## Compose

`docker-compose.yml` (base) · `dev-mac.yml` (ports/volumes) · `field-rpi.yml` (RPi, ~1.5 GB, sin scanner ni icmp-canary) · `sensor-only.yml` (standalone vía AMQP)
