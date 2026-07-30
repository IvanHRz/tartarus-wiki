---
tipo: adr
estado: aceptada
creado: 2026-07-30
actualizado: 2026-07-30
commit_ref: 0085c31
tags: [flocks, multi-tenancy, mssp, schema, consumer]
---

# ADR-0002 — Multi-tenancy: "Flocks"

## Contexto

Tartarus nació mono-tenant: un despliegue, un operador, todo global. El salto a
modelo MSSP (un proveedor atiende a varios clientes desde una consola) exige
**aislamiento**: el Manager del Cliente A no debe ver nada del Cliente B. Thinkst
resuelve esto con "flocks" (bandadas) — la abstracción que adoptamos por nombre y
concepto.

El reto real no es crear la tabla `flocks`; es que **cada entidad de pantalla**
(eventos, detecciones, kill-chain, sesiones, tokens, honey-creds, hosts, sensores)
pueda filtrarse por cliente sin reescribir 20 queries a mano ni migrar el histórico.

Implementado en 6 tandas: Fase 1 aislamiento `0058d9d`, Fase 2 RBAC `3f83f1c`
(ver [[0003-rbac-tres-roles]]), Fase 3 asignaciones `8f928e7`, Fase 5 filtro global
`0c36b1d`, Fase 4 per-flock completo `78b4263`, Fase 5 sensores `5891465`.

## Decisión

**`flock_id UUID` nullable en cada entidad, donde `NULL == Default Flock`.**

- Sin backfill: las filas pre-existentes quedan NULL y siguen funcionando como
  "Default" (retrocompatibilidad total). `engine/engine/schema.py` `alter_columns`.
- El consumer estampa `flock_id` en ingesta vía `flock_resolver.resolve_flock_id`
  por regla del operador (`protocol` / `honeypot_id` / `source_ip` CIDR, first-match).
- Los lectores filtran con el fragmento compartido `_flock_clause` (`flock_id = $N::uuid`
  para un flock concreto; sin filtro = global).
- Los writers derivados **heredan** el `flock_id` del evento origen (detecciones en
  `consumer.py`, kill-chain vía subquery a `event_ids`, honey-creds del POST).

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| **Backfill `NULL → default-uuid`** | Obliga a migrar todo el histórico y reescribir el resolver. `NULL=Default` es gratis. **Pero** tiene un costo real: el Default no se puede scopear por UUID (ver Consecuencias). |
| **`flock_id NOT NULL`** | Fuerza el backfill anterior y rompe cualquier inserción que no resuelva flock (canary saltaba el resolver — `d16f116`, arreglado en `5891465`). |
| **Base de datos por tenant** | Sobredimensionado para la escala actual; multiplica la carga de ops (migraciones ×N, backups ×N) sin beneficio de aislamiento que una columna + RBAC no den ya. |

## Consecuencias

- **El Default Flock no tiene workspace propio.** Como sus eventos llevan `flock_id
  NULL` y `_flock_clause` genera `flock_id = $`, seleccionar el Default por su UUID
  devuelve 0 filas. Por eso en la UI el Default **es** la vista global, no un cliente
  aislado (ver [[0006-consola-dos-niveles]]). Es la deuda que `NULL=Default` nos cobró.
- **Asignación por `honeypot_id` es frágil.** Depende del `HandlerName` de Beelzebub,
  que es texto libre y **de hecho llega vacío** (issue `#11`). Las vías robustas son
  `protocol` y `source_ip/CIDR`.
- El `flock_id` llegó tarde a honey-creds/sensores (Fase 4/5), no en la Fase 1 — hubo
  una ventana donde "por-flock" era mentira parcial para esas entidades.
- Ganancia: un helper (`_flock_clause` / `_windowed_where`) scopea ~13 superficies sin
  duplicar lógica. El aislamiento se probó E2E (Cliente A no ve eventos de B).

## Estado real — verificado contra `0085c31` (2026-07-30)

Implementado y mergeado (#8). `flock_id` presente en: `events`, `canary_tokens`,
`detections`, `kill_chain_traces`, `correlation_sessions`, `honey_credentials`,
`hosts`, `sensor_registry`, `remote_sensors`. 835 tests verdes.

| Prometido | Estado |
|---|---|
| Aislamiento entre flocks | ✅ E2E: workspace de un flock no muestra otro |
| Consumer estampa flock_id | ✅ `consumer.py` vía `flock_resolver` |
| Writers derivados heredan | ✅ detecciones/kill-chain/honey/canary |
| Test de integración con Postgres real | ⬜ los 835 tests son unit con pool mockeado — el aislamiento nunca se prueba contra una DB real |

## Enlaces

- [[0003-rbac-tres-roles]] — quién ve qué dentro del aislamiento
- [[0006-consola-dos-niveles]] — cómo se navega madre ↔ flock
- [[sintesis]]
