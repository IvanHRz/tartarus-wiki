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
| [[0007-canvas-puro-sin-frameworks]] | Canvas + vanilla JS (C3) | **aceptada** — legacy, vigente |
| [[0008-rabbitmq-event-bus]] | RabbitMQ entre honeypot y consumer | **aceptada** — legacy; "never lost" contradicho (`#10`) |
| [[0009-risk-scoring-aditivo]] | Score 0–100 determinista, sin ML | **aceptada** — legacy, vigente |
| [[0010-websocket-real-time]] | `/ws/events` push post-INSERT | **aceptada** — legacy; huérfana (Neural Graph retirado) |

## Postmortems

*(vacío — candidato inmediato: issue `#10`, la ingesta AMQP muerta)*

## Módulos

- [[consumer]] — pipeline de ingesta (RabbitMQ→parse→flock→Sigma). `god: _parse_event`
- [[risk-engine]] — score 0–100 aditivo + MITRE. `god: calculate_risk (67)`
- [[sigma-eval]] — evaluación Sigma inline, AST sin `eval`. `god: _safe_eval_condition`
- [[reporting]] — reporte de engagement (VRA, 100% forense). `god: _generate_engagement_report_impl`
- [[sensores]] — registro, bootstrap, binding a flock (Fase 5). `god: HmacVerifier (50)`
- Todas `commit_ref: 0085c31` salvo donde se indique.

## Releases

*(vacío — v0.6.2 documentada vía ADRs 0002–0006; falta página de release formal)*

---

## Fuentes sin ingerir

| Fuente | Ruta | Estado |
|---|---|---|
| Vault legacy — 4 Decisions | `.raw/vault-legacy/…/Decisions/` | **ingerido** → ADRs 0007–0010 |
| Vault legacy — Components (Consumer, InfraMap, Risk Engine, ws_manager) | `.raw/vault-legacy/…/Components/` | **pendiente** — candidatos a [[modulos]] (los god-nodes del grafo mandan el orden) |
| Vault legacy — NeuralGraph + "Fase 4 Neural Graph" | idem | **obsoleto** — `graph.js` retirado (ver [[0010-websocket-real-time]]) |
| Vault legacy — Runbooks, Glossary, Sprints, canvas | idem | **no se importa** — how-to/estado, no "por qué"; vive en el repo |
| `CHANGELOG.md`, `Docs/*`, `Fixes/`, `Plan_despliegue/` | `.raw/repo`, `.raw/docs` | **pendiente** |

> Historial de git v0.5.0→v0.6.2 (`6f584b7`..`0085c31`): **ingerido** — ver ADRs 0002–0006 y [[roadmap]].
