---
tipo: roadmap
creado: 2026-07-09
actualizado: 2026-07-10
commit_ref: 6f584b7
---

# Roadmap — Tartarus

Estados: `idea` → `decidido` (tiene ADR) → `en curso` (tiene issue) → `hecho` (tiene release) → `descartado` (con razón)
**Nada se borra.** Lo descartado es tan informativo como lo hecho.

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
