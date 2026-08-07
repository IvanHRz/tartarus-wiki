# Log — Wiki Tartarus

Bitácora de actualizaciones. Append-only.
`grep "^## \[" log.md | tail -5`

## [2026-07-09] bootstrap | Wiki inicializada
- Estructura creada: raw/repo (symlink a ~/Documents/Tartarus), wiki/{adr,postmortems,modulos,releases}
- Schema: CLAUDE.md
- Historial de git sin ingerir

## [2026-07-10] ingest | Docs/adr/ADR-001 — Arquitectura de sensores
- Fuente: `raw/docs/adr/ADR-001-sensor-architecture.md` (459 líneas, 2026-05-06)
- Verificado contra: `6f584b7`
- Páginas nuevas (2): wiki/adr/0001-arquitectura-de-sensores.md, wiki/modulos/sensores.md
- Actualizadas: index.md, wiki/roadmap.md, wiki/backlog.md, wiki/sintesis.md
- NO se duplicó la ADR original — se referencia por ruta.
- **Hallazgo:** el audit §2 de la ADR omite dos consumidores de `remote_sensors`: `docs/generate_report.py:553` y `engine/tests/test_active_sensors_widget.py`. El `DROP TABLE` prescrito rompería la generación de reportes.
- **Hallazgo:** ADR sigue en PROPOSED tras 2 meses; 0 de 8 cambios prescritos existen en HEAD. Correcto por diseño (la ADR prohíbe implementar antes de validar), pero la validación tampoco ocurrió.
- Numeración ADR establecida: la siguiente es 0002.
— claude

## [2026-07-30] refactor | Rescate del vault legacy (marzo, v0.5.0)
- Origen: Tartarus/vault/ (bóveda local dentro del repo, congelada 2026-03-14, contaminada con Chronos-DFIR)
- 23 notas TARTARUS movidas a raw/vault-legacy/ (fuente cruda, pendiente de ingest)
- Chronos-DFIR (18 notas) reubicadas a wiki-chronos/raw/vault-legacy/
- vault/ eliminado del repo Tartarus (era local, no versionado)
- Pendiente: ingerir raw/vault-legacy/ — destilar ADRs/runbooks vigentes al schema, descartar lo que el código ya contradice (documenta v0.5.0, HEAD va por v0.6.2)
— claude

## [2026-07-30] bitacora | mssp: flocks, rbac, acknowledge, attack-map, dos niveles
- Commits: `6f584b7`..`0085c31` (24) — v0.5.0→v0.6.2; todo mergeado en #8, pin Beelzebub v3.8.0 en #9
- ADRs nuevas (5): [[0002-multi-tenancy-flocks]], [[0003-rbac-tres-roles]], [[0004-acknowledge-limpieza-de-ruido]], [[0005-attack-map-contexto-de-despliegue]], [[0006-consola-dos-niveles]]
- Actualizadas: index.md, wiki/sintesis.md, wiki/roadmap.md (sección "Hecho MSSP" + issues #10/#11)
- Hilo conceptual: la decisión `NULL=Default` (flock_id) atraviesa 0002 y 0006 — su costo es que el Default no tiene workspace propio.
- **Hallazgo (issue `#10`, crítico):** ingesta muerta — el canal AMQP de Beelzebub se cae por inactividad; los honeypots capturan pero no reportan y el dashboard muestra 0. Bloqueante de despliegue. Candidato a postmortem cuando se arregle.
- **Hallazgo (issue `#11`):** `events.honeypot_id` siempre NULL (consumer lee `HandlerName`, Beelzebub emite `Handler` vacío) → el attack-map mapea por protocolo, no por sensor real.
- Numeración ADR: la siguiente es 0007.
- Pendiente: destilar `raw/vault-legacy/` (operación `ingest` aparte).
— claude

## [2026-07-30] ingest | vault-legacy — 4 decisiones fundacionales (v0.5.0)
- Fuente: `raw/vault-legacy/Knowledge Base/Decisions/` (marzo 2026). Verificado contra `0085c31`.
- ADRs nuevas (4): [[0007-canvas-puro-sin-frameworks]], [[0008-rabbitmq-event-bus]], [[0009-risk-scoring-aditivo]], [[0010-websocket-real-time]]. **No se copiaron** — se destilaron y se verificaron contra HEAD.
- **Hallazgo (0008):** la ADR original promete "events never lost". Falso: cola `durable=False` (`consumer.py:444`) **y** el canal se cae (issue `#10`). La promesa del bus es mito.
- **Hallazgo (0010):** `/ws/events` + `ws_manager` siguen vivos (`main.py:286`) pero **huérfanos** — el Neural Graph que los justificaba está retirado y la UI volvió al master-poll. Candidato de `lint`.
- **Obsoleto:** NeuralGraph + "Fase 4 Neural Graph" (graph.js dead-code, `index.html:227`).
- **No importado:** runbooks, glossary, sprints, canvas — son how-to/estado, no "por qué"; viven en el repo.
- Pendiente: Components legacy (Consumer, InfraMap, Risk Engine, ws_manager) → páginas de [[modulos]] cuando corra el grafo (los god-nodes mandan el orden).
- Numeración ADR: la siguiente es 0011.
— claude

## [2026-08-06] refactor | Grafo reconstruido contra `0085c31`
- Tooling: `graphifyy 0.9.34` instalado aislado con pipx (`~/.local/bin`, no global). `graph_rebuild.sh` local, sin LLM.
- Grafo: 4236 nodos, 7177 edges, 276 comunidades. Solo `GRAPH_REPORT.md` versionado (graph.json en .gitignore).
- God-nodes (candidatos a [[modulos]]): `calculate_risk()` (67), `_parse_event()` (30), `_safe_eval_condition()` (28), `_generate_engagement_report_impl()` (30), `HmacVerifier` (50). → Risk Engine, Consumer, Sigma-eval, Reporting, Sensores.
- **Hallazgo:** `NeuralGraph` es god-node #4 (39 edges) pero está **retirado** — `graph.js` sigue en el repo como dead-code, estructuralmente central pero muerto. Confirma [[0010-websocket-real-time]]; candidato de `lint`: borrar `graph.js`.
- Pendiente: escribir las páginas de módulo (operación aparte, la mandan los god-nodes).
— claude

## [2026-08-06] ingest | módulos desde los god-nodes del grafo
- Páginas nuevas (4): [[consumer]], [[risk-engine]], [[sigma-eval]], [[reporting]]. Actualizada: [[sensores]] (commit_ref 6f584b7→0085c31, + binding flock_id Fase 5).
- Regla: responsabilidad/invariantes/trampas, NO listado de funciones (eso lo da el grafo).
- **Trampa capturada (consumer):** cola `durable=False` (`#10`/[[0008-rabbitmq-event-bus]]) + `honeypot_id`=HandlerName vacío (`#11`) + re-clasificación de protocolo por puerto.
- **Invariante de seguridad (sigma-eval):** condición Sigma se parsea a AST con whitelist, nunca `eval` (BUG-015). Y el hallazgo "89 de 424 reglas aplican" queda anclado aquí.
- **Trampa (reporting):** `_generate_engagement_report_impl` + `generate_report.py:553` leen `remote_sensors` (tabla muerta) — el `DROP` de [[0001-arquitectura-de-sensores]] rompería reportes.
- Pendiente: `lint` — borrar `graph.js` (dead-code, god-node #4); postmortem de `#10` al arreglarse.
— claude

## [2026-08-06] refactor | raw/ y graph/ → dotfolders (.raw/.graph)
- Motivo: Obsidian seguía el symlink `raw/repo` e indexaba TODO el repo como notas (205 notas visibles, grafo ilegible). Su "excluded files" solo atenúa, no oculta. Los dotfolders sí se ocultan.
- `git mv raw .raw` + `git mv graph .graph`. Ahora Obsidian solo ve: wiki/, index.md, log.md, Templates/, AGENTS.md (20 notas).
- Refs actualizadas a `.raw/`/`.graph/` en: tools/*.sh (funcional), .gitignore, AGENTS.md (el schema), index.md, sintesis.md, adr_original de 0001/0007-0010. Entradas históricas de este log se dejan como estaban (append-only).
- Smoke-test OK: `git_digest.sh` y `stale_modules.sh` resuelven `.raw/repo`.
- Nota zsh: el word-splitting no aplica a `$VAR` sin comillas — `for f in $FILES` iteraba una sola vez. Usar lista explícita o `${=FILES}`.
— claude

## [2026-08-07] refactor | Tier 0 saneamiento: loop de evaluación + gate verde 11/11
- Origen: auditoría del *proceso de trabajo* + exploración del despliegue de campo. 11 hallazgos (T0-1..T0-11) → puerta de calidad antes de retomar features (decisión del usuario: "todo el backlog").
- **Motor del loop:** `scripts/audit_gate.sh` (criterio de "sano" por hallazgo, exit 0 = todo verde). Reemplaza a `verify_features.sh` (v0.5). Verificado **11 OK / 0 FAIL / 0 SKIP** con el stack arriba.
- **Críticos sanados y E2E-verificados:**
  - `#10` ingesta ciega → `engine/ingestion_health.py` + `consumer:last_event_ts` + `/health.checks.ingestion` (ok/stale/idle) + reconexión AMQP por inactividad. Tras ingerir, `/health` → `ingestion=ok`. Ver [[2026-08-07-ingesta-amqp-ciega]].
  - Telemetría de campo rota → `POST /ingest/sensor` (HMAC, flock-aware, `sensor_id`→`honeypot_id` mitiga `#11`). E2E: evento de campo aterrizó en `events` con risk 80. `push-to-rpi.sh`/composes corregidos (apuntaban a `/events/webhook` inexistente).
- **Otros:** test de integración de aislamiento de flocks (`_windowed_where` real vs Postgres); `/detections/rules` ahora distingue **cargadas (427) vs aplicables a honeypot (117)**; skills `tartarus-*` consolidadas a una ubicación + banner v0.6.x; `scripts/reset_clean.sh` (clean-slate); git-maintenance off en la wiki.
- **Roadmap:** Tier 0 (gate) + Tier E (despliegue self-service) añadidos a `.agents/ROADMAP.md`.
- Pendiente: fix real del `#11` en el path AMQP; build del Tier E (enrollment + auto-bind); verificación E2E de la reconexión por inactividad bajo canal muerto.
— claude
