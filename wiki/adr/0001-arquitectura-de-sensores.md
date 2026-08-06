---
tipo: adr
estado: propuesta
creado: 2026-07-10
actualizado: 2026-07-10
commit_ref: 6f584b7
adr_original: .raw/docs/adr/ADR-001-sensor-architecture.md
bugs: [BUG-031b, BUG-032, BUG-041, BUG-043]
tags: [sensores, networking, schema, bootstrap]
---

# ADR-0001 — Arquitectura de sensores: networking, schema, bootstrap

> [!info] Documento fuente
> La ADR completa (459 líneas) vive en `.raw/docs/adr/ADR-001-sensor-architecture.md`, fechada 2026-05-06.
> **No se duplica aquí.** Esta página añade lo que la ADR no puede saber sobre sí misma: su estado real dos meses después.

## Qué decide

Cuatro bugs forman un cluster inseparable — `BUG-031b` scanner sin visibilidad LAN, `BUG-032` icmp-canary sin paquetes a ghost IPs, `BUG-041` dos tablas paralelas de sensores, `BUG-043` dos semánticas de bootstrap.

**Decisión: Opción A.** Bridge formal universal + scanner nativo fuera del compose + override Mac para icmp-canary. `DROP TABLE remote_sensors`. Unificar `KNOWN_SENSORS` + `POST_SEED_SENSORS` en `SEED_SENSORS` con campo `bootstrap_policy`.

## Estado real — verificado contra `6f584b7` (2026-07-10)

**La ADR sigue en `PROPOSED`. Nada se implementó. Es correcto: la propia ADR lo prohíbe** hasta pasar los 6 criterios de validación en hardware RPi 5 16GB.

| Cambio prescrito | Estado en HEAD |
|---|---|
| `DELETE engine/engine/sensor_router.py` | ⬜ el archivo existe |
| `DROP TABLE remote_sensors` | ⬜ sin `db/migrations/` |
| Remover `scanner:` del compose | ⬜ `docker-compose.yml:130` |
| `docker-compose.dev-mac-host-canary.yml` | ⬜ no existe |
| `SEED_SENSORS` + `bootstrap_policy` | ⬜ las dos listas siguen separadas |
| Validación en RPi 5 | ⬜ sin evidencia |

Único commit sobre sensores desde la ADR: `c1d3e4d` *feat(sensors): auto-register icmp-canary [BUG-034]* — anterior a la ADR en intención, no la implementa.

## Consecuencia observada que la ADR no anticipó

> [!warning] El audit de consumidores de `remote_sensors` está incompleto
> §2 del ADR lista los consumidores: `sensor_router.py` (4 endpoints), `deploy_router.py:290`, `schema.py`. Un `grep` contra `6f584b7` encuentra **dos más**:
>
> - `docs/generate_report.py:553` — la tabla aparece en el reporte generado como *"Sensores RPi registrados"*
> - `engine/tests/test_active_sensors_widget.py` — test de contrato que menciona la tabla en sus aserciones
>
> `DROP TABLE remote_sensors` sin tocar `generate_report.py` **rompe la generación de reportes**. Añadir a §5.1 antes de implementar.

Esto no invalida la decisión — la tabla sigue con 0 filas y el consumidor solo la lista, no la lee para nada crítico. Pero el ticket de Sprint 6+ está subestimado.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| **B** — Host networking universal | Rompe el DNS interno del bridge (`postgres`, `redis`, `broker` dejan de resolver). En Mac, Docker Desktop lo emula inconsistentemente → es la Opción A peor disfrazada. Expone Redis sin auth. |
| **E** — Scanner ↔ engine vía HTTP | No resuelve BUG-032 ni la esencia de BUG-031b (el transporte de jobs es ortogonal al networking). Crea dos canales para el mismo concepto. |

## Consecuencias aceptadas

- icmp-canary en bridge en producción base = **cero ingest ICMP**. No es regresión (ya es cero hoy), pero queda P2 hasta que se invoque el override o se despliegue en RPi.
- `setup-rpi.sh` no instala nmap ni crea systemd para el scanner nativo. ~30–50 LoC bash adicionales.
- Tabla `sensor_bootstrap_log`: **deferida**. Ver [[backlog]].

## Enlaces

- [[sensores]] — mapa del módulo
- [[roadmap]] — los 6 criterios de validación son ítems bloqueantes
