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

## [2026-08-07] bitacora | Tier E arranque: enrolamiento, notificaciones, dashboard (ref. Thinkst)
- Origen: evaluación de **Thinkst Canary** (POC en `~/Documents/Thinks Canary`) como plataforma de
  referencia. Matriz de gap TARTARUS vs Canary + reestructura del Tier E (E-A…E-G) en `.agents/ROADMAP.md`.
- **E-A enrolamiento** (`fcea76c`): `POST /flocks/{id}/enroll` (token single-use en Redis) +
  `POST /sensors/enroll` (auto-bind del `flock_id`) + re-home de sensores al borrar flock (lección POC:
  borrar un Flock desemparejó el hardware). E2E: token→auto-bind→re-home. `scripts/sensor-enroll.sh`.
- **E-E notificaciones** (`ae28dd7`): estaban rotas (todo off por defecto, config solo-RAM). Tabla
  `notify_config` (JSONB) + `persist()`/`load_persisted()` al boot + UI de credenciales email/WhatsApp +
  test-con-body + errores a `logger.error`. E2E: config sobrevive reinicio.
- **E-F dashboard** (`446ed87`, [[0011-dashboard-alerts-centric]]): navegación por vistas
  (Principal/Análisis/⚙Gestión) — de 27 secciones/3 mapas a un núcleo triage. `graph.js` borrado.
  Variante Balanceada; Mínima documentada como alternativa.
- **E-F2 Gestión/Análisis honestos** (`378a07c`): Threat Intelligence agrupa Internos vs Externos y la
  IP interna (RFC1918) dice explícito "sin inteligencia externa" (antes tarjeta vacía); **Infra Map
  eliminado** (redundante con Remote Sensors + Attack Map); Attack Origin Map ya no se atasca en
  "Cargando…"; Audit Trail con etiquetas legibles (auth/flocks/sensores + rutas `{id}`).
- **Regla de oro registrada (usuario):** todo lo que incorporemos debe priorizar **intuición + facilidad
  de uso**; referencia Thinkst = una alerta se resuelve en 5-8 campos, cero relleno.
- Suite 864 verde. Rama `feature/tier0-deployment-readiness` (5 commits code + wiki), sin push aún.
- Pendiente Tier E: E-F2.5 alert-UX (Related Incidents/Ignore-IP), **E-B OT (Modbus+portscan)**, E-C
  cebos rotos (planter no beacona), E-D export a XSIAM, modos VM/OVA·Tailscale (nube al final).
— claude

## [2026-08-07] bitacora | Tier E cont.: OT (Modbus+portscan), cebos, API SOC → PR #12
- Continuación de la sesión larga. Rama `feature/tier0-deployment-readiness` **pusheada, PR #12 → main**
  (11 commits, suite 882 verde).
- **E-F2.5** (`7511b41`): "Ignorar IP" real — el notifier consume el set `ignored_ips` (antes no-op).
- **E-B OT** (`95d7d1d`,`7461491`): honeypot **Modbus/TCP** señuelo (`sensors/modbus_canary/`, parser
  puro + servidor asyncio, scoring ICS: read=Discovery/T0846, **write=Impact/T0836 crítico**) +
  **portscan detection first-class** (`portscan_detector.py`, ventana Redis de puertos distintos por IP,
  dispara "Host Port Scan"/T1046 una vez por ventana; enganchado en consumer + `/ingest/sensor`).
  Candidatos a página [[modulos]]: `modbus_canary`, `portscan_detector`.
- **E-C cebos** (`083a4aa`): el planter doc/pdf ahora **beacona** (reusa `canary_docgen` → docx/pdf real
  con web-bug; deploy_router pasa `token_value` único); creds aws/slack **únicas + `register_decoy`**
  (antes: llave-ejemplo famosa inerte); breadcrumbs FTP/RDP/SMB reconciliados con OpenCanary
  (`ACTIVE_HONEYPOT_PROTOCOLS`). Pendiente **E-C.4**: file-share SMB con árbol tokenizado.
- **E-D1 API SOC** (`c06f63b`): decisión = **token de menor privilegio** para consumo por máquinas, no
  el JWT de consola ni la llave-plana. Ver [[0012-api-soc-menor-privilegio]]. `soc_auth.py` (tokens
  hasheados, read-only, flock-scoped) + `soc_router.py` (`/api/v1/soc/{incidents,devices,detections}`,
  rate-limited; `/soc/tokens` admin). engine internal-only (bind 127.0.0.1). Runbook en [[deploy-checklist]].
  **E-D2 (el feed real al SIEM) queda para decidir: pull vs push.**
- **OPSEC:** `190ff39` neutralizó el nombre del SIEM del cliente en 2 docstrings. 2 mensajes de commit lo
  conservan (aceptado por el usuario — el cliente ya estaba público en el repo; `filter-branch` bloqueado
  en el entorno). "Thinkst"/"IQSEC" ya eran públicos en 22/25 archivos de `main` desde antes.
- **Hallazgo (readiness):** la auth de la API está **OFF por defecto** (`TARTARUS_SESSION_AUTH=false`);
  para prod hay que activarla + cert TLS real (`certs/` está vacío) + hostname. Documentado en el runbook.
- Pendiente Tier E: E-C.4 (SMB), E-D2 (feed SIEM), TE-B3/B4 (LDAP/VNC/realismo/AD), TE-G (VM/OVA·Tailscale).
— claude

## [2026-08-07] refactor | Wikis narrativas + brief de cowork + Tier F (para la asesora)
- Motivo: enriquecer la wiki a alto nivel/narrativa para lectura de dirección (dsantamaria, asesora con
  lectura del repo privado). La `sintesis.md` estaba desfasada (jul-30) — su "tensión central" (#10,
  aislamiento sin probar, detección inflada) **ya se resolvió** en el Tier 0.
- Páginas: **[[sintesis]]** reescrita al presente (PR #12) · **[[estado-y-rumbo]]** (nueva: qué tenemos /
  qué mejoramos / próximas acciones con estimados S/M/L) · **[[brief-cowork]]** (nueva: onboarding
  completo — arquitectura, constraints C1-C5, OPSEC, cómo trabajamos, qué estudiar) · **[[roadmap]]**
  actualizada (Tier 0 ✅, Tier E en curso, Tier F). index.md enlaza las nuevas.
- Roadmap de código: **Tier F** (13 brechas) añadido a `.agents/ROADMAP.md` con causa raíz + estimados.
  #1 (aislamiento) es P0: el backend SÍ aísla; la "fuga" visible era un guard cosmético del front, pero
  hay 2 vistas sin filtrar (kill-chain/correlación) y falta el clamp datos por usuario→flock (MSSP real).
- Próximo: quick-wins de UI (memo con Enter, color de sensores, estados vacíos) + validación #9 (cebos
  + alertas email/Telegram/SMS, requiere credenciales) + seguridad de la llave del honeypot.
— claude

## [2026-08-08] modulo | Cebos: qué dispara alerta y cuándo (fire-on-open amarrado)
Nueva página [[canary-tokens]] con la realidad honesta por tipo de cebo (3 familias: 🔗 web/DNS al
accederse, 📄 documento al abrirse viewer-dependiente, 🔑 credencial al usarse). El *por qué*: la
pregunta recurrente "dejé un archivo y no me llegó alerta" casi nunca es bug — es confundir familias.
Ancla `fa60f1f`. En el repo: `docs/CEBOS_QUE_DISPARAN.md` (tabla operativa) + `docs/CANARY_ALCANZABILIDAD.md`.
Contexto de código (repo): se arregló la brecha #1 (nginx no enrutaba `/canary/` → el beacon caía en la
SPA; `329e9f1`), docx ahora lleva doble vector (imagen + plantilla remota, paridad Thinkst), base URL
alcanzable documentada, y verificación viva E2E (`scripts/verify_canary_open.py`, PASS localhost y LAN+nginx).
Pendiente agendado: HTTPS/TLS del callback por escenario (P1, no bloqueante; autofirmado ROMPE el beacon
→ solo cert de confianza; Cloudflare Tunnel para off-site).
— claude

## [2026-08-08] modulo | Consola de Canarios usable (crear≠desplegar) + rate-limit por token
Rediseño accionable de la consola tras feedback de UX (repo `c1310cf`). La UX previa confundía:
"+ Add Token" para docs no generaba archivo, menú de despliegue duplicado, "Memo" opaco, flujos por
`prompt()`, etiquetas en inglés. Ahora: panel unificado que **genera y descarga el archivo real** (o
la URL para web); crear ≠ desplegar (método = trazabilidad en la tarjeta); modales con checklist para
"Enviar al cliente"/"Bundle"; endpoint nuevo `POST /canary-tokens/credential`; y **rate-limit de
alertas por TOKEN** para canarios (antes por IP suprimía pruebas locales, que salen todas con la IP
del gateway Docker). Guía how-to: `.raw/repo/docs/GUIA_CONSOLA_CANARIOS.md`. Actualizada [[canary-tokens]].
No era bug: el web token disparaba (evento confirmado) pero lo tapaba el rate-limit por IP; el correo
al cliente se enviaba pero el ZIP caía en spam corporativo.
— claude
