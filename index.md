---
tipo: index
actualizado: 2026-07-30
commit_ref: 0085c31
---

# Índice — Wiki Tartarus

El agente lee este archivo **antes** de cualquier query.

## Estado

- [[sintesis]] — el proyecto en una página
- [[roadmap]] — bloqueado por la validación en hardware RPi 5
- [[backlog]] — 3 ideas diferidas con su razonamiento

## ADRs

| # | Título | Estado |
|---|---|---|
| [[0001-arquitectura-de-sensores]] | Networking, schema y bootstrap del sensor | **propuesta** — sin implementar, por diseño |
| [[0002-multi-tenancy-flocks]] | Aislamiento por `flock_id` (`NULL=Default`) | **aceptada** — mergeada #8 |
| [[0003-rbac-tres-roles]] | 3 roles fail-closed + fail-open en dev | **aceptada** — #8 |
| [[0004-acknowledge-limpieza-de-ruido]] | Ocultar-no-borrar + consistencia de ventana | **aceptada** — #8 |
| [[0005-attack-map-contexto-de-despliegue]] | Interno/externo, MITRE, host:puerto | **aceptada** — #8 |
| [[0006-consola-dos-niveles]] | Madre (global) vs workspace de flock | **aceptada** — #8 |

## Postmortems

*(vacío — candidato inmediato: issue `#10`, la ingesta AMQP muerta)*

## Módulos

- [[sensores]] — registro, bootstrap y telemetría. `commit_ref: 6f584b7`

## Releases

*(vacío — v0.6.2 documentada vía ADRs 0002–0006; falta página de release formal)*

---

## Fuentes sin ingerir

| Fuente | Ruta | Estado |
|---|---|---|
| Vault legacy (marzo, v0.5.0) — 23 notas | `raw/vault-legacy/` | **pendiente** — prioridad alta, siguiente operación |
| `CHANGELOG.md` | `raw/repo/CHANGELOG.md` | **pendiente** |
| `Docs/architecture/`, `Docs/audits/`, `Docs/api/` | `raw/docs/` | **pendiente** |
| `Fixes/`, `Plan_despliegue/` | `raw/repo/` | **pendiente** |

> Historial de git v0.5.0→v0.6.2 (`6f584b7`..`0085c31`): **ingerido** — ver ADRs 0002–0006 y [[roadmap]].
