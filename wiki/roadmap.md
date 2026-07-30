---
tipo: roadmap
creado: 2026-07-09
actualizado: 2026-07-30
commit_ref: 0085c31
---

# Roadmap — Tartarus

Estados: `idea` → `decidido` (tiene ADR) → `en curso` (tiene issue) → `hecho` (tiene release) → `descartado` (con razón)
**Nada se borra.** Lo descartado es tan informativo como lo hecho.

## Hecho — MSSP / multi-tenancy (v0.5.0 → v0.6.2, PR #8)

| Ítem | Estado | ADR | Commit |
|---|---|---|---|
| Multi-tenancy "Flocks" (aislamiento por flock_id) | hecho | [[0002-multi-tenancy-flocks]] | `78b4263` |
| RBAC 3 roles | hecho | [[0003-rbac-tres-roles]] | `3f83f1c` |
| Acknowledge + consistencia de ventana | hecho | [[0004-acknowledge-limpieza-de-ruido]] | `665cd09` |
| Attack Map contexto de despliegue | hecho | [[0005-attack-map-contexto-de-despliegue]] | `5891465` |
| Consola de dos niveles (madre/workspace) | hecho | [[0006-consola-dos-niveles]] | `4b707ed` |
| Fijar Beelzebub a v3.8.0 (reproducibilidad) | hecho | — | `965c65c` |

## En curso — bloqueantes de despliegue (issues abiertos)

| Ítem | Estado | Issue | Nota |
|---|---|---|---|
| Ingesta muerta (canal AMQP se cae) | en curso | `#10` | **crítico — condición de "desplegable"**. Healthcheck de ingesta + reconexión. |
| `events.honeypot_id` siempre NULL | en curso | `#11` | Bloquea el join real events→sensor. Clave estable de sensor en `events`. |
| Test de integración con Postgres real | idea | — | El aislamiento entre flocks solo se prueba con pool mockeado. |

## Bloqueante: validación en hardware RPi 5 16GB

[[0001-arquitectura-de-sensores]] es `PROPOSED` y **prohíbe** implementar hasta pasar los 6 criterios. Todo lo demás del cluster de sensores depende de esto.

| # | Criterio | Estado |
|---|---|---|
| 1 | Scanner nativo escanea LAN real (≥1 host distinto del propio RPi) | ⬜ |
| 2 | icmp-canary en host networking recibe ping a ghost IP → evento en `/events` en <5 s | ⬜ |
| 3 | Stack del bridge levanta sin `name resolution failed` | ⬜ |
| 4 | `GET /sensors` devuelve `sensor_registry` (≥6 sensores, sin shape legacy) | ⬜ |
| 5 | `DROP TABLE remote_sensors` limpio, `COUNT(*)=0` re-confirmado antes | ⬜ |
| 6 | Bootstrap idempotente: 3 restarts con sensor borrado → `COUNT(*)` sigue en 5 | ⬜ |

## Implementación (Sprint 6+, bloqueada por lo anterior)

| Ítem | Estado | ADR | Issue | Nota |
|---|---|---|---|---|
| Eliminar `sensor_router.py` (~104 LoC) | decidido | [[0001-arquitectura-de-sensores]] | — | |
| Migración `DROP TABLE remote_sensors` | decidido | 0001 | — | ⚠ **actualizar `docs/generate_report.py:553` primero** |
| Sacar `scanner:` del compose → nativo en host | decidido | 0001 | — | nmap + `setcap` + systemd unit + `scanner-host.py` |
| `docker-compose.dev-mac-host-canary.yml` | decidido | 0001 | — | |
| `field-rpi.yml`: añadir icmp-canary con `network_mode: host` | decidido | 0001 | — | + `ip addr add` de ghost IPs en `setup-rpi.sh` |
| Unificar `SEED_SENSORS` + `bootstrap_policy` | decidido | 0001 | — | |
| Alias `GET /sensors` → `GET /sensors/status` | decidido | 0001 | — | |
| `GET /deploy/status`: leer registry o deprecar | decidido | 0001 | — | decisión menor, se cierra al implementar |

## Descartado

| Ítem | Por qué | Fecha |
|---|---|---|
| Host networking universal (Opción B) | Rompe DNS interno del bridge; Docker Desktop lo emula mal en Mac; expone Redis sin auth | 2026-05-06 |
| Scanner ↔ engine vía HTTP (Opción E) | No resuelve BUG-032 ni el fondo de BUG-031b; dos canales para el mismo concepto | 2026-05-06 |
