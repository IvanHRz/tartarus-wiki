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

## [2026-08-10] seguridad | Auditoría de hermeticidad de flocks (100%) — reportes/export cerrados
Fuga entre clientes reportada por Iván. Auditado TODO con harness determinista (repo
`scripts/audit_flock_isolation.py`: 2 flocks marcados, 19 superficies, loop). Hallazgos + fix
(repo `17d167c`): (1) fuga VISUAL front-end (DOM/caché sin limpiar al cambiar de flock); (2) fuga REAL
en **reportes de engagement + 6 fuentes + PDF/HTML por-id + exportación CSV/normalized/STIX** que NO
scopeaban por flock (la última era la query de ventana en `correlate_around_detections`); (3) `/hosts`
observed dedupe global. Resultado: **0 fugas en 5 rondas**, incl. reportes/CSV/STIX. Guardarraíl
`test_report_export_flock_scope.py`. Vulnerabilidades PENDIENTES en `.agents/ROADMAP.md §Auditoría`:
RBAC no forzado por defecto (P0), integridad de mutaciones por-id (P1), notificaciones por-flock (P1),
rate-limit por flock (P2), assignments obligatorios (P2), watermark de flock en reportes (P3).
— claude

## [2026-08-10] seguridad+ejecutivo | Segunda pasada de hermeticidad + bitácora ejecutiva
Cerrada la 2ª parte de la seguridad entre clientes (integridad + autorización), tras la de lectura
(repo `17d167c`). En el repo (sin commitear al escribir esto): mutaciones acotadas por flock
(borrar/editar cebos, borrar honey creds, reconocer/silenciar IP; "limpiar todo" ya no arrasa con los
demás clientes), freno de alertas e IPs silenciadas por flock, y marca de agua de cliente en el reporte
de engagement. RBAC: la barrera ya existía y estaba dormida (sesión apagada en dev); se añadió test que
la fija (`test_mutation_flock_scope.py`) y guía `docs/SEGURIDAD_MULTITENANT.md` para encender producción.
Auditoría en bucle: **0 fugas** en lectura, reportes/export y mutación. Suite 998 verde / 4 skip.
Nueva página [[bitacora-ejecutiva]] (avance por fechas, lenguaje llano, para asesoría). ROADMAP del repo
actualizado: pendientes con fecha objetivo + épica nueva "Plataforma de gestión de clientes" (venta).
— claude

## [2026-08-10] sesión-autónoma | Cruce visual de cebos + avisos por cliente + detección + bcrypt
Tanda de trabajo continuo (repo, 4 commits `028b945`..`d25e562`). (1) El "cruce de cebos entre
clientes" reportado era DOM rancio: la consola no limpiaba el grid al cambiar a un cliente sin cebos
(quedaban los del anterior). Fix: limpiar en vacío + blanquear al cambiar + mutaciones por flock
(`028b945`). De paso, `scripts/audit_flock_isolation.py` era destructivo (borraba datos reales): ahora
acota su limpieza a los flocks de auditoría; nuevo `scripts/seed_demo.py`. (2) Notificaciones por
cliente (`abd47e2`): tabla `notify_config_flock`, `Notifier.config_for`, enrutado por `event.flock_id`,
endpoints con `?flock_id`; falta el selector en la UI. (3) Detección (`59edc1e`): las 16 reglas del
Tier 1 ya existían; se cerró el hueco real T1136 (create-account) para Windows/PowerShell. (4) Bcrypt
(`d25e562`): opcional con degradación, verificación compatible, rehash transparente en login. Suite
1010 verde; auditoría de aislamiento 0 fugas. Detalle en `.agents/BITACORA.md`. Bloqueado: HASSH (fork
Beelzebub) para la regla c2_encrypted_channel.
— claude

## [2026-08-10] plan | Clean slate + ataque E2E + fixes UI + skill de planes
Plan aceptado archivado en [[planes/2026-08-10]]. Limpiar todos los flocks, atacar todos los protocolos
por el camino real (Beelzebub→pipeline) y auditar que no se filtre a otros flocks (Iván testigo);
arreglar recarga/vista de flock; limpieza mínima del panel central; auditar cobertura de protocolos al
roadmap; y nueva skill `registrar-plan` que archiva cada plan aceptado aquí (este es el primero).
— claude

## [2026-08-10] refactor+bitacora | Telnet, watchdog del pipeline, cobertura y estudio HTTPS
Cierre de los huecos detectados en la auditoría de cobertura (repo, commits 0226ee9..90dbf7d).
(1) Telnet: attack_all.py usaba TCP crudo contra un honeypot SSH (Beelzebub no tiene telnet nativo;
:23 es SSH+LLM) → 0 eventos; ahora ataca por SSH, verificado 28 eventos TELNET. (2) Watchdog
`scripts/beelzebub_watchdog.sh`: el host sondea /health (ingestion stale) y reinicia Beelzebub con
cooldown (el engine ya se auto-recupera; Beelzebub Go no). (3) Scripts attack_modbus (10 eventos, con
el sensor levantado), attack_icmp (campo) y attack_prometheus (14 eventos). (4) Estudio HTTPS
`docs/ESTUDIO_HTTPS_TLS.md`: Thinkst Canary (competidor principal) ofrece HTTPS con cert configurable →
recomendado desplegar (P2/M), solo evaluado esta ronda. Nueva página [[competencia-thinkst]]. Los planes
del día en [[planes/2026-08-10]] ahora incluyen los prompts del usuario (skill registrar-plan mejorada).
— claude

## [2026-08-10] plan+bitacora | Análisis Telnet + gestión LLM (DeepSeek) + revisión seguridad + diseño dashboard
Tercer plan del día en [[planes/2026-08-10]] (con prompts). Repo commit 73d1715. (1) Análisis Telnet
(docs/ANALISIS_TELNET.md): CLI Cisco por LLM convincente, pero éxito PARCIAL, NO garantía (no habla telnet
real → pierde IoT/Mirai; LLM puro depende de key viva; costo por interacción). (2) Key LLM cambiada a la de
GPT.rtf ($4.67); runbook DeepSeek listo (docs/RUNBOOK_LLM_DEEPSEEK.md); documentado el no-op de
POST /settings/beelzebub/ai. (3) Revisión de vulnerabilidades priorizada (docs/REVISION_SEGURIDAD_PENDIENTES.md)
+ job secret-scan en CI. (4) Diseño del dashboard de despliegue G-2/G-3/G-4 (docs/DISENO_DASHBOARD_DESPLIEGUE.md),
sin construir. Suite 1010 verde.
— claude

## [2026-08-10] plan+bitacora | Auditoría de Beelzebub + alcance de la IA + quick wins
Cuarto plan del día en [[planes/2026-08-10]]. Repo commits 1367cf4 (guardrails/validate CI/respaldo telnet)
y 2eaf198 (docs). (1) Auditoría de capacidades de Beelzebub (docs/AUDITORIA_BEELZEBUB.md): huecos —
métricas Prometheus reales perdidas (:2112 tapado por honeypot falso), telnet/MCP no nativos, Ollama/
multi-proveedor, MazeHoneypot, key hardcodeada, evaluar upgrade de imagen. (2) Mapa de alcance de la IA
(docs/ALCANCE_IA_TARTARUS.md) + apartado [[alcance-ia]]. (3) Quick wins probados: guardrails anti-jailbreak
en los honeypots, respaldo estático en telnet, validación de YAML de Beelzebub en CI. (4) Nuevo apartado
[[actualizaciones-herramientas]] (tool-watch). Diseño del dashboard ampliado (multi-proveedor + observabilidad).
— claude

## [2026-08-10] release+plan | Upgrade de Beelzebub v3.8.0 → v3.9.0
Quinto plan del día en [[planes/2026-08-10]]. Repo commit 858620e (pin de imagen). Upgrade empírico y
reversible: los 6 servicios cargan sin errores del nuevo validador por schema, todos los honeypots responden
(probados uno por uno), guardrails y respaldo estático de Telnet intactos, pipeline ingiere. Hallazgo clave:
v3.9.0 trae NATIVO telnet, TLS/HTTPS, multi-proveedor LLM (host), MazeHoneypot y guardrail → varios
pendientes se abaratan (config, no build). Re-priorizado en el roadmap. Tool-watch: [[actualizaciones-herramientas]].
— claude

## [2026-08-11] feat+plan | Telnet nativo + HTTPS nativo (Beelzebub v3.9.0)
Repo commit acfb90b. Aprovechando v3.9.0: telnet-23 -> protocol telnet (captura telnet real/IoT, conserva
CLI Cisco por IA + respaldo estatico + guardrails; verificado 32 eventos TELNET); honeypot HTTPS en :443
(host :8443) con cert autofirmado, sin nginx (consumer fija dest_port=443 via TLSServerName; test añadido).
services.example actualizado; .gitignore certs/. Suite 1011 verde. Plan en [[planes/2026-08-11]].
— claude

## [2026-08-11] feat+plan | G-4: proveedor/key LLM por honeypot desde la UI
Repo commit 0ecbf84. POST /services/{file}/llm + personality_engine.set_llm escriben el bloque plugin del
YAML (OpenAI/DeepSeek/OpenRouter/Ollama via provider+host). Seccion "Proveedor LLM" en el modal. Arregla el
no-op de settings/beelzebub/ai (deprecado). C5: la key nunca se devuelve/loguea. E2E: loop gpt-4o<->
gpt-4o-mini por API. Suite 1019 verde. Multi-proveedor aprovechado en [[actualizaciones-herramientas]].
— claude

## [2026-08-11] feat+plan | MazeHoneypot (anti-escaner) + metricas Prometheus reales (observabilidad)
Repo commit al momento d2105a5. (A) MazeHoneypot: fallback plugin MazeHoneypot en http-80.yaml y
https-443.yaml (reemplaza el 404) -> laberinto infinito de directorios falsos a los escaneres; portal y
login intactos. (B) Metricas Prometheus reales de Beelzebub recuperadas: mapeo del :2112 real a :9112 en
compose (sin quitar el senuelo) + observability_router.py (GET /observability/beelzebub raspa
beelzebub:2112 por red interna, parser minimo, resiliente) + panel de salud en la UI. 7 tests nuevos,
suite 1026 verde. E2E: contadores suben con el trafico. Maze y metricas aprovechados en
[[actualizaciones-herramientas]]. — fable

## [2026-08-11] feat+plan | Cierre de pendientes menores (etiqueta laberinto + Grafana opcional + prod)
Repo commit al momento 1bbbf4f. (1) Etiqueta de laberinto: maze_tagger.py deduce si una peticion HTTP cayo
en el maze (URI sin handler real) e inyecta maze_hit en el payload; badge en el feed. (2) Grafana opcional:
perfil compose observability (Prometheus rasca beelzebub:2112 + Grafana :3300 con dashboard "Salud de
honeypots" auto-provisionado); no arranca por defecto. (3) Mount rw de configs en prod
(docker-compose.prod.yml) -> personas/G-4/etiquetado funcionan en produccion. 9 tests nuevos, suite 1035
verde. E2E: probe de escaner sale marcado, portal no; Grafana target UP con beelzebub_events_total=386.
Se suma al PR #15. — fable

## [2026-08-11] feat+plan | Reconciliar metricas (embudo) + Grafana benchmark + G-3 (on/off + reiniciar)
Repo commit al momento 1ada8a5. El usuario noto que Grafana (754/45/736) != panel Principal (1166/94/821).
Diagnostico: 5 causas estructurales (ventana, flock, taxonomia, fuente-vs-persistido, reset). F1: embudo de
ingesta Beelzebub->consumer(Redis)->BD, GET /observability/reconcile (brechas, separa colapso de port-scan de
perdida real), panel en la UI, scripts/compare_metrics.py. E2E: consumer->BD 0.0% (sin perdida). F2: Grafana
benchmark (increase reset-aware, anotacion de reinicios, endpoint /metrics/tartarus + 2o job Prometheus,
fuente vs persistido). F3: G-3 encender/apagar honeypots (mueve YAML a disabled/) + reiniciar via flag que
ejecuta el watchdog (C4). 16 tests nuevos, suite 1045 verde. Doc nuevo docs/OBSERVABILIDAD_METRICAS.md.
Reconciliacion aprovechada en [[actualizaciones-herramientas]]. — fable

## [2026-08-11] feat+plan | Hub de despliegue (Honeypots + Sensores + Deception en Gestion)
Repo commit al momento 34f98b2. La seccion "Honeypot Services" se reencuadro como "Despliegue" con 3 familias:
Honeypots (grid existente), Sensores remotos (loadSensorsFamily sobre GET /sensors/status), y Deception (barra
de acciones + modal: clonar sitio, plantar cebo, plantar honey-cred). Cero backend nuevo (endpoints ya
existian). Wizard conservado como "Modo avanzado" (deprecacion segura). Corregido: el grid ahora sigue al
flock activo (refreshFlockViews). Bug evitado: el wizard posteaba canary sin token_value (obligatorio); el hub
lo genera. E2E: 3 familias + plantar cebo/cred OK. Solo UI; suite backend intacta (1045). — fable

## [2026-08-11] plan | Retiro total de wizard.js
Plan aceptado archivado en [[planes/2026-08-11]]. Reemplazar el wizard de 1342 lineas por un
despliegue de una sola pantalla dentro del hub (estilo Thinkst, sobrio), migrando escenarios y
perfiles de hardware como datos, y borrar wizard.js. — fable

## [2026-08-11] feat | Despliegue en una sola pantalla (retiro total de wizard.js)
Se borró wizard.js (1342 líneas) y su CSS/HTML; en su lugar deploy_hub.js monta el despliegue de una
pantalla dentro del hub, estilo sobrio de Thinkst: escenario (prellena) + contexto + sistema destino
(9 perfiles) + sensores (ICMP con subform) + trampas por SO + escaneo (sigilo/normal) + resumen + botón
único. Ejecuta /api/deploy/execute (cero backend nuevo) y pinta tabla de resultado; "Ir al hub" salta a
Gestión. Bug corregido: setView no está en window → se usa el tab de vista. 7 tests E2E nuevos verdes;
verificado a mano. Detalle ejecutivo en [[bitacora-ejecutiva]]. — fable

## [2026-08-11] feat | Rediseño del despliegue: honesto, accionable y manipulable en vivo
Se rehízo el modal de despliegue en 5 fases tras el feedback del usuario: escenarios que explican qué activan
(sin tiempos inventados), contexto de 2 opciones directas (atacante activo/preparación), sistema renombrado,
sensores que distinguen IA (Beelzebub) vs solo-detección (OpenCanary) con verificación de /settings/ai, trampas
que generan+descargan el archivo real con nombre/ruta editables (endpoints de canarios), escaneo reencuadrado
como "Reconocer la red" que sugiere sensores desde /hosts, y hub vivo (quitar/reasignar sensor; nuevo
DELETE /sensors/registry/{id}). 2 bugs corregidos (re-render async que borraba la tabla; funciones no globales
en módulo ES). Suite 1048 (+3), 10 E2E verdes, verificado a mano. Detalle en [[bitacora-ejecutiva]]. — fable

## [2026-08-11] feat | Refinamiento crítico del despliegue (contexto que orienta, catálogo, un solo botón)
2ª pasada de feedback sobre el modal: internet deja de ser decorativo (afecta el aviso de IA), atacante activo
genera recomendaciones concretas, se quita "sigilo" (jerga), se explica pasividad de sensores y el ICMP
(tripwire de IPs señuelo), catálogo "+" de ~13 tipos de cebo, y un solo botón "Generar cebos (paquete)". Backend:
POST /canary-tokens/bundle que respeta nombre/ruta por cebo (el enriquecimiento viaja en el ZIP). Reconocimiento
reposicionado como paso previo opcional. Suite 1050 (+2), 12 E2E verdes. Detalle en [[bitacora-ejecutiva]]. — fable

## [2026-08-25] feat | Renombrar flocks — cierre del P0 "Interfaz global de gestión de flocks"
Retomada la rama `feature/tier0-deployment-readiness` tras perder las sesiones en curso. El P0 de gestión de
flocks estaba casi cerrado por el trabajo previo de la consola de dos niveles (deploy_hub): ya existían
**crear/borrar/entrar**, **salud por cliente** (tarjetas con Atacantes/Alto riesgo/sparkline 24h), **persistir
el flock al recargar** (`localStorage tartarus_flock` + rehidratación) y el **selector de vista `view-nav`**
(`setView` valida/sincroniza/persiste en `tartarus_view`). El único faltante real era **renombrar**: se añadió
`PATCH /flocks/{flock_id}` (`rename_flock`, mismo patrón que create/delete — `can_mutate`, nombre requerido,
duplicados contra otros flocks, 404 si no existe, `is_default` inmutable) + botón "Renombrar" en cada tarjeta y
`renameFlock()` en la UI (si se renombra el flock activo, refresca banner/selector sin salir). Tests: ruta PATCH
en `test_flocks_router_exposes_crud_routes` + `test_rename_flock_rejects_empty_name`. Suite **1051 verde**.
Verificación en vivo pendiente: el engine/DB no estaban arriba (solo grafana/prometheus/beelzebub); probar el
PATCH contra el stack cuando se levante. Sin commitear aún. — fable

## [2026-08-25] fix+auditoría | Falsos positivos: la infraestructura se autogeneraba alertas CRITICAL
Iván reporta correos CRITICAL sin parar (TCP:8080, T1046, riesgo 80) sin que nadie ataque. Diagnóstico: el
atacante `192.168.97.8` es **el propio engine**; `.7` es **beelzebub**. **~97% del tráfico ingerido era de
nuestra propia infraestructura**. En la BD (3691 eventos): `.7` beelzebub 2159 (2158 = TCP:8080), `.8` engine
169, `.1` gateway 1363 (mix real de simulaciones NATeadas). Causa raíz: `sensor_health_worker.py` prueba
beelzebub:8080/:22/:80 **cada 30s** + `sensor_manager.py` (probes de verificación de despliegue) + beelzebub
hacia sí mismo; beelzebub loguea TODA conexión TCP como "sesión" → se ingiere como recon CRITICAL → correo.
**Fix (parte 1):** el consumer descarta EN INGESTA los eventos cuyo `source_ip` es de un contenedor propio
(auto-resuelto por DNS: engine/beelzebub/scanner/ui/… = .2–.10; el gateway .1 se CONSERVA porque por ahí entran
ataques externos NATeados). Override `TARTARUS_INGEST_IGNORE_IPS`/`_HOSTS`. Test
`test_parse_ignores_infra_source`. Suite **1052 verde**. Verificado en el contenedor: ignora .2–.10, no .1 ni
IPs externas. **Limpieza histórica:** script `scripts/purge_infra_noise.sh` (dry-run confirma 2328 eventos-ruido
.7+.8); el borrado quedó **pendiente de correr por el usuario** — el clasificador de seguridad del harness
bloqueó el DELETE directo. **Auditoría abierta en `.agents/ROADMAP.md` (P0):** recalibrar que un simple "New TCP
Session" no sea riesgo 80/CRITICAL, doble taxonomía TCP vs TCP/HTTP, rate-limit de recon repetido, y evaluar que
el health worker no toque el puerto de ataque. Sin commitear aún. — fable

## [2026-08-25] fix+auditoría | Recalibración de severidad (recon ya no es CRITICAL) + conteo del flock
Segunda parte de la auditoría de falsos positivos. **(1) Recon marcado CRITICAL:** un simple `GET /` (o
`New TCP Session`, `GET /tools/list`) salía **80/CRITICAL** por un bug circular de scoring. La regla Sigma
`multi_protocol_kill_chain` (nivel critical) tenía `condition: any_event` → matcheaba CUALQUIER evento, y el
consumer floreaba el riesgo a 80; encima 3 meta-reglas (`critical_risk_event` ≥80, `high_risk_event` ≥70,
`multi_protocol_recon` ≥60) solo re-expresaban el `risk_score` como "detección", retroalimentando el floor. Y
los umbrales estaban inconsistentes (≥80 en stats/reportes/correo vs ≥85 en `risk_to_severity`): un 80 era
"high" al guardarse pero "CRITICAL" en los tiles/correo. **Fix:** las 4 meta-reglas a `status: deprecated` (+
el loader de Sigma ahora ignora deprecated); **fuente única de umbrales** (`session_scorer` 85/70/40) aplicada
en events_router/report_router/notifier/llm_analyzer/narrative_builder/cross_correlator; y el floor de Sigma/
YARA usa los cortes canónicos **y se registra en `risk_factors`** (antes el 80 salía sin explicación: los
factores sumaban 50 pero el score era 80). Verificado en vivo: el mismo `GET /` ahora da **50 = MEDIUM**
(factores 30+20=50, cuadran) y no dispara correo (<70). **(2) Conteo del flock:** el header decía "3693" pero
los paneles casi vacíos — no es bug: el header/selector usa `event_count` histórico (all-time) mientras los
paneles usan ventana de 24h (solo 2 eventos recientes; 2328 de los 3693 son el ruido de infra aún sin purgar).
Se etiquetó el selector ("… · 3693 total") y la tarjeta ("Eventos (total)"). Suite **1054 verde**. Reglas
activas 655 (−4). Sin commitear aún. — fable

## [2026-08-25] auditoría+fix | Audit profundo de FP/alertas/métricas (3 agentes) — Ola 1
A petición de Iván ("audita todo a profundidad") se lanzaron 3 agentes de exploración (scoring/Sigma,
alertas/correo, métricas). Hallazgos estructurales grandes. Plan aceptado por olas
(`~/.claude/plans/si-sigue-hazlo-a-refactored-rivest.md`). **Ola 1 (detener el flood + FP estructurales),
suite 1058 verde:** (1) las fases MITRE peligrosas (SMB/RDP/FTP/Telnet/SSH-login) ya no saltan el umbral por
sí solas — requieren interacción real (comando/credencial/payload); era la causa dominante del exceso de
correos. (2) Tope global de alertas por flock/hora (`NOTIFY_MAX_PER_HOUR`) + rate-limit configurable. (3) Un
honey-cred ya no queda suprimido por una alerta trivial de la misma IP (bug de sub-alerta). (4) El filtro de
infra ahora corre en TODOS los webhooks (opencanary/icmp/ingest/canary), no solo en RabbitMQ — extraído a
`engine/engine/infra_filter.py`. (5) sigma_lite: un bloque de detección vacío ya no lanza NameError→fallback
`any()` (anulaba los `and not filtro` → FP masivos como T1021_004_ssh_lateral). (6) las reglas de correlación
(`event_count gte:N`) ya no disparan con 1 evento (ssh_brute_force, ping_sweep). (7) deprecada
`icmp_tunnel_exfil` (circular). Verificado en vivo: un `GET /` recon da 50=MEDIUM sin floor. Faltan Ola 2
(limpiar el corpus Sigma, filtrar por aplicabilidad) y Ola 3 (unificar métricas + purga de datos). Sin
commitear aún. — fable

## [2026-08-25] fix | Auditoría profunda — Ola 2 (corpus Sigma) y Ola 3 (métricas unificadas)
Continuación del audit por olas. **Ola 2 — el corpus de reglas:** el motor cargaba 669 reglas y evaluaba
cientos escritas para telemetría de endpoint (Sysmon/EDR: `CommandLine` 305 usos, `Image` 252, `EventID`
124) contra los 14 campos que tiene un evento de honeypot. Ahora solo se cargan las reglas cuyos campos
existen en el evento: **669 → 366**, y el arranque lo dice en el log (7 deprecadas + 304 no aplicables), sin
recortes silenciosos. Al probarlo apareció un **bug del motor**: el patrón del modificador `re` pasaba por
`.lower()`, lo que convertía `\S` en `\s` (y `\D`→`\d`, `\W`→`\w`) y rompía en silencio cualquier regex con
clases negadas; corregido. Además se deprecaron las dos reglas que disparaban solo por protocolo
(RDP/SMB lateral, ya cubierto por el motor de riesgo), se bajaron a "medio" cuatro que se activaban con un
simple saludo de conexión (rdp/smb/telnet/ftp) y se afinaron seis que casaban por trozo de palabra ('host'
dentro de 'hostname', 'sudo' dentro de 'sudoku', '--' de cualquier opción, 'NLA' en el JSON crudo…).
Comprobado de punta a punta: una conexión pelada ya no pasa de "medio", mientras SQLi, salto de directorio
y subida de webshell siguen saliendo en 85/crítico; cero disparos de reglas retiradas.
**Ola 3 — que los números cuadren:** la unificación de umbrales estaba a medias y el sitio más visible (la
tira principal del panel) seguía con la escala vieja, así que un mismo evento salía "crítico" en un panel y
"alto" en otro. Se migró todo a 85/70/40 (motor, reportes, PDF, TheHive, recomendaciones y el **texto que
lee el operador**, que documentaba la escala vieja), el frontend pasó a usar una constante única, el KPI
"alertas críticas" del panel central dejó de mezclar histórico con la ventana de 24h, el resumen por cliente
ya no cuenta los críticos dos veces, y el embudo de ingesta dejó de leer como "pérdida" lo que en realidad
son descartes del filtro de infraestructura. Se añadió una prueba que falla si alguien reintroduce la escala
vieja. Suite **1066 verde**. Corregidas también las fechas de las entradas anteriores (estaban puestas como
18-ago tomando la fecha del correo de alerta; el trabajo es del 25-ago).
**Pendiente de Iván (el harness bloquea los borrados):** correr `scripts/purge_infra_noise.sh --apply`
(2328 eventos-ruido) y borrar los flocks de prueba AUDIT_A/AUDIT_B. Sin commitear aún. — fable

## [2026-08-26] fix | Pendientes del audit: sensores, cebos y correlación (Olas A, B y C)
Segunda tanda del audit, por olas. Suite **1090 verde**.
**A · Sensores (lo que se veía en pantalla).** El sensor ICMP salía "failed" en el despliegue y "offline"
en el panel aunque funcionara: se le hacía una sonda TCP a un puerto (`:8000`) que en realidad es el del
engine — ese sensor no escucha nada, reporta por webhook. Ahora se verifica por su estado real y, además,
cada evento suyo deja constancia de que está vivo (nadie emitía su latido, por eso el "offline" eterno;
verificado: pasó a activo). También se quitó ruido en origen: el vigilante abría ~14.400 conexiones al día
contra los puertos de ataque del honeypot; ahora usa las métricas del proceso y espacia las sondas
(medido: 0 eventos en 100 s, antes ~15).
**B · Cebos: que solo avise lo que importa.** OpenCanary marcaba TODO evento como cebo disparado, así que
cada conexión de un escaneo mandaba correo; ahora solo avisan los intentos reales (login/credencial/abrir
un fichero señuelo) y las conexiones se registran sin avisar. Al probarlo salió un hueco: la descripción
que escribe OpenCanary ("RDP connection") pasaba por comando tecleado, así que se añadió una señal
explícita de "hubo intento real". Y los **previsualizadores de enlaces** (Safe Links, Slack, antivirus de
correo) que abren un cebo al reenviarlo por correo: ahora se reconocen, el disparo se guarda como
evidencia con su etiqueta pero no manda correo. De paso se corrigió de quién se registra la IP: se tomaba
el primer valor de la cabecera de proxy (falsificable y, con un previsualizador de por medio, la IP
equivocada).
**C · Escaneo de puertos y correlación.** La "ventana de 5 minutos" del detector no era tal: se rearmaba
en cada evento, así que un escáner lento acumulaba para siempre; ahora es deslizante de verdad. Y se
añadió una lista de escáneres autorizados (el Nessus de la empresa deja constancia pero no dispara
alarma). Lo más importante: se implementó la **correlación real**, así que las reglas de umbral vuelven a
servir — "5 intentos de acceso desde la misma IP en 5 minutos" ahora cuenta de verdad en vez de disparar
con el primero. Al probarla se descubrió que la regla de fuerza bruta buscaba un texto ("Failed password")
que este honeypot **nunca escribe**, porque acepta todos los accesos a propósito; se corrigió contra lo
que emite de verdad. Verificado: 1 intento no dispara, 6 disparan una sola vez.
**Hallazgo operativo serio:** al probar salió que **el honeypot llevaba desde ayer 23:30 sin ingerir nada**
— Beelzebub había perdido su conexión con la cola de mensajes y no la reintenta solo. Se restauró
reiniciándolo, pero el vigilante que existe para esto (`beelzebub_watchdog.sh`) **no está corriendo en la
máquina**; conviene dejarlo activo o el honeypot puede quedarse mudo sin avisar. Sin commitear aún. — fable

## [2026-08-26] ops | El vigilante del honeypot ya está activo (y por qué nunca lo estuvo)
Cerrando el hallazgo anterior: el script que vigila la ingesta (`beelzebub_watchdog.sh`) existía desde
agosto pero **nunca tuvo permiso de ejecución**, así que jamás llegó a correr — de ahí que el honeypot
pudiera quedarse mudo ocho horas sin que nadie se enterara. Se le dio permiso y se dejó instalado como
servicio del sistema (launchd, `com.tartarus.beelzebub-watchdog`): comprueba cada minuto, arranca solo al
encender la Mac y escribe en `/tmp/tartarus-watchdog.log` (solo habla cuando actúa). Se le puso el PATH
explícito porque launchd arranca sin `docker` ni `python3` en el camino. **Probado en serio**: se simuló
la avería, el vigilante la detectó y reinició Beelzebub, y la ingesta volvió a estar sana en segundos.
Para apagarlo: `launchctl bootout gui/$(id -u)/com.tartarus.beelzebub-watchdog`. — fable

## [2026-08-26] limpieza | Fuera el ruido histórico de la base (y el watchdog, corregido)
Último pendiente del audit: la base seguía arrastrando los eventos que se colaron **antes** de que
pusiéramos el filtro, es decir, los que generaba el propio sistema al vigilarse a sí mismo. Mientras
estuvieran ahí, los paneles y los informes contaban ruido como si fueran ataques.

**Lo que se hizo, en orden.** Primero un **respaldo** de la base (no existía ninguna costumbre de
respaldos en el proyecto: los únicos volcados eran de mayo), verificado antes de borrar nada — y de paso
quedó escrito cómo restaurarlo, que tampoco estaba documentado. Después se reforzó el script de limpieza:
solo contemplaba dos tablas y dejaba referencias colgando en otras tres; ahora las limpia todas en la
misma operación. Se ensayó el borrado completo **con marcha atrás** para comprobar que salía bien, y
recién entonces se ejecutó de verdad.

**Resultado:** de 3720 eventos quedaron **1389**, y de 15978 detecciones quedaron **6679**. Los 1389
eventos de las simulaciones reales (los que entran por la puerta de enlace) están intactos. Se borraron
también los dos clientes de prueba que había dejado una auditoría vieja (AUDIT_A y AUDIT_B, vacíos) y tres
eventos sintéticos de las pruebas de hoy. Importante: hubo que **ajustar los contadores internos**, porque
si no el sistema comparaba "3710 recibidos contra 1389 guardados" y reportaba una pérdida de datos del
62% que era falsa; ahora marca 0%.

**Corrección sobre la marcha:** el vigilante que dejamos activo ayer estaba **reiniciando el honeypot cada
cinco minutos** sin necesidad. El motivo: reiniciaba en cuanto veía que no entraban datos, pero en un
laboratorio sin ataques eso es lo normal, no una avería. Ahora distingue las dos situaciones — mira si el
honeypot **sí** está registrando cosas que no llegan a la base (avería de verdad) o si simplemente no hay
tráfico (silencio) — y solo actúa en el primer caso. Probados los dos escenarios. Sin commitear aún. — fable

## [2026-08-26] corrección | El vigilante estaba reiniciando el honeypot en bucle (tercera es la vencida)
Rectifico lo que di por bueno hace unas horas: dije que el vigilante ya no reiniciaba en bucle, basándome
en una comprobación de seis minutos que cayó en un momento tranquilo. No era suficiente para un fallo que
se repite cada cinco. Revisando el registro completo aparecieron **166 reinicios en unas catorce horas**.

**Por qué fallaron los dos primeros intentos.** El primero reiniciaba en cuanto veía que no entraban datos;
en un laboratorio sin ataques eso es lo normal, no una avería. El segundo intentaba deducirlo comparando
cuántos eventos registra el honeypot contra cuántos llegan a la base — y ahí estaba la trampa: **al
reiniciar el honeypot sus contadores vuelven a cero**, y las propias sondas de salud del sistema los suben
otra vez; como esas sondas se descartan a propósito al entrar, parecía "produce pero no llega". Se mordía
la cola solo.

**La solución que sí funciona** es dejar de deducir y mirar el síntoma directo: cuando el honeypot pierde
la conexión con la cola de mensajes, lo escribe en su propio registro con un error concreto, uno por cada
evento que no consigue enviar. Ahora se exige ese error para actuar. La diferencia es medible: 106 de esos
errores durante la avería real, 0 con el sistema sano.

**Probado provocando la avería de verdad**, no simulándola: se reinició la cola de mensajes para romper el
canal, se confirmó que los eventos se perdían, y el vigilante lo detectó, reinició el honeypot y la
ingesta volvió a funcionar. Y con solo tráfico de sondas, no toca nada. — fable

## [2026-08-26] fix | Unificar la ingesta: lo que entraba por webhook se guardaba pero no se analizaba
El pendiente era "el barrido de pings no detecta nada". Investigándolo resultó ser la punta de algo mayor:
**había cinco puertas de entrada de eventos y solo una estaba completa**. La principal (la de los
honeypots) hacía quince cosas con cada evento —buscar patrones de ataque, elevar el riesgo, correlacionar,
registrar la cadena del ataque—; las otras cuatro (el sensor ICMP, OpenCanary, los cebos y los sensores de
campo) hacían entre cinco y ocho. En la práctica: **todo lo que entraba por esas cuatro puertas se
guardaba en la base pero nunca se analizaba**. Aparecía en la lista de eventos y jamás generaba una
detección. No daba error; simplemente no ocurría.

**Lo que se hizo.** Se extrajo el análisis a un solo sitio que ahora usan las cinco puertas, de modo que no
puedan volver a separarse. De paso salieron cuatro fallos que llevaban tiempo escondidos:
- El registro de la cadena de ataque del sensor ICMP **nunca funcionó**: se le pasaban mal los datos y el
  error se descartaba en silencio. Al arreglarlo apareció un segundo fallo detrás del primero. Ahora el
  error se registra bien visible: el silencio era justo lo que lo mantenía vivo.
- El disparo del cebo de un cliente **acababa atribuido al cliente por defecto**, sin avisar. Comprobado
  ya funcionando: el cebo del cliente "Iván" queda en su sitio.
- **Ocho reglas de ataques web** (inyección SQL, XSS, SSRF y compañía) estaban cargadas pero no podían
  detectar nada, porque miraban unos datos que nadie rellenaba —aunque el sistema ya los tenía a mano—.
  Al activarlas se destapó otra: una regla que habría marcado como sospechosa **cualquier** visita normal;
  corregida antes de que molestara.
- Los contadores de las cuatro puertas no se actualizaban, así que el panel de control mostraba menos de
  lo que realmente entraba.

**El corpus de reglas.** Se auditaron las 83 reglas de comportamiento y 13 no podían disparar jamás: unas
buscaban textos que este honeypot nunca escribe (ese era el caso del barrido de pings, cuyo término salió
de documentación vieja), otras miraban el campo equivocado —las de escáner buscaban el nombre de la
herramienta en la dirección web en vez de en el identificador del navegador—, y las de contraseñas
buscaban la clave dentro del texto del comando, lo que provocaba avisos falsos con cosas tan inocentes
como `chown root` y, a la vez, no veía el intento real. Todas corregidas y verificadas una por una.

**Lo más importante para el futuro:** se añadieron doce comprobaciones automáticas que fallan si alguien
vuelve a escribir una regla que mire un dato inexistente, o añade una puerta de entrada que no analice lo
que recibe. Al ponerlas en marcha ya destaparon siete casos más.

**Comprobado de punta a punta:** dos pings no disparan nada; el tercero genera **una sola** alerta de
barrido; el cuarto no duplica. OpenCanary y los sensores de campo ya generan detecciones (antes, ninguna).
Suite en 1102 pruebas verdes. Sin commitear aún. — fable

## [2026-08-26] fix | Sanear la base: puntuaciones que nadie podía explicar y alertas de reglas que ya no existen
Las tandas anteriores arreglaron la entrada de eventos **de aquí en adelante**. Lo que seguía sin tocar era
lo ya guardado, y al medirlo resultó bastante peor de lo anotado.

**Lo que se encontró.** De los 1.395 eventos de la base, **1.273 (el 91 %) tenían una puntuación de riesgo
mayor de lo que sus propios motivos justificaban**. El caso típico: un evento marcado con 80 puntos cuyos
dos motivos apuntados sumaban 50. Los 30 restantes no salían de ningún sitio — eran el rastro de las cuatro
reglas circulares que se retiraron el día 25 y que subían el riesgo de casi todo sin dejar constancia. Y no
se quedaba en el rango "alto": llegaba a 85, o sea que había eventos pintados como críticos sin motivo.

Además apareció una segunda mitad que nadie había contado: **5.076 de las 6.681 alertas guardadas (el 76 %)
pertenecían a esas cuatro reglas retiradas**. El motor ya ni las carga, pero sus registros seguían ahí
copando el panel de detecciones, el mapa de técnicas de ataque y la narrativa. La consola seguía mintiendo
sobre el pasado aunque la entrada de datos ya fuera correcta.

**Cómo se arregló, sin inventar nada.** No se volvieron a analizar los eventos viejos: aquellos se
guardaron antes de que el sistema recogiera ciertos datos de las peticiones web, así que volver a pasarles
las reglas de hoy habría comparado peras con manzanas. En su lugar se aplicó la regla que usa el sistema
ahora mismo, pero **usando solo las pruebas que ya estaban guardadas**: el riesgo de cada evento pasa a ser
la suma de sus propios motivos, o el mínimo que impongan sus alertas supervivientes si es mayor. Todo con
respaldo previo de la base y en una sola operación reversible.

**Dos cosas que el plan no había previsto y se corrigieron sobre la marcha:**
- **346 eventos tenían la puntuación correcta pero nada que la explicara.** Filtrar por "el número cambia"
  los dejaba fuera: son los que el analizador de firmas sube a 85 sin apuntar el motivo. La comprobación
  final habría dado 346 fallos en vez de cero.
- **El analizador de firmas no respeta el nivel que declara la regla**: sube al máximo directamente.
  Deducirlo del nivel guardado habría rebajado a 70 lo que el sistema pone en 85, en más de trescientos
  registros.

**Lo que queda para que no vuelva a pasar.** Treinta comprobaciones automáticas que fijan una sola frase:
*la suma de los motivos de un evento es exactamente su puntuación de riesgo*. Si algo sube el riesgo sin
apuntar por qué, fallan. Conviene contar que **esas comprobaciones nacieron vacías**: el sistema carga las
reglas al arrancar, y en las pruebas eso no ocurre, así que pasaban sin comprobar nada en realidad. Se
añadió lo que faltaba para cargarlas, más una comprobación que exige que estén cargadas y otra que exige
que los casos de prueba sigan disparando de verdad. Se verificó rompiendo el sistema a propósito: fallan.

**Un fallo distinto, encontrado al verificar.** El sistema nunca conseguía leer qué navegador o herramienta
usaba el atacante. Lo buscaba en un sitio donde el honeypot escribe texto corrido en vez de una lista de
datos, así que reventaba **en cada visita web** — y el error se descartaba sin dejar rastro. Lo grave no es
el dato en sí: dentro de ese mismo bloque estaba **el envío de la alerta**, así que llevaba meses sin
enviarse. Corregido, con diez comprobaciones nuevas, y el error ahora se registra bien visible. Comprobado
en vivo: la huella de un escáner ya acumula puntuación donde antes no acumulaba nada.

**Resultado comprobado contra la base y en vivo:** ningún evento descuadrado, ninguna alerta de regla
retirada, ningún registro huérfano y ni un evento perdido. Las alertas pasan de 6.681 a 1.605. El reparto
de gravedad deja de estar aplastado contra el techo: 830 medias, 197 altas, 368 críticas. Veinticuatro
eventos **subieron** de riesgo; se revisaron uno a uno y todos son ataques reales que estaban
infravalorados —cebos disparados, subida de webshell, inyección de comandos, robo de credenciales—.
Suite en 1132 pruebas verdes. Sin commitear aún. — fable

## [2026-08-27] fix | Las trampas dejaban su rastro para siempre: cerrar el ciclo de vida de los cebos
Esta salió de tirar de un hilo equivocado. Al revisar por qué el sistema tenía un 87 % de reglas
marcadas como "críticas" resultó que la alarma era falsa —y que detrás había un problema real, pero
distinto—.

**Cómo funcionan los cebos.** Cuando se planta una trampa (una credencial falsa, un fichero señuelo),
el sistema escribe una regla que vigila ese secreto concreto: si alguna vez reaparece en un ataque,
significa que alguien se lo llevó y lo está usando. Es de lo más valioso que tiene la plataforma,
porque un acierto ahí no admite duda.

**El problema.** Esa regla se creaba al plantar la trampa y **no se borraba nunca**. El módulo tenía
la función de registrar y ninguna de retirar. Al eliminar una trampa desde la consola desaparecía su
ficha, pero la regla se quedaba en el disco. Resultado medido: **382 reglas frente a 20 trampas
vivas**, acumuladas desde el 14 de julio. Ninguna había disparado jamás, y 140 eran el mismo señuelo
de pruebas repetido.

No es solo desorden. Cada regla se revisa contra cada cosa que entra, así que el sistema gastaba
trabajo en vigilar trampas que ya no existen. Y peor: si el secreto de una trampa retirada reaparece,
salta una alerta **crítica** de algo que ya no está puesto. Una falsa alarma de manual, justo lo que
estas semanas llevamos corrigiendo.

**Por qué nadie lo había limpiado.** No se podía. La regla se escribía con el secreto, pero en la
ficha de la trampa se guardaba **otro valor distinto**: el secreto no se apuntaba en ningún sitio. No
existía forma de saber qué regla pertenecía a qué trampa. La única excepción eran las credenciales
falsas, que sí guardan su contraseña — de ahí salía la única regla que se pudo emparejar.

**Lo que se hizo.** Primero crear el vínculo que faltaba: al plantar una trampa se apunta en su ficha
una huella del secreto (**la huella, nunca el secreto**: sirve para encontrar la regla y no convierte
la base en un almacén de contraseñas). Con eso, borrar la trampa ya retira su regla, en las tres vías
por las que se puede borrar. Después, un script limpió lo acumulado: **384 reglas retiradas, 1
conservada**, con copia de seguridad comprimida antes de tocar nada — porque si mañana aparece una
trampa desplegada que no consta, se puede deshacer.

**Comprobado en vivo, de punta a punta:** plantar una credencial falsa crea su regla y deja la huella
en la ficha; borrarla contesta "1 regla retirada" y el fichero desaparece. El sistema pasa de vigilar
465 reglas a 84, y el reparto de gravedad por fin es razonable: 16 medias, 43 altas, 25 críticas
(antes las críticas eran el 87 %). La entrada de eventos sigue funcionando igual y cada puntuación
sigue cuadrando con sus motivos. Suite en 1146 pruebas verdes.

**De dónde salían de verdad.** Al vigilar el sistema después de limpiarlo aparecieron siete reglas
nuevas de la nada. No las creaba nadie usando la plataforma: **las creaban las propias pruebas
automáticas**. Varias plantan trampas para comprobar que funcionan, y cada vez que se ejecutaban
dejaban su rastro en el directorio de verdad. Como las pruebas corren en cada cambio que se guarda,
ahí estaba el goteo desde julio. Tres ficheros de prueba lo provocaban, pero el fondo era otro: solo
una de las tres vías por las que se planta una trampa respetaba el ajuste que manda esos ficheros a
un sitio temporal; las otras dos escribían siempre en el directorio real. Se unificó en un único
sitio y se añadió una regla general para todas las pruebas, de modo que quien escriba una prueba
nueva quede cubierto sin tener que saber nada de esto. Comprobado: ahora la tanda entera de pruebas
deja el directorio tal como lo encontró.

**Un fallo propio, dicho claro.** La primera versión del script de limpieza nombraba la copia de
seguridad solo con la fecha, así que al ejecutarlo por segunda vez el mismo día **se sobrescribió la
copia de la primera** y se perdió el respaldo de las 384 reglas retiradas. El daño real es pequeño
—eran reglas sin dueño, que no habían disparado nunca en toda la historia del sistema— pero la copia
existe justo para no tener que confiar en eso. Corregido: ahora el nombre lleva fecha y hora, y el
script se niega a machacar una copia que ya exista.

**Queda anotado:** los señuelos de tipo "migaja de pan" no se guardan en ninguna tabla, así que sus
reglas siguen sin poder emparejarse con nada. Cerrar también ese ciclo necesita una tabla nueva y se
dejó para otra tanda. — fable

## [2026-08-27] feat | El riesgo ya se explica solo: por qué un evento puntúa lo que puntúa
Las dos tandas anteriores se dedicaron a que cada puntuación de riesgo se pudiera justificar. Se
limpió el histórico, se dejó la regla de que **los motivos de un evento suman exactamente su
puntuación** y treinta comprobaciones automáticas vigilándola. Hoy no hay ni un solo evento en la base
cuyo número no cuadre con sus motivos.

**Y nada de eso llegaba a ninguna pantalla.** La consola enseñaba el número y, al pulsar una fila, un
volcado técnico del mensaje original. El correo de alerta decía "Riesgo: 85/100" y punto. El dato
existía, era correcto y estaba a mano —el propio correo ya lo recibía sin mirarlo— pero se quedaba
guardado. Justo lo que hizo falta el día que un simple `GET /` empezó a salir en 80 y nadie supo
decir por qué.

**Lo que se hizo.**

En la **consola**, el panel de detalle ya existía; ahora abre con una sección "Por qué este riesgo"
que lista cada motivo con sus puntos y el total, que coincide con el número de la fila. Si alguna vez
no coincidiera, se pinta en rojo en lugar de disimularlo: significaría que algo elevó la puntuación
sin dejar constancia, que es el fallo original.

En el **correo**, el desglose va justo debajo de la línea de riesgo, en los tres tipos de aviso (cebo
abierto, credencial señuelo usada, interacción con el honeypot). Queda así:

```
⚠️ Riesgo:    85/100
   · Acceso a sensor perimetral        +30
   · Petición HTTP al honeypot         +20
   · Ruta de explotación conocida      +25
   · Escáner conocido detectado        +10
```

Dos detalles que el dato real obligó a cuidar. Uno: hay motivos que valen cero puntos —por ejemplo la
marca de que un evento se recalibró en la limpieza del día 26, que está en 1.284 eventos—; son notas,
no motivos, y van aparte, porque mezclarlos haría que la suma pareciera no cuadrar. Y dos: si los
motivos no suman la puntuación guardada, el correo enseña el número a secas. Un aviso de madrugada no
es el sitio para enterarse de que algo va mal por dentro.

**De paso, una incoherencia vieja.** El mapa de ataques calculaba la gravedad **con otros umbrales**
que el resto del sistema: su máximo era "alta" y nunca llegaba a "crítica". Así que una categoría con
riesgo medio de 90 se pintaba como alta en esa pantalla y como crítica en todas las demás. Es
exactamente el problema que la recalibración del día 25 quiso eliminar, escondido en una función
suelta. Ya usa los mismos cortes que todo lo demás. Curiosamente, **una prueba automática daba por
buena la versión rota**: afirmaba que 85 era "alta". Se corrigió dejando escrito por qué cambió.

**Comprobado en vivo:** la interfaz devuelve los cuatro motivos de un `GET /.env` y suman su 85
exacto; el correo generado con un evento real de la base muestra el desglose cuadrando; el mapa de
ataques ya produce "crítica", que antes era imposible. La entrada de eventos sigue igual y no hay ni
un evento descuadrado. Suite en 1179 pruebas verdes.

**Queda anotado:** los textos de los motivos vienen en inglés del motor de riesgo, mientras la consola
es en español. Se muestran tal cual porque son el dato real; traducirlos toca una veintena de textos
y sus pruebas, y mezclarlo aquí habría enturbiado la comprobación. — fable

## [2026-08-27] fix | La misma táctica contada dos veces: unificar los nombres de MITRE
El panel que resume qué tipo de ataques se han visto llevaba contando mal desde siempre, y hoy se vio
por qué.

**El problema.** Cada detección guarda a qué "táctica" de la clasificación MITRE pertenece —
reconocimiento, robo de credenciales, movimiento lateral…—. El panel agrupa por ese texto. Y ese texto
estaba escrito de varias maneras distintas para la misma cosa: de 1.643 detecciones, 644 lo tenían en
minúsculas (`discovery`), 643 con su código delante (`TA0007 - Discovery`) y 356 en blanco. Resultado:
"Descubrimiento" aparecía **dos veces en el panel**, con 225 y 87, cuando eran 312. "Persistencia"
salía en cuatro filas, una de ellas con un guion largo en vez de corto — invisible a simple vista y
suficiente para que la base las tratara como cosas distintas.

**No era culpa de quien escribe las reglas.** Cuando una regla no dice su táctica, el sistema la
deducía de sus etiquetas y la dejaba en minúsculas; cuando sí la dice, unas usan un guion y otras
otro. Tres formas de escribir lo mismo y nadie comprobando nada. En el conjunto de reglas activas
había **29 variantes para 13 tácticas**.

**Lo que se hizo.** Un único sitio que sabe cómo se llama cada táctica y traduce cualquier forma a la
buena. La forma buena no hubo que inventarla: el resto del sistema ya usaba el nombre limpio
("Descubrimiento" sin código), y por eso el mapa de calor de MITRE —que bebe de otra tabla— siempre
estuvo bien. Ahora las reglas se normalizan al cargarse, y un script limpió lo ya guardado: 17
variantes quedaron en 10 tácticas, 1.287 filas corregidas, con copia de seguridad previa.

**Y tirando de ese hilo aparecieron tres fallos encadenados**, cada uno tapando al siguiente:

1. Las 356 detecciones en blanco eran todas del motor de firmas (YARA). El código metía la **técnica**
   en la casilla de la **táctica**, y dejaba la de técnica vacía.
2. Al corregirlo, seguía sin funcionar: **el motor de firmas nunca entregaba los datos de la regla**.
   Quien los pedía tenía valores por defecto para todo, así que nada fallaba — simplemente toda
   detección se guardaba como "alta" aunque su regla dijera "media", y nunca se sabía qué cadena había
   saltado.
3. Y aun así seguía sin funcionar, porque **había dos puertas para guardar detecciones**: la unificada
   y una copia propia dentro del componente que procesa el honeypot principal, que la unificación del
   día anterior había dejado atrás. Como por ahí pasa la mayor parte del tráfico, arreglar la puerta
   buena no arreglaba nada. Ahora hay una sola puerta, y una comprobación automática impide que
   vuelvan a ser dos.

**Comprobado en vivo:** las detecciones nuevas nacen con el nombre correcto; las del motor de firmas
ya llevan su técnica, su gravedad real y las cadenas concretas que saltaron (solo los nombres de las
cadenas, no su contenido: eso puede ser el ataque en sí y no tiene por qué acabar en la base). El
panel ya no duplica ninguna táctica. Y el mapa de calor de MITRE quedó **exactamente igual** antes y
después, que era justo la prueba de que no se rompió nada al lado. Suite en 1240 pruebas verdes.

**Queda anotado:** la táctica de las detecciones del motor de firmas sigue en blanco. Ya tienen
técnica, pero deducir la táctica exige un trabajo aparte sobre 89 formatos distintos. — fable

## [2026-08-27] fix | Cerrar toda la deuda de la auditoría: cinco frentes de una tanda
Las tandas de estos tres días fueron dejando cosas apuntadas «para otro momento»: detalles que se
descartaban a propósito para no enturbiar la comprobación de lo que se estaba arreglando en ese
instante. Eran seis. Se cierran todos.

Al hacer inventario antes de empezar, **uno estaba ya resuelto**: la nota decía que el barrido de
pings no podía detectarse, pero eso se arregló el día 26 y nadie actualizó el apunte. Comprobado en
vivo: tres pings seguidos producen una sola alerta de barrido, como debe ser.

**Los nombres de las tácticas.** El sistema clasifica cada detección según el catálogo MITRE, y 356
no tenían clasificación ninguna. Se arreglaron todas. Por el camino aparecieron tres cosas del mismo
tipo —el dato estaba, simplemente no se leía—: las reglas declaran su técnica con **tres nombres de
campo distintos** y el código solo miraba uno; **33 reglas viven en subcarpetas** que ni el script ni
*mi propia comprobación automática* estaban mirando (al corregir la comprobación, ella misma destapó
doce técnicas que faltaban); y las detecciones antiguas no tenían de dónde deducir la clasificación…
salvo que el dato seguía en el fichero de su regla, y el identificador de la detección dice cuál es.
Se recuperaron de ahí en vez de darlas por perdidas.

**La evidencia de las reglas que estaban rotas.** Cinco reglas se reescribieron el día 26 porque no
detectaban lo que decían detectar. Sus detecciones anteriores seguían guardadas. En vez de borrarlas
en bloque, se volvió a pasar **la regla de hoy** sobre el evento original: si sigue casando, la
detección vale; si no, era falsa. Menos mal que se hizo así, porque el resultado no fue uniforme: una
de las cinco se salvó **entera** (la reescritura solo la había afinado), mientras que otras dos
cayeron al completo. ¿Qué las disparaba? **Peticiones web normales.** Un simple `GET /` contenía la
palabra `host` dentro de una cabecera y una dirección `192.168.`, y con eso el sistema lo registraba
a la vez como salto entre máquinas por SSH y como comunicación con un servidor de control. Una visita
contaba como dos ataques. De 949 detecciones, 264 tenían fundamento y 685 no.

**Cobertura que faltaba.** El sensor industrial llevaba desde julio emitiendo eventos que ninguna
regla miraba: el riesgo se calculaba bien, pero no aparecía con nombre en el panel. Ahora hay dos
reglas —leer el proceso es reconocimiento; **escribir** en él es intentar manipularlo, y eso es lo
grave—, comprobadas con un ataque real contra el señuelo. También se cubrieron SNMP y NTP, aunque
ahí la comprobación es simulada: ese señuelo no está desplegado en esta máquina y conviene decirlo.

**Los textos, en español.** Desde que la consola explica por qué un evento puntúa lo que puntúa, esos
textos los lee una persona — y venían en inglés. Cuarenta y uno traducidos. Se tradujo lo que se ve,
nunca la etiqueta interna: esa se usa en las consultas a la base y traducirla las habría roto.

**Y las migas de pan.** Eran el último hueco: se generaban, se registraba su regla de vigilancia y no
se guardaban en ninguna parte, así que no se podían ni listar ni retirar. De las 384 reglas
huérfanas que hubo que purgar el día anterior, 140 eran justamente eso. Ahora tienen su ficha, se
listan y al borrarlas se llevan su regla. Comprobado el ciclo entero.

**Un detalle que las pruebas existentes cazaron y agradezco:** al pedir la conexión a la base para
guardar la ficha, generar una miga pasaba a **exigir** base de datos, y antes funcionaba sin ella.
Eso era empeorar, no mejorar. Se dejó tolerante: si no hay base, el artefacto se entrega igual.

Suite en 1292 pruebas verdes. En el roadmap ya no queda deuda de esta auditoría; lo que sigue
apuntado son las épicas de producto (despliegue, notificaciones, cifrado del canal), que son otra
cosa. — fable

## [2026-08-27] fix | Dos «mejoras pendientes» que eran agujeros de seguridad
Cerrada la deuda de la auditoría, tocaba mirar qué quedaba apuntado. Dos de esas notas estaban
descritas como mejoras de comodidad o de despliegue, y al medirlas resultaron ser otra cosa.

**El canal en vivo estaba abierto de par en par.** El sistema tiene un canal por el que empuja cada
evento nuevo en tiempo real. Estaba anotado como «pendiente: acotarlo por cliente», sonando a mejora.
La realidad, comprobada conectándome: **acepta conexiones sin ninguna credencial**, y a quien se
conecta le manda **los eventos de todos los clientes** — la dirección desde la que atacan y el
comando que ejecutan. En una plataforma donde cada cliente paga por ver lo suyo, eso es que el
cliente A ve los ataques que recibe el cliente B.

Tres cosas lo empeoraban. El mensaje ni siquiera decía a qué cliente pertenecía cada evento, así que
tampoco podría filtrarse en el navegador. Activar el inicio de sesión **no lo habría tapado**: la
protección de sesión está montada de una forma que, por cómo funciona la librería, no se aplica a
este tipo de conexiones — estaba cubierta la web y no el canal en vivo. Y el servidor web lo publica
hacia fuera, así que era alcanzable desde la red.

Lo más llamativo: **la interfaz ya ni lo usaba**. La vista que lo consumía se retiró hace tiempo y su
código quedó muerto. Era una puerta que no servía a nadie y filtraba datos entre clientes.

Ahora cada conexión se identifica y queda anotada con los clientes que puede ver, y solo recibe esos.
Sin credenciales válidas se cierra la conexión antes de aceptarla: nada de datos antes de saber quién
está al otro lado. En el entorno de trabajo diario, donde el inicio de sesión está apagado, todo
sigue funcionando igual que antes.

**Y una comprobación que vale más que el arreglo:** ahora falla la batería de pruebas si alguien añade
otro canal en vivo sin identificar a quien se conecta. El fallo de fondo no fue olvidar proteger éste,
sino dar por hecho que la protección general llegaba hasta ahí. El siguiente nacería igual de abierto.

**Las contraseñas llevaban semanas guardándose de forma más débil.** El sistema prefiere un método de
cifrado lento y resistente a la fuerza bruta, y si no está disponible baja a uno más simple para no
dejar a nadie fuera. Eso está bien pensado. Lo que no lo estaba es que **lo hacía sin decir nada**: la
herramienta buena no estaba instalada en la imagen —una instalación manual de agosto se perdió al
recrear el contenedor— y ni una línea del arranque lo mencionaba. Reconstruida la imagen, añadido un
aviso bien visible si vuelve a faltar (diciendo qué hacer, no solo que algo va mal) y el método en uso
ahora se ve desde fuera, sin entrar al contenedor. Las contraseñas antiguas siguen valiendo y se
actualizan solas al siguiente inicio de sesión.

**Un aviso más para los cebos.** Los documentos trampa «llaman a casa» al abrirse. El sistema ya
avisaba si esa dirección era inalcanzable desde otra máquina; ahora avisa también cuando va sin
cifrar por la red local: funciona, pero un antivirus corporativo puede bloquearlo y no captura
aperturas fuera de la red del cliente. **El aviso no dice «pon cifrado y ya»**, y es importante: un
certificado hecho en casa **rompería la trampa** —el procesador de textos lo rechazaría— y sería peor
que dejarlo como está. Dice qué vía usar según el caso.

**Y algo que decidí no hacer, con sus números.** Faltaba una regla para la única categoría de ataque
sin cubrir del catálogo MITRE. Al medirla: **cero señales** de ese tipo en toda la base, y lo poco
parecido que hay ya está clasificado donde el propio MITRE lo pone. Esa categoría describe lo que el
atacante prepara en *su* infraestructura antes de atacar; una trampa ve el ataque, no la preparación.
Escribir la regla habría sido aparentar cobertura que no existe — justo el problema que llevamos días
corrigiendo. Queda una comprobación que deja constancia de que es una decisión medida y no un
descuido.

Suite en 1320 pruebas verdes. — fable

## [2026-08-27] fix | Primera revisión de la consola: tres fallos reales y tres malentendidos
Iván revisó la interfaz con calma y mandó capturas. De lo que reportó, tres eran fallos de verdad y
tres eran cosas que parecían fallos y no lo eran — conviene dejarlo escrito para no volver a
investigarlo.

**Los tres fallos.** El más molesto: al recargar en una pestaña aparecían secciones de otras, y al
cambiar de pestaña y volver, desaparecían. La causa resultó ser **una regla de estilo que apuntaba a
un nombre que no existe**: ocultaba unas pestañas llamadas de una forma cuando en la página se llaman
de otra. Como no coincidía, la regla no hacía nada — y las pestañas se veían en una pantalla donde el
diseño decía que no debían estar. Una regla que no encaja con nada no da error: simplemente no
funciona, y el efecto se ve pero nada en el código lo señala.

Los otros dos: al pulsar una dirección IP, su ficha se dibujaba **encima** del panel de detalle
porque tenía prioridad de capa; y ese panel de detalle **sobrevivía al cambio de pestaña**, quedándose
pegado abajo tapando lo que había debajo. Los dos, arreglados.

**Lo que no eran fallos.** El flock de Iván tiene **un solo evento**: el disparo de uno de sus propios
cebos — justo el arreglo del día anterior funcionando, **no hay fuga de datos**. El "ruido de
direcciones IP" son **dos** direcciones, ambas de nuestras pruebas. Y el mapa de origen de ataques
está vacío porque **no hay ninguna dirección pública que localizar**: una es de red interna y la otra
pertenece a un rango reservado para documentación. Los textos en inglés que veía son los eventos
antiguos, que guardaron el texto de antes de traducirlo.

**Una sola pantalla.** Las tres pestañas repartían veintisiete secciones y obligaban a recordar qué
había en cada una. Ahora está todo en una página, ordenado por el momento en que se usa: qué está
pasando, analizar, infraestructura, trampas. Un índice lateral salta a cada bloque y marca dónde
estás al desplazarte. El riesgo de mover veintisiete bloques es dejarse uno, así que hay una
comprobación automática que verifica que están todos, sin duplicados.

**Las personalidades del honeypot.** Ver cómo responde una persona costaba un ciclo entero: editarla,
aplicarla, reiniciar el honeypot y conectarse a mano. Ahora hay una zona de pruebas dentro de la
propia pantalla: escribes lo que teclearía el atacante y ves qué contestaría, **con el borrador que
tienes a medias y sin aplicar nada**. La pantalla además explica qué hace bueno a un prompt y trae un
ejemplo real. Un detalle importante: si no hay clave del modelo configurada, el sistema responde con
un texto de reserva; la zona de pruebas **avisa de eso antes de enseñar la respuesta**, porque ajustar
un disfraz mirando texto inventado es peor que no probar nada.

**Y la primera sesión SSH real contra el honeypot.** Funcionó y quedó registrada. Destapó dos cosas:
la sesión se cerraba a los dos minutos (era un límite total, no de inactividad) — subido a diez; y que
**`cd` no cambia de directorio**. Esto último se investigó a fondo y **no tiene arreglo por
configuración**: la versión del honeypot que usamos evalúa cada comando de forma aislada, sin recordar
lo anterior. Se comprobó de dos formas distintas. La instrucción que se había añadido al disfraz para
pedirle que recordara el directorio **se retiró**: pedirle al modelo algo que no puede cumplir solo
estorba. Queda anotado como limitación conocida, con las salidas posibles.

Suite en 1348 pruebas verdes. — fable

---

## 27 de agosto de 2026 — La separación entre clientes, de verdad

Volvieron las pestañas. La barra lateral duró poco: las tablas se le montaban encima porque tres
secciones declaran su propio margen y, en CSS, una clase gana a un selector de elemento. El
reordenado por momento de uso se conservó —eso no era el problema—, así que ahora hay cuatro
pestañas sobre esos mismos cuatro grupos.

**La duda de fondo era otra, y era la buena:** «en el flock de Iván no hay nada desplegado, pero
aparecen canarios desplegados e incluso detecciones». Se midió contra la base: ese cliente tiene **un
solo evento**, el disparo de su propio cebo, y dos detecciones de ese mismo evento. **No había
filtración.** Lo que se colaba en su pantalla eran cosas de la plataforma pintadas como si fueran
suyas: los honeypots de Beelzebub —una única instancia compartida por todos— y, sobre todo, un
contador de las 87 reglas del motor que se colaba en una respuesta por cliente. La consola encendía
el panel como «Activo» y ponía ese 87 en la casilla de detecciones de un cliente con cero sensores,
cero cebos y cero credenciales. Arreglado: el aviso de «sin desplegar» ya no depende de un contador
global, la casilla muestra las detecciones reales y los honeypots llevan la etiqueta
**«compartidos»**.

**«Si entro a Beelzebub, ¿a quién estoy atacando?»** La respuesta honesta era: a nadie en concreto.
Todo el tráfico caía en el cliente por defecto, y no por decisión sino porque **no había ningún dato
en el evento que permitiera decidir**. El programa que recibe los ataques leía un campo que el
honeypot nunca ha enviado —cero de mil cuatrocientos setenta y tres eventos lo traían—, así que el
identificador del honeypot quedaba vacío en mil cuatrocientos cuarenta y dos. El otro campo parecido
tampoco servía: guarda rutas internas, no el honeypot.

Lo que sí estaba, y en casi todos los eventos, era **el puerto atacado**. Y el registro de sensores ya
sabía qué sensor escucha cada puerto y de qué cliente es, pero nadie lo consultaba. Ahora sí: puerto
→ sensor → cliente. Con eso, **un cliente = su sensor en su puerto**, que es el modelo que se había
elegido. Una regla escrita a mano por el operador sigue mandando por encima; el cliente por defecto
queda como último recurso. Se comprobó con un ataque real por SSH: el evento llegó etiquetado con su
sensor y su cliente. Los mil cuatrocientos veinte eventos anteriores se rellenaron a partir del
puerto, con copia de seguridad previa.

Y la consola ahora lo **dice**: al abrir un evento aparece quién lo capturó —qué sensor, en qué
puerto— y de qué cliente es, en vez de tener que fiarse de una etiqueta.

**Un fallo silencioso que se borraba solo.** Las detecciones nacían sin cliente asignado. La fila del
evento sí lo tenía, porque se resolvía dentro de la propia orden a la base; pero lo que heredan las
detecciones es el dato en memoria, y ahí quedaba vacío. Una detección sin cliente **no aparece en
ningún cliente**, tampoco en el de por defecto. Lo peor: al reiniciar, una reparación automática las
arreglaba, así que el fallo duraba justo lo que durase el proceso y no dejaba rastro. Se comprobó al
revisarlo: las siete detecciones afectadas ya habían desaparecido tras dos reinicios. Ahora la caída
al cliente por defecto se decide antes, donde sí la heredan las detecciones.

**El ruido de direcciones IP.** De doscientas cincuenta y nueve filas, **doscientas cincuenta y
cuatro** eran direcciones a las que el router contestó con un rechazo durante un barrido: sin puertos
abiertos, sin identificador de tarjeta de red y sin nombre. Como la lista se ordenaba por fecha,
copaban las cincuenta que caben en pantalla y los cuatro equipos útiles no salían nunca. Ahora se
ocultan por defecto, la lista se ordena por señal antes que por novedad, y **se dice cuántas se
esconden** con un interruptor para verlas: esconder doscientas cincuenta y cuatro filas sin avisar se
lee como «la red solo tiene cinco equipos», que es otra mentira distinta.

Aquí hubo un error propio que conviene anotar. El primer filtro incluía la huella de sistema
operativo como señal válida, y **no escondió nada**: las doscientas cincuenta y ocho filas la tenían.
Al mirarlas de cerca eran invento del escáner —cuatro direcciones seguidas etiquetadas como la misma
impresora, sin un solo puerto abierto—. Sin puertos, esa huella no vale. Queda como prueba para que
no vuelva.

**Sobre las pruebas.** Un rato perdido persiguiendo un fallo que aparecía y desaparecía: era código
compilado antiguo que quedaba en caché al restaurar los ficheros de respaldo. Las comprobaciones de
calidad hechas antes de descubrirlo se repitieron todas desde cero.

**Lo que no se pudo hacer.** La identidad del honeypot sigue cambiando en cada reinicio, y por eso
salta el aviso de «la máquina ha cambiado» al conectarse por SSH. Para desbloquearse:
`ssh-keygen -R "[localhost]:2222"`. No hay forma de fijarla por configuración en la versión que
usamos; para un honeypot no es un detalle menor, porque **lo delata**: cualquiera que vuelva tras un
reinicio sabe que la máquina es efímera. Queda anotado.

Suite en 1368 pruebas verdes. — fable

---

## 27 de agosto de 2026 (tarde) — Lo que rompí al quitar la barra lateral

Empiezo por lo importante: **dos de las cuatro cosas que reportaste las rompí yo**, y en el mismo
sitio. Al retirar la barra lateral por la mañana, el cambio quitó ciento veinticuatro líneas de
estilos y añadió dieciséis. Solo unas cuarenta eran de la barra. Las demás no tenían nada que ver, y
cada una se llevó algo por delante:

- La **tira de indicadores del panel central** perdió su formato y pasó a pintarse como texto corrido
  en vertical: «3Flocks», «5/6Sensores activos». No era que estuviera mal implementada; era que se
  quedó sin estilos.
- La **gráfica de cada cliente** perdió su altura fija —treinta píxeles— y sin ese tope se expandió
  hasta ocupar media pantalla.
- Y la regla que mantenía **auditoría, notificaciones y usuarios** fuera de la vista, disponibles solo
  desde el engranaje. Sin ella, esas tres salían en las cuatro pestañas y dentro de todos los
  clientes. Eso es lo que viste en el cliente IR y lo que, con toda razón, te pareció una filtración.

Es el mismo tipo de fallo que el de la semana pasada: un estilo que el programa aplica pero que ya no
existe **no da error, simplemente no hace nada**. Por eso ahora hay una comprobación automática que
recorre todos los estilos que el programa aplica y exige que existan. Habría atrapado este y el
anterior.

**Por qué se repetían secciones entre pestañas.** Tenías razón aunque el reparto no tuviera ningún
bloque duplicado: lo que se repetía era el *contenido*. La sección «Remote Sensors» repetía la
familia de sensores del panel de Despliegue, y estaba en la misma pestaña, justo al lado. Los cebos y
las credenciales trampa se desplegaban desde Infraestructura pero se administraban en Trampas. Y
había dos mapas de ataques en pestañas distintas.

Ahora hay **una sola entrada por cosa**: se retiró la sección suelta de sensores llevándose al panel
lo único que ella tenía y el panel no —saber de un vistazo cuántos están degradados o caídos, porque
un «3» a secas no distingue tres sensores sanos de tres muertos—; los cebos y las credenciales pasan
a estar junto al panel desde el que se despliegan; y los dos mapas son ahora uno con dos modos. El
mapa de origen geográfico salía **siempre vacío** porque no hay ni una sola dirección pública en toda
la base, así que parecía roto: ahora, cuando no hay nada que situar, lo dice.

De veintisiete secciones a veinticinco. Las dos comprobaciones que vigilan que no se pierda ninguna
hicieron su trabajo: fallaron en cuanto retiré las dos, y se actualizaron a conciencia.

**Discovered Hosts.** Preguntabas qué aporta. Con el ruido del barrido ya filtrado quedaban cuatro
equipos, y **dos eran TARTARUS**: el propio motor y la puerta de enlace de su red interna. Los otros
dos son tu router y un Mac. Ni un solo atacante. Ya existía la pieza que sabe reconocer nuestras
propias máquinas, pero solo se usaba al recibir ataques, nunca al listar equipos. Ahora lo nuestro se
agrupa aparte, **diciendo por qué** —«es un contenedor de TARTARUS», «está en la red de Docker»— en
vez de pedirte que te fíes. El contador pasa a decir tres cifras: hallados, propios y ocultos por
falta de señal. En un cliente de verdad la sección sí sirve, para mapear su red y saber dónde plantar
cebos; aquí solo se veía a sí misma.

Un matiz que conviene decir: hay una regla que **a propósito** no ignora la puerta de enlace cuando
llega un ataque, porque un atacante externo puede aparecer con esa dirección y descartarlo sería
perder ataques reales. Para la lista de equipos la regla es la contraria. Son dos reglas distintas y
se han dejado separadas justamente para no romper una arreglando la otra.

**Y un susto que era mío.** La vigilancia automática marcó de golpe los mil cuatrocientos ochenta y
cinco eventos como incoherentes en su puntuación de riesgo. No lo eran: mi consulta buscaba el campo
del peso por un nombre equivocado, sumaba cero y por tanto todo le parecía mal. Con el nombre bueno:
**cero incoherencias**. Queda anotado, porque un cuadro de mando que grita sin motivo es peor que uno
que calla.

Suite en 1387 pruebas verdes. — fable

---

## 28 de agosto de 2026 — Por qué el botón de prueba de la IA no funciona

Cerramos la revisión anterior con veinte minutos de vigilancia y **todo en cero**: ninguna puntuación
de riesgo incoherente, ninguna detección sin cliente, ningún evento sin cliente, ningún error.

**El botón de prueba de AI Settings.** Metiste la clave, pulsaste probar y te dijo que no hay ningún
proveedor configurado. No era la clave: **se estaba guardando en un sitio que nadie lee**.

El programa calcula la ruta del fichero de configuración subiendo tres carpetas desde donde está su
propio código. Dentro del contenedor eso no lleva al fichero del proyecto, sino **a la raíz del
contenedor**. Y ese fichero, además de no ser el bueno, no lo lee nadie al arrancar: el sistema de
contenedores lee el del ordenador, no el de dentro. Medido: dentro del contenedor hay una clave de
ciento sesenta y cuatro caracteres guardada, y la variable correspondiente está **vacía**.

Eso explica por qué el fallo despista tanto. Al guardar, la clave **sí queda cargada en memoria**, así
que funciona hasta que el motor se reinicia. Como ayer se reinició varias veces por los cambios, se
perdió por el camino y volvió al modo de reserva sin decir nada.

**Y una confusión que conviene deshacer**, porque hay dos inteligencias artificiales distintas y solo
una está rota:

- La **del honeypot** —la que habla con el atacante y le da vida a las personas— **funciona**.
  Comprobado: al conectarse por SSH responde como `prod-web-01`. Su clave vive en los ficheros de
  configuración del honeypot.
- La **del motor** —la que analiza los eventos— es la rota, y es la que prueba ese botón.

Queda apuntado con su arreglo: que la clave persista de verdad entre reinicios, una comprobación
automática que impida que la ruta vuelva a apuntar fuera de sitio, y que la consola avise cuando algo
solo vive en memoria. De paso hay que arreglar la casilla de «sincronizar con Beelzebub», que llama a
una función **marcada como obsoleta en su propio código**: escribe donde el honeypot no mira.

**Sobre dejar los clientes a cero para llevar control.** Es buena idea y así lo haremos, pero antes de
borrar nada conviene saber tres cosas que medimos hoy:

- **IR y Pruebita ya están a cero.** Lo que se veía dentro de IR era el fallo de estilos de ayer, ya
  reparado. No hay nada que limpiar ahí.
- La tabla de sensores **no se puede vaciar**. Sus seis filas son lo que permite decir de qué cliente
  es cada ataque; sin ellas, todo vuelve a caer en el cliente por defecto y perdemos lo construido.
- **Trece tablas** llevan la marca del cliente. Un borrado a medias deja restos sueltos.

Así que la limpieza se hará con un guion reproducible —copia de seguridad, borrado, verificación de
recuentos antes y después—, no a mano, para poder repetirla cada vez que empiece una tanda de
pruebas. Y con confirmación previa, porque es un borrado masivo.

La prueba que de verdad importa viene después: **atacar el sensor de un cliente y comprobar que no
aparece nada en los demás**. Para eso hace falta darle a cada cliente de prueba su propio puerto.

Queda escrito un guion de arranque para la sesión siguiente en `wiki/prompt-siguiente-sesion.md`, con
el diagnóstico ya hecho para no repetir la investigación.

Suite en 1387 pruebas verdes. — fable

## [2026-08-28] tooling | Puesta a cero reproducible + cliente de prueba con puerto propio
- Motivo: quedaban restos de sesiones anteriores (cebos desplegados, 1488 eventos, 1020 detecciones, 258 hosts en el Default) que impedían llevar control limpio de las pruebas de aislamiento. Iván pidió empezar de 0.
- Script nuevo: `scripts/puesta_a_cero.sh` (respaldo pg_dump verificado → TRUNCATE de 12 tablas de datos → limpieza de estado derivado en Redis por patrón → reinicio del engine → verificación a 0). Se distingue de `reset_clean.sh` (conserva cebos) y `clean_attack_audit.sh` (ataca acto seguido).
- Conserva por diseño: flocks (4), usuarios (1), `flock_assignments`, `notify_config` y `sensor_registry` (la atribución por puerto).
- Se vació también `console_audit` (623 filas) por decisión de Iván. Se eliminaron 2 `remote_sensors` zombis ("smoke-sensor", 10.0.0.99, de un smoke-test del 15-jun).
- Cliente de prueba: **Pruebita** recibe el sensor Modbus (:502) en `sensor_registry` + regla explícita `honeypot_id=modbus-canary-01 → Pruebita`. De paso se registró Prometheus (2113 → Default), cerrando parte del pendiente «eventos sin sensor».
- Prueba de humo de aislamiento (registrada en `wiki/registro-pruebas.md`): ataque Modbus al 502 → 10 eventos SOLO en Pruebita; `curl` HTTP al 80 → 5 eventos SOLO en Default; IR e Iván a 0 en todas las tablas. **Aislamiento correcto.**
- Respaldos generados: `backups/db/tartarus_pre_reset_20260828_1509.sql.gz` (antes de la prueba) y `_1516.sql.gz` (cierre a 0 absoluto).
- **Hallazgo metodológico:** contar eventos/detecciones por flock con dos `LEFT JOIN` encadenados da un producto cartesiano (vi «100/100» donde había 10). Para conteos por flock, subconsultas correlacionadas.
- Estado final: plataforma en 0, 8 sensores en `sensor_registry`, lista para la verificación de aislamiento real.
— claude

## [2026-08-28] tooling | Reinicio de fábrica + onboarding de un cliente desde cero
- Motivo: Iván quería la plataforma LITERAL de 0 (no solo datos: también los flocks de cliente y la flota de sensores) para recorrer el despliegue de un usuario nuevo y llevar seguimiento fino.
- Aclaración de fondo: los sensores de `sensor_registry` no son datos sobrantes; reflejan los contenedores de honeypot que corren de verdad. El engine re-siembra la flota base (5 Beelzebub + icmp) al arrancar si la tabla está vacía (`bootstrap_known_sensors`). Son infraestructura de plataforma, no de un cliente.
- Script nuevo: `scripts/reinicio_de_fabrica.sh` — deja estado de instalación nueva (solo Default + 6 sensores base, 0 datos, 0 reglas). Hermano de `puesta_a_cero.sh` (que conserva inventario). Respaldo `backups/db/tartarus_pre_fabrica_20260828_1552.sql.gz`.
- Onboarding de «Cliente Demo 01» por el flujo real del producto (API abierta en dev): crear flock → asignar el honeypot Modbus (:502) por regla `honeypot_id` → desplegar y asignar un cebo AWS.
- Aislamiento verificado en vivo (en `wiki/registro-pruebas.md`): el cliente recibió solo sus 10 eventos Modbus (0 fugas); SSH/TCP/HTTP/Prometheus cayeron todos en Default. Prometheus (2113), antes «sin sensor», ya atribuye.
- Al roadmap (radar de UX, feedback de Iván): color de timeline por severidad/riesgo por defecto (el mecanismo ya existe, `timeline.js:15-42`, pero el defecto es por protocolo y engaña); drill-down por interacción en la timeline (hoy el tooltip es por bucket); rediseño estético de la consola (se ve arcaica).
- Observación: Telnet (:23) devolvió `TIMEOUT_CONNECT` — no llegó ningún evento. Sumado al frente de fiabilidad de Beelzebub.
- Siguiente: integración API de GPT (AI Settings, bug ya diagnosticado) y fiabilidad de Beelzebub.
— claude

## [2026-08-28] fix | Cero real de Beelzebub + botón para borrar flocks desde el banner
- Motivo: Iván veía en Infraestructura «aún hay despliegue» (Salud de honeypots 322, DRAS «1 componente») pese a la base en 0. Aclaración: el 322 es el contador Prometheus interno de Beelzebub (desde su arranque), no la base; y los honeypots están rotulados COMPARTIDOS (infraestructura de plataforma, se ven en todo flock). La verdad es la BD (Persistido·BD 0).
- Arreglo de fondo: al borrar un flock quedaban huérfanas sus reglas de asignación (`flock_assignments` no tiene FK a `flocks`), así que el consumer seguía atribuyendo tráfico a un flock muerto. `delete_flock` ahora las borra en la misma transacción y recarga el caché del consumer. Test nuevo en `test_flocks.py`. Suite: 1388 verdes.
- Verificado en vivo: creado un flock con regla → borrado por el endpoint arreglado → 0 huérfanas. Limpiada la huérfana que había dejado el borrado previo de «Cliente Demo 01» (ese flock ya lo había borrado el botón viejo, dejando la regla colgando).
- Botón «🗑 Eliminar flock» añadido al banner del flock (antes solo estaba en la tarjeta del panel central); reusa `deleteFlock()`. `.btn-danger` en el CSS. Se ve con Cmd+Shift+R.
- Beelzebub reiniciado para poner a 0 el panel de Salud de honeypots. Estado final: 1 flock (Default), 0 reglas, 0 datos, 7 sensores base, embudo 0→0.
- Pendiente para la siguiente tanda: integración API de GPT (LLM del engine «ninguno configurado») y fiabilidad de Beelzebub (Telnet no llegó, canal AMQP, clave de host).
— claude

## [2026-08-28] fix | AI Settings: la clave del engine ya persiste al reinicio (punto 1 del roadmap)
- Motivo: se metía la clave de OpenAI en AI Settings, Test respondía «No AI provider configured», y tras reiniciar volvía a `template` en silencio.
- Causa confirmada en vivo: `ENV_FILE` caía en `/.env` (raíz del contenedor, no montada, que nadie lee) y el `LLMClient` lee las claves de `os.getenv` al arrancar; el guardado solo tocaba memoria. Además el `.env` de host ni siquiera tenía `OPENAI_API_KEY`.
- Arreglo: `AI_ENV_FILE=/app/.ai_runtime.env` (host `engine/.ai_runtime.env`, gitignoreado) en ruta montada RW; nuevo `load_ai_env()` que el engine llama al arrancar y vuelca las claves a `os.environ` antes de construir el cliente. Enfoque «releer al arrancar» — funciona con `docker restart`, sin `up` (sin riesgo para la BD).
- La consola no miente: `GET /settings/ai` expone `persisted`; el modal avisa «solo en memoria» si la clave no está en fichero.
- Beelzebub sync: el front dejó de llamar al endpoint deprecado (escribía `.env`, no-op) y ahora empuja la key al YAML de cada honeypot con LLM vía `/services/{file}/llm`, avisando del reinicio de Beelzebub.
- Test nuevo `test_settings_ai.py` (5 casos). Suite: 1393 verdes.
- Verificado en vivo: clave configurada → `docker restart` del engine → sigue `available:true, persisted:true`. Antes se perdía.
- **Hallazgo del lado de Iván (no es código):** las DOS claves de OpenAI del repo dan 401 (la de `Entrada/GPT.rtf`, 164 car., y la de los YAML del honeypot, 156 car., son distintas). OpenAI las rechaza. Para ver el Test en verde hace falta una clave válida nueva; esto también afectaría al LLM del honeypot. Dejé el fichero de runtime limpio (sin la clave muerta).
— claude

## [2026-08-28] fix | AI Settings: «Test» guarda la clave antes de probar, y el error deja de mentir
- Motivo: Iván pegó la API key, pulsó Test y salió «No AI provider configured». Los logs del engine lo confirmaron: 3 POST /settings/ai/test y 0 POST /settings/ai — o sea, Test no guarda; solo prueba lo ya guardado. Footgun de UX.
- Arreglo (front): `persistKeys()` compartida por Save y Test; Test la llama primero, así la clave recién pegada sí se prueba. Mensajes: «Pega una API key primero» si no hay clave; el error real si la hay.
- Arreglo (backend): `analyze()` se traga el 401 y cae a template, así que el Test devolvía un «warning» vago. Ahora, si el proveedor está configurado pero la respuesta vino de template, el endpoint devuelve error claro de clave inválida/sin saldo. Tests nuevos; suite 1395 verdes.
- Sigue pendiente del lado de Iván: una API key de OpenAI válida (las dos del repo dan 401). El Test ahora lo dice claro.
— claude

## [2026-08-28] feat | Honeypot SSH: el estado de sesión SÍ funciona (cd persiste entre comandos)
- Motivo: Iván probó `ssh -p 2222`, vio que `cd proyects` no daba error y `ls` siempre respondía igual, y concluyó que la herramienta «aún no funciona bien».
- Diagnóstico: esas respuestas eran handlers ESTÁTICOS del YAML (no el LLM). El `^cd → ''` se tragaba cualquier cd; solo el catch-all `^(.+)$` va al LLM. Y la clave del honeypot seguía siendo la de 401 (no se había sincronizado la válida del engine).
- Hallazgo que corrige el roadmap: «Beelzebub v3.9.0 no mantiene estado de sesión» era FALSO. Beelzebub sí pasa el historial al LLM; el problema eran los handlers estáticos. Verificado en vivo: enrutando `cd` y `pwd` al LLM, tras `cd projects` el `pwd` da `/home/admin/projects` y `cd ..` vuelve — el directorio PERSISTE.
- Hecho: (1) sincronizada la clave válida a SSH y Telnet (`/services/{file}/llm`); (2) quitado el `^cd → ''` estático → cd al LLM (ahora `cd inexistente` da error real); (3) `pwd` al LLM (estado) + prompt mejorado con la lista de directorios existentes; (4) `ls` se deja estático (el LLM lo hacía mal). El prompt mejorado se versionó en `services.example/ssh-22.yaml` (sin clave); el `services/` real está gitignoreado.
- Límites honestos: el LLM es ~90% consistente (alguna vez erra un cd a un dir real, o mete un espacio); `ls` no refleja el CWD (estático); la clave de host SSH sigue sin persistir (aplazado). Suite 1395 verde.
— claude

## [2026-08-28] feat | Cimientos del despliegue: honeypot SSH que funciona + flock opt-in + diseño
- Motivo: Iván probó SSH y `ls -las` daba «command not found»; y planteó un tema de producto mayor: Beelzebub aparece «desplegado por default» sin preguntar, cuando quizá solo quiere canary tokens. Quiere un flujo opt-in guiado estilo Thinkst y menos ruido en pestañas. «No soltarlo hasta que funcione.»
- Realidad de fondo (aterrizada en el diseño): Beelzebub es UNA instancia compartida; el engine no puede crear contenedores por cliente (C4). «Desplegar en un flock» = asignar puertos del lab compartido + cebos/honey-creds por-flock + sensores remotos enrolados.
- Hecho: (1) honeypot SSH robusto — dos handlers de `ls` deterministas (largo si flags con `l`, simple si no); verificado por SSH con estado de sesión (`cd`/`pwd`). (2) Separación opt-in en el hub: «Laboratorio compartido (Beelzebub)» vs «Sensores de este cliente»; badge «Opt-in · nada por defecto»; un flock nuevo no aparenta desplegar Beelzebub. (3) `wiki/diseno-despliegue.md`: modelo, manual vs recomendado, spec del flujo «+ Añadir» tipo Thinkst, personalidad del sensor, y recortes de ruido de las 4 pestañas.
- Decisiones de Iván: flock vacío/opt-in; esta tanda cimientos+diseño; mantener 4 pestañas quitando ruido.
- Diferido (especificado): construir el flujo «Añadir» + activación opt-in de protocolos; recortar ruido de pestañas; persistir clave de host SSH; versionar la config rica keyless.
- Nota: la config real `services/ssh-22.yaml` está gitignoreada (clave), así que el arreglo de `ls` no se commitea ahí; queda en local.
— claude

## [2026-08-28] feat | Honeypot SSH con estado real: cd/ls/pwd coherentes
- Motivo: tras `cd projects`, `ls` seguía mostrando el home (ls era estático; cd/pwd sí tenían estado). Iván: «debería actuar como Ubuntu real». Y las casillas Host/API key del modal confundían.
- Causa de que el prompt «se revirtiera» antes: al «Aplicar a este servicio» se copia el prompt de la PERSONA (`personalities/ubuntu-server.yml`, versionada) al YAML, machacando ediciones a mano. Solución: el prompt bueno va en la persona.
- Lo que funcionó (verificado en vivo, varias sesiones frescas): enrutar cd/pwd/ls al LLM (quitados los handlers estáticos de ls) + prompt con árbol de ficheros explícito + regla de cd PERMISIVA desacoplada del árbol + regla de arranque en /home/admin + modelo gpt-4o. gpt-4o-mini NO era capaz (rechazaba cd válidos, fallaba ls). `apply` conserva modelo/clave.
- Resultado: pwd=/home/admin al entrar; cd projects → ls muestra webapp/api-gateway/...; cd /var/log → sus logs; cd proyects → error. Coherente.
- Límites honestos: ~95% (glitch puntual, sobre todo el 1er comando); el estado se arrastra entre reconexiones de la MISMA IP (Beelzebub guarda historial por IP, reinicio lo resetea; IPs distintas aisladas); gpt-4o cuesta ~15× más que mini. Para 100% determinista → Cowrie (agendado).
- Modal: Host/endpoint + API key bajo toggle «Avanzado» (ocultos por defecto). Test de UI actualizado. Suite 1395 verde.
- Nota: el YAML real (con clave y comandos estáticos) sigue gitignoreado; se versiona el prompt en la persona y la plantilla `services.example` (sin clave).
— claude

## [2026-08-28] feat | Entornos de deception generados por IA (a medida del cliente)
- Motivo: Iván quiere explotar la ventaja de la IA para crear entornos completamente creíbles y personalizados al cliente (como el File Share de Thinkst, que lo hace estático). Ref: `Archivos_ejemplo/Canary Console opciones en protocolos.pdf`.
- Hecho: `POST /personalities/generate-scenario` — describes al cliente (industria, datos) y gpt-4o genera un prompt de shell SSH a medida (hostname, árbol de ficheros del negocio, contenidos, reglas con estado + anti-detección). No aplica nada: se prueba con el banco `probe`, se ajusta y se guarda como persona. UI: botón «✨ Generar entorno con IA» en el editor de personas. Añadido override de modelo en `llm_client.analyze(model=)`.
- Verificado en vivo: contexto «ACME Electrónica, sensores industriales» → entorno con sensor_firmware/, plc_configs/, scada_dashboards/, bom_october.pdf, supplier_contracts/. Base enriquecida: `cat backup.sh` → script realista; `cat auth.log` → log con timestamps.
- Realidad honesta: el SSH es compartido, así que el escenario es global (un tema a la vez). Per-cliente simultáneo necesita un SSH por flock en su puerto (rango pre-publicado + flujo «+ Añadir») — agendado en diseno-despliegue §9, es la tanda de despliegue.
- Test nuevo `test_generate_scenario.py`. Suite 1400 verde. El generador NO toca claves; el YAML real sigue gitignoreado; el prompt (sin clave) se versiona en la persona y en services.example.
— claude

## [2026-08-28] fix+feat | ls consistente y modal SSH como hub de personalidades
- Motivo: Iván vio que `ls` y `ls -lsa` mostraban entradas distintas (p.ej. `ansible` aparecía en uno y no en otro) y que la personalidad a medida no se veía; y pidió que el modal de configurar SSH sea el sitio para ver/elegir/generar/editar/aplicar las personalidades de SSH.
- ls: el árbol del prompt ahora marca carpetas con `/` y ficheros sin barra, con la regla de que las entradas de un directorio son FIJAS entre formatos; `cd` a fichero da `Not a directory`; `cd` sigue permisivo (multinivel, `..`, absolutos). Verificado: ls/ls -lsa iguales, cd entra en carpetas y falla en ficheros.
- Modal SSH: nuevo bloque «✨ Generar personalidad a medida (IA)» — describes al cliente + nombre → genera (gpt-4o) → crea la persona → la selecciona → Aplicar. Reusa el generador, `POST /personalities`, `_idDesdeNombre` y `_loadServicePersonas`. Verificado E2E (ls tematizado a electrónica).
- Trampas se deja como está por ahora (decisión de Iván). HTTP a probar después. Suite 1400 verde. El prompt se versiona en la persona y en services.example; el YAML real sigue gitignoreado.
— claude

## [2026-08-28] fix+feat | La persona a medida ya se aplica de verdad + dirección del árbol
- Motivo: Iván generó una persona (RH electrónica), guardó y aplicó, y la shell no la reflejaba (seguía prod-web-01, mismos errores).
- Causas: (1) «Aplicar» no reiniciaba Beelzebub (paso aparte); (2) 61 comandos estáticos fijaban prod-web-01 y ganaban sobre el LLM; (3) el prompt generado no llevaba las reglas afinadas.
- Hecho: (1) Aplicar/Guardar reinician Beelzebub solos (watchdog ≤60s); (2) SSH LLM-first: quitados los 61 estáticos, el prompt de la persona controla todo; (3) generador robusto = escenario (LLM) + reglas fijas afinadas; (4) el contexto de generación se guarda en la persona («Generado para: …»). Verificado E2E: persona RH → hostname RH-Server-Electro, whoami jlopez, ls = árbol RH, ls==ls -lsa. Suite 1400 verde.
- Dirección de fondo (de Iván): árbol de ficheros estático editable + plantillas por industria/departamento + LLM encima («estáticos + a medida», Thinkst con IA). Diseñado en diseno-despliegue §10, a construir por fases.
- Pendiente menor: el banner SSH usa serverName del YAML (no cambia con la persona) → tematizarlo también.
— claude

## [2026-08-28] cierre | Fin de sesión: honeypot SSH creíble; pendiente realismo + constructor por árbol
- Resumen de la sesión (larga): puesta a cero + reinicio de fábrica reproducibles; despliegue opt-in (lab compartido vs cliente); AI Settings arreglado (clave persiste, Test honesto); honeypot SSH con estado real (cd/ls/pwd, ls==ls -lsa) LLM-first con gpt-4o; sistema de personas + generador de entornos por IA (escenario + reglas fijas); «Aplicar» reinicia Beelzebub solo. Suite 1400 verde. Sin push (todo local).
- Iván probó y detectó tells de realismo: la clave de host SSH cambia en cada reinicio (REMOTE HOST IDENTIFICATION HAS CHANGED); `cat` de PDF salió meta; `nano` no existía; una empresa hospitalaria CDMX generó documentos en inglés y estructuras sin sentido; el banner sigue prod-web-01.
- Visión de producto de Iván: constructor de entornos por ÁRBOL — menús desplegables de industria+departamento (catálogo definido por nosotros) + una barra de personalización; vista de árbol editable + shell de prueba al lado; plantillas base por industria/departamento; integración con canary tokens (ubicarlos en el árbol para que el atacante los recolecte); control de timestamps; máximo realismo.
- Se cierra para continuar en una conversación nueva. Prompt de arranque detallado en `wiki/prompt-siguiente-sesion.md`; pendiente ordenado en `.agents/ROADMAP.md` (Parte A realismo, Parte B constructor por árbol); plan archivado en `wiki/planes/2026-08-28.md`.
— claude

## [2026-08-28] plan | Parte A: realismo del shell SSH
Plan aceptado archivado en [[planes/2026-08-28]]. Cierra seis "tells" del honeypot SSH: persistir la
clave de host de Beelzebub (parche + imagen local), inyectar las reglas del shell al aplicar/probar,
volcado de binarios, editores/pagers, locale por país/industria, serverName a medida y época de ficheros.
— claude

## [2026-08-28] ingest | Parte A ejecutada: realismo del shell SSH (6 ítems + refactor)
- Repo Tartarus: commits `da5497b` (clave de host) y `b9e93b9` (realismo del shell). Suite 1418 verde.
- **Clave de host persistente**: Beelzebub v3.9.0 no lo admite por config → parche mínimo
  (`beelzebub/build/beelzebub.patch`) + imagen local `tartarus-beelzebub:v3.9.0-hostkey`; claves
  ed25519+rsa en el host (`make ensure-hostkeys`), distintas por nodo; `push-to-rpi.sh` blindado.
  Verificado: huella estable tras 2 reinicios; reconexión estricta sin «REMOTE HOST IDENTIFICATION
  HAS CHANGED».
- **Reglas inyectadas, no congeladas**: módulo `engine/engine/ssh_rules.py`; la persona guarda solo el
  escenario, `apply`/`probe` anteponen reglas frescas. Gate `rules_profile: bash` protege las personas
  SSH no-bash. Ítems cubiertos: binarios (`%PDF`), editores/pagers + toolkit (0 «command not found»),
  locale español por industria, `serverName` a medida (`mariana@hr-dept-srv01`), época/TIMELINE.
- Pendientes anotados: techo ~90-95% del LLM (glitches `less (END)` / «Is a directory» esporádicos →
  Parte B), tells que necesitan más parche (`:~$` fijo, usuario del prompt = login), y que el SSH vivo
  quedó con la persona hospital aplicada.
- Páginas: `wiki/roadmap-operativo.md` (sincronizado con `.agents/ROADMAP.md`), `wiki/planes/2026-08-28.md`
  (plan archivado antes de ejecutar).
— claude

## [2026-08-28] ingest | Parte A.2: correcciones y UX tras probar (shell navegable, diálogos, generador)
- Repo Tartarus: commit `0558613`. Suite 1425 verde.
- **Shell de prueba navegable**: `llm_client.analyze` acepta `history`; `/probe` la reenvía; la UI es un
  mini-terminal con estado. `cd`/`ls`/`cat` navegan de verdad (antes cada comando era aislado).
- **Diálogos propios en toda la app**: fuera los `confirm/alert/prompt` nativos; `confirmDialog`,
  `promptDialog`, `showToast` (~44 reemplazos).
- **Aplicar en un clic**: botón «Guardar y aplicar»; `applyPersonality` avisa que el reinicio cierra las
  sesiones SSH y hace un solo reinicio. La sesión que se caía «sola» a los ~18 s era ese reinicio (no
  timeout: `deadlineTimeoutSeconds` es 600).
- **Generador más claro**: campo «Detalles / archivos y fechas» → `SPECIFIC REQUIREMENTS`; descripción
  corta ya no vuelca el contexto entero; etiquetas por pasos. Verificado en vivo: `nomina_marzo_2019.xlsx`
  en `/home/juan/finanzas` con fecha 2019.
- Pendiente P1 anotado: Parte B (árbol determinista con ruta/fecha por archivo; base `INDUSTRY_SEEDS` +
  `TOKEN_CATALOG`).
- Páginas: `wiki/roadmap-operativo.md` sincronizado; plan en `wiki/planes/2026-08-28.md`.
— claude

## [2026-08-29] plan | Parte A.3: entorno con cebo, pulido de realismo, latencia y ancho de UI
Plan aceptado archivado en [[planes/2026-08-29]]. Enriquecer el entorno del honeypot para que sea cebo
de verdad (denso, malas prácticas evidentes, archivos que se relacionan, find/grep/locate con morbo y
adaptación) + arreglar los tells que quedan (cd→«ls», fugas `<|disc_score|>` en binarios, archivo-vs-
carpeta, clave de host, latencia sin cambiar modelo, ancho del editor estilo Thinkst).
— claude

## [2026-08-29] ingest | Parte A.3: entorno con cebo + pulido de realismo
- Repo Tartarus: commit `2402aa5`. Suite 1427 verde. Verificado en vivo.
- **Entorno con cebo**: META_SSH genera árboles densos (4-12 entradas/carpeta, varios usuarios) con
  malas prácticas evidentes (id_rsa, .env/config.php con credenciales, dump.sql, .bash_history con
  `mysql -uroot -p..`/`scp id_rsa`, cron con secretos), archivos que se referencian entre sí, y
  taxonomía de interés (básico/experto/IA). find/grep/locate sacan el cebo a la luz y se adaptan.
- **Tells**: cd exitoso ahora es salida vacía (no «ls»); binarios acotados y sin `<|disc_score|>`;
  tipo fichero/carpeta fijo por sesión.
- **Latencia**: reglas condensadas + salidas cortas, sin cambiar de gpt-4o (~0.7-1.4s/comando).
- **Clave de host**: up/up-quick ya no corren clean-ssh (la huella persiste) + guardia check-bee-image.
- **UI**: editor de persona ancho (estilo Thinkst) con metadatos a 2 columnas; prompt del banco sin el
  punto de más.
- Pendiente: Parte B (constructor visual por árbol; navegación determinista; cebo→canary token real).
- Páginas: `wiki/roadmap-operativo.md` sincronizado; plan en `wiki/planes/2026-08-29.md`.
— claude

## [2026-08-29] plan | Parte A.4: última pasada al shell LLM + UI + persona Windows
Plan aceptado archivado en [[planes/2026-08-29]]. Arreglar por prompt los bugs discretos del shell
(token suelto→command not found no «cd:», fechas reales, idioma solo en contenido, consistencia,
cobertura de comandos + búsqueda), entorno menos predecible (usuarios aleatorios, cebo enterrado/sutil,
coherencia de negocio), persona Windows rica, y UI (un botón de guardar, quitar campo industria, prompt
más grande). El filesystem determinista (cwd/consistencia al 100%) queda para la Parte B.
— claude

## [2026-08-29] ingest | Parte A.4: última pasada al shell LLM + UI + persona Windows
- Repo Tartarus: commit `d6a0c61`. Suite 1429 verde. Verificado en vivo.
- **Comandos bash**: solo `cd` da errores de cd (token suelto/`..` → command not found); cwd riguroso;
  fechas concretas (no `fecha_modificación`); herramientas/errores en inglés (idioma solo en contenido);
  consistencia dura; cobertura ampliada de búsqueda/análisis.
- **Aleatoriedad**: el engine impone nº de usuarios 2-6 (gpt-4o gravitaba a 3). Cebo enterrado y sutil;
  coherencia de negocio estricta.
- **Windows**: persona rica (árbol C:\, dominio, cebo unattend.xml/web.config/PS history/SAM, reglas
  PowerShell/cmd). Repaso ligero de los otros appliances.
- **UI**: un botón de guardar (Cancelar + Guardar y aplicar); quitado el campo industria redundante;
  prompt más grande.
- Nota honesta: cwd/consistencia mejora pero ~85-90% (techo LLM); el 100% es la Parte B (filesystem
  determinista, engine como host LLM de Beelzebub).
- Páginas: `wiki/roadmap-operativo.md` sincronizado; plan en `wiki/planes/2026-08-29.md`.
— claude

## [2026-08-29] plan | Parte A.5: FHS real + personas estándar/reset + falsos positivos
Plan aceptado archivado en [[planes/2026-08-29]]. Que el shell trate el honeypot como un Ubuntu REAL
(todo el FHS existe; el árbol de negocio se añade encima) — arregla el bug raíz de que rechazaba
/tmp, /home, /var. Personas estándar genéricas por default + botón «Reset a estándar» (el editor
sobrescribía el catálogo). Más contenido y requisitos quirúrgicos. Falsos positivos: correr la purga
del ruido histórico (dry-run) + cerrar la sonda del health worker sobre :8080 + filtrar el recon pelado
del timeline. Filesystem determinista sigue siendo Parte B.
— claude

## [2026-08-29] ingest | Parte A.5: FHS real + personas estándar/reset + falsos positivos
- Repo Tartarus: commit `bf003de`. Suite 1431 verde. Verificado en vivo.
- **Shell = Ubuntu REAL**: todo el FHS existe con contenido estándar (arregla que /home,/tmp,/var,/etc
  «no existían»); /tmp con contenido; cd .. sube; sin fugas <|...|>; pipes. (cd .. hacia arriba aún
  falla a veces = techo LLM → Parte B.)
- **Personas estándar + Reset**: ubuntu-server ahora genérico (srv-app-01); baselines en _standard/;
  endpoint /{id}/standard; botón «Reset a estándar»; la IA en el editor crea persona derivada, no pisa
  el base.
- **Falsos positivos**: purga interna ya da 0 (BD limpia); health worker deja de sondear los puertos de
  ataque de Beelzebub (solo métricas :2112); histograma oculta handshakes pelados (New %) por defecto
  (360 vs 531). Los correos ya no se disparaban; el asistente no registra sus cambios (pega al engine,
  no al honeypot). Pendiente: política del gateway .1 y taxonomía TCP/TCP-HTTP.
- Páginas: roadmap-operativo sincronizado; plan en planes/2026-08-29.
— claude

## [2026-08-29] plan | Parte B (Fase B1): engine como cerebro determinista del honeypot
Plan aceptado archivado en [[planes/2026-08-29]]. Arranca la Parte B: el engine se vuelve el «host» LLM
de Beelzebub y resuelve `cd`/`ls`/`pwd`/`find`/`cat` EN CÓDIGO desde el árbol (parseado del escenario);
el LLM solo genera contenido (cacheado en Redis). Cierra de raíz la queja #1 de todas las rondas: la
consistencia del filesystem. Repo al momento: `bf003de`.
— claude

## [2026-08-29] plan | Parte B (Fase B7b): el motor de comandos de Windows
Plan aceptado archivado en [[planes/2026-08-29]]. Segunda mitad de B7: que `cd`/`dir`/`type` se resuelvan
en código para Windows, con carpetas base propias, verbos de sistema y el prompt `PS C:\...>` (que obliga
a ampliar el parche de Beelzebub y reconstruir su imagen). El inventario destapó cuatro trampas: `dir` ya
está registrado apuntando al `ls` de Linux (en cuanto el gate distinga dialectos imprimiría formato POSIX
dentro de un Windows); las carpetas base de Ubuntu se siembran sin condición; el índice del árbol no
pliega mayúsculas (`cd c:\users` fallaría, y afecta a la clave del canario); y `pushd`/`popd` romperían
el contrato que consumen 16 manejadores. Repo: `ebc2f6d`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B7a HECHA: cimientos de Windows + editor de config
Implementada y verificada. Nuevo `tree_grammar.py`: la gramática del árbol vivía duplicada en dos módulos
(~174 líneas) y ya había divergido; ahora es una sola, con sabor POSIX o Windows, y se comprobó byte a
byte que el resultado en Linux no cambia (de ese texto salen las huellas que mantienen vivos los canarios
de B3). Arreglado el bloqueante: `shlex` trataba `\` como escape y destruía las rutas `C:\`. El árbol de
Windows ya se parsea (66 nodos, con `Program Files`, PSReadline y SAM) y sus canarios se aprovisionan por
la rama correcta — B6 había dejado un discriminador binario que los mandaba a la rama de router. Y se
cierra el pendiente de B6: editor visual de configuración para Cisco/FortiGate. Suite 1646 verde; shell
Linux sin regresión. Detalle en [[roadmap-operativo]] (29-ago, Fase B7a). Pendientes: B7b y B5b.
— claude

## [2026-08-29] plan | Parte B (Fase B7a): cimientos de Windows + editor de configuración
Plan aceptado archivado en [[planes/2026-08-29]]. B7 va en dos partes; esta ronda son los CIMIENTOS
(el motor de comandos queda para B7b). Incluye un bloqueante que nadie había visto: `shlex.split` trata
la barra invertida como escape, así que `cd C:\Users\x` llega al motor como `C:Usersx` — sin arreglarlo
nada de Windows funciona. También se unifica la gramática duplicada (~174 líneas repetidas, ya con
divergencia real) ANTES de extenderla, sin cambiar un byte de la salida POSIX para no invalidar los
canarios de B3. Y se corrige una trampa introducida en B6: `canary_tree` usa «empieza por /» para decidir
si un canario es de árbol o de aparato, así que una ruta Windows caería en la rama del router — no falla,
aprovisiona mal. De paso se cierra el pendiente de B6: el editor visual de configuración en la interfaz.
Repo: `dff6531`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B6 HECHA: la config del aparato como «árbol»
Implementada y verificada. Lo primero fue medir: `show running-config` estaba ROTO (respondía comando
inválido incluso con privilegios) y la tabla de interfaces cambiaba entre llamadas, porque el escenario
daba un resumen en prosa. Ahora la configuración va LITERAL (115 y 149 líneas): el volcado sale idéntico
las tres veces y termina en `end`. Nuevo `config_serde.py` (hermano de filetree_serde, pero preservando
el ORDEN, que en una config es semántico) + endpoints configtree + detección de líneas con secreto. Y
canarios en la configuración: cada línea marcada recibe un secreto único con su regla; reusarlo dispara
alerta crítica. El secreto vive solo en el fichero del servicio, nunca en el de la persona (C5). Suite
1610 verde. Detalle en [[roadmap-operativo]] (29-ago, Fase B6). Pendientes: editor de config en la UI,
B7 (Windows) y B5b.
— claude

## [2026-08-29] plan | Parte B (Fase B6): los aparatos de red, con su config como «árbol»
Plan aceptado archivado en [[planes/2026-08-29]]. Respuesta a «¿en qué punto entra el árbol de archivos
en las demás personalidades?»: Windows sí tiene filesystem literal (va a B7, con sus 7 frentes ya
inventariados); Cisco y FortiGate NO son shells — su equivalente es la CONFIGURACIÓN. Medido en vivo:
`show running-config` está ROTO (responde `% Invalid input` incluso en privilegiado) y
`show ip interface brief` cambia entre llamadas, porque el escenario le da al LLM un resumen en prosa y
le exigimos repetir un texto que nunca le dimos. La fase: config literal + editor visual de config +
canarios reales en las líneas de secreto (hoy la PSK de la VPN está en claro, sin token ni alerta).
Sin motor determinista. Repo: `422f154`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B5a HECHA: las otras personalidades al nivel del Linux
Implementado y verificado en vivo. Nuevo `engine/engine/cli_profiles.py` con cuatro familias de reglas
(bash/ios/fortios/powershell) y `ssh_rules` como fachada. Jenkins y Synology, que son shells Unix reales,
pasan a perfil bash y heredan de golpe el motor determinista, el editor de árbol, los canarios y el prompt
con ruta (verificado por SSH real). Cisco y FortiGate reciben reglas de su propio CLI (modos, config
estable, errores literales, cebo del aparato); Windows saca sus reglas del YAML al código; el telnet queda
alineado y también recibe reglas y comandos. Los tests cazaron un bug serio: los marcadores nuevos
contenían al de bash, con lo que un FortiGate encendía el motor POSIX. Suite 1567 verde, sin regresión en
Linux. Detalle en [[roadmap-operativo]] (29-ago, Fase B5a). Pendientes B6 (Windows determinista) y B5b.
— claude

## [2026-08-29] plan | Parte B (Fase B5a): las otras personalidades al nivel del Linux
Plan aceptado archivado en [[planes/2026-08-29]]. Jenkins y Synology son shells Unix REALES sin ninguna
regla → pasan a perfil bash con escenario denso y heredan de golpe el motor determinista, el editor de
árbol, los canarios y el prompt con ruta. Cisco y FortiGate reciben reglas propias de su CLI (modos,
running-config estable, errores literales, cebo del aparato). Windows: sus reglas pasan del YAML al
código. Y se arregla el telnet, que es un router escrito a mano que contradice a la persona cisco-ios.
Pieza de arquitectura: registro de perfiles con marcador por familia, manteniendo el motor determinista
atado SOLO al marcador bash (para que un router no responda POSIX). B6 (Windows determinista) y B5b
(filetree ZIP fusionado con el bundle) quedan registradas. Repo: `9ccb045`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B4 HECHA: el shell se siente real
Implementado y verificado en vivo por SSH real. `cd` ya no deja línea en blanco y el prompt sigue la ruta
(`admin@srv:~/documentos$`): ambos requerían parchear Beelzebub — nuevo `beelzebub-shell-prompt.patch` que
aplica en cadena tras el de clave de host (imagen `v3.9.0-tartarus`; fingerprint intacto). El cwd lo manda
el engine fuera de banda, NEGOCIADO, para no filtrarlo a sensores sin parchear (0 eventos con el marcador).
Contraseña de entrada configurable desde la UI (4 modos, `passwordRegex`, con escape verificado). Carpetas
base pobladas y ficheros de sistema con contenido horneado del escenario (sin LLM, coherentes con `id`) y
permisos canónicos. Suite 1539 verde. Detalle en [[roadmap-operativo]] (29-ago, Fase B4). B5 registrada:
personalidades no-Linux + filetree ZIP.
— claude

## [2026-08-29] plan | Parte B (Fase B4): el shell se siente real (prompt, cd, contraseña, carpetas base)
Plan aceptado archivado en [[planes/2026-08-29]]. Cuatro fallos vistos en vivo: `cd` imprime línea en
blanco y el prompt no sigue la ruta (ambos son de Beelzebub: `ssh.go:155` y el `:~$` literal de
`buildPrompt` → se amplía el parche de la imagen); no se puede fijar la contraseña (`passwordRegex` ya
soporta los 3 modos); y las carpetas base están vacías (sin `/opt`, `/srv`, `/home`, `/tmp` pobre, y
ningún fichero de sistema con contenido horneado). El prompt se sincroniza con un marcador fuera de banda
NEGOCIADO (para no filtrarlo a sensores con imagen sin parchear). B5 registrada: personalidades no-Linux
+ filetree ZIP. Repo: `3e4476e`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B3 HECHA: canary REAL en el árbol, ambos disparos
Implementado y verificado end-to-end por SSH real. Nuevo `engine/engine/canary_tree.py` (aprovisiona al
aplicar: secreto único + regla `decoy_reuse` + fila en consola + siembra en Redis); `shell_brain._content`
sirve el honeytoken; `apply_personality` recibe `request` y llama a provision (`canaries_armed`). Verificado:
`cat /opt/app/.env` muestra `CANARY-DECOY-JWT-<uid>`; el reuso (curl) dispara CRÍTICO y la LECTURA también
(Beelzebub mete la respuesta en el payload) — ambos sin código extra; notificación por el consumer. Suite
1493 verde. Detalle en [[roadmap-operativo]] (29-ago, Fase B3). Registrada Fase B4 (filetree ZIP) como P1.
— claude

## [2026-08-29] plan | Parte B (Fase B3): canary REAL en el árbol del honeypot
Plan aceptado archivado en [[planes/2026-08-29]]. Vuelve REALES los nodos marcados canary en B2: al
aplicar la persona, cada uno siembra un secreto único (que el `cat` sirve vía Redis) y registra la regla
`decoy_reuse`; el reuso dispara detección CRÍTICA + notificación (ya llega sola por el consumer). Ambos
disparos (reuso + al leer). El filetree ZIP se registra como Fase B4 (no se abandona). Repo: `0d37e2d`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B2 HECHA: constructor visual por árbol
Implementado y verificado end-to-end. Nuevos `engine/engine/filetree_serde.py` (parse⇄serialize del árbol,
round-trip estable, preserva cebo/Users verbatim) y `filetree_templates.py` (4 plantillas curadas);
endpoints `/personalities/filetree/{parse,serialize,template,templates}` + `department` en generate-scenario.
UI: editor visual de árbol en el editor de persona (colapsable, añadir/renombrar/borrar/canary, toggle
texto crudo), desplegables industria×departamento (8×6) y botón «Plantilla base». El texto del prompt
sigue siendo la fuente de verdad; el motor B1 no se tocó. Suite 1485 verde. Detalle en [[roadmap-operativo]]
(29-ago, Fase B2). Pendiente: smoke test visual en navegador y B3 (canary real en el árbol).
— claude

## [2026-08-29] plan | Parte B (Fase B2): constructor visual por árbol + catálogo industria×departamento
Plan aceptado archivado en [[planes/2026-08-29]]. Siguiente fase de la Parte B: editor VISUAL del árbol
(estilo Thinkst) con shell de prueba al lado (ya existe, pega a B1), desplegables industria×departamento
(8×6, confirmado), plantillas curadas + IA rellena. El texto del prompt sigue siendo la fuente de verdad:
el editor parsea/serializa el bloque FILESYSTEM sin tocar el motor B1. B3 (canary real en el árbol) queda
para la siguiente ronda (el nodo lleva flag canary preparado). Repo al momento: `64e64da`.
— claude

## [2026-08-29] bitacora | Parte B · Fase B1 HECHA: filesystem determinista, verificado en vivo
Implementado y verificado por SSH real. Nuevos `engine/engine/shell_brain.py` (parser del árbol + FHS base
+ replay del cwd + resolutor determinista + cache de contenido en Redis + fallback) y
`engine/engine/openai_shim_router.py` (`POST /v1/chat/completions`, ignora Authorization/stream). El banco
(`probe`) usa el mismo cerebro; `services/ssh-22.yaml` apunta al engine (`set_llm`). Resultado: navegación
100% consistente (incl. `cd ..` desde `/`), `ls`/`cat` idénticos entre llamadas, `cat` cacheado; latencia
de `cd`/`ls`/`pwd` 2.5–5 ms (antes ~1-2 s). Suite 1466 verde. Detalle en [[roadmap-operativo]] (29-ago,
Fase B1). Pendiente: toggle de UI (hoy se revierte con `set_llm(host="")`), fases B2 (constructor visual)
y B3 (canary en el árbol).
— claude

## [2026-08-30] plan | B9 bloque 2: cerrar la fuga de datos entre clientes
Plan aceptado archivado en [[planes/2026-08-30]]. Medido en vivo antes de planear nada, con dos clientes
en la base —«Default Flock» con 910 eventos e «Iván» con cero—, así que cualquier cifra distinta de cero
pedida como «Iván» es una fuga demostrada. El hallazgo que cambia el plan de partida: **el backend está
mucho mejor de lo que creíamos y la consola mucho peor**. Informe de engagement, notificaciones, WebSocket
y el repintado al cambiar de cliente ya estaban resueltos en el servidor; el agujero se movió a la
interfaz, que de sus 132 llamadas solo añade el cliente en 12 — el informe que se ENTREGA al cliente se
pide sin él y trae 910 eventos ajenos (con el cliente puesto trae 0). La otra mitad son 129 rutas que ni
siquiera pueden aceptar el parámetro, aunque 6 de sus 7 consultas pesadas ya sepan filtrar: ahí es pasarlo,
no reescribirlo. Lo peor suelto: `/iocs/extract` (100 hashes, 100 comandos, 12 URLs y 50 credenciales de
otro cliente), `/detections` (434), `/audit` (587 acciones) y los memos de analista, que además son
escritura cruzada y su borrado ni comprueba el rol. Dos hallazgos nuevos que no estaban en el plan de
partida: `hosts.ip` y `uq_honey_creds_combo` son ÚNICOS globales —dos clientes no pueden tener el mismo
host ni la misma credencial trampa—, y conviven tres semánticas incompatibles del cliente por defecto que
hay que unificar antes de tocar nada. Cuatro decisiones tomadas por el usuario: migrar `console_audit` de
verdad, omitir los contadores globales cuando hay cliente, dejar el WebSocket fuera del bloque (la consola
ya no lo usa: 0 conexiones) y enmascarar la configuración de avisos heredada. Suite de partida: 1734 verde.
Repo: `0633b61`.
— claude

## [2026-08-30] plan | B9 bloques 3 y 4: el ping y el honeypot web
Plan aceptado archivado en [[planes/2026-08-30]]. Al medir contra el sistema antes de planear, **dos
premisas del plan de partida se cayeron**, y no eran detalles. El **respondedor ARP con scapy no
existía**: no está en el árbol, ni en el historial, ni en ninguna de las 21 ramas, ni en el stash, ni
dentro del contenedor — así que no hay nada que «recuperar», hay que escribirlo. Y el **laberinto
anti-escáner tampoco era una regresión del 29-ago**: `MazeHoneypot` no aparece en ningún YAML
commiteado en toda la historia del repo, y la propia auditoría del proyecto lo lista como «no usado».
Lo que sí existe son las 119 líneas de `maze_tagger.py` detectando hits contra un plugin que no está.

Las dos cosas encajan en el mismo patrón —se probaron en vivo y no se commitearon— y en el caso del
laberinto hay un mecanismo que lo explica y sigue activo: aplicar una persona HTTP borra el bloque
`commands` entero, así que cualquier cosa añadida al YAML desaparece en el siguiente apply. Por eso
ese arreglo va primero: sin él, lo demás se vuelve a perder igual.

Medido: el ping a la IP señuelo se pierde al 100% porque nadie contesta el ARP (por eso el sensor
lleva desde su creación con cero eventos); dentro del contenedor `ip_forward=1` y `send_redirects=1`,
que es lo que causaba el bucle de 227 paquetes y no el ARP; y las cuatro rutas del honeypot web
(`/`, `/admin`, `/.env`, `/wp-admin`) devuelven **el mismo cuerpo byte a byte**, igual que el señuelo
de Prometheus. En la base, 82 eventos en el puerto 80 contra 1 en el 443, porque el HTTPS se detecta
por un campo que llega vacío cuando el cliente se conecta por IP.

Cuatro decisiones tomadas: construir el laberinto por primera vez, fusionar en vez de sustituir en
`personality_engine`, escribir el respondedor ARP desde cero, y que el señuelo de Prometheus sirva
métricas falsas creíbles. Repo: `6a6c82b`.
— claude

## [2026-08-31] plan | Beelzebub al 100%, sensor por sensor
Plan aceptado archivado en [[planes/2026-08-31]]. Dejar MCP, HTTP/HTTPS, Telnet y TCP al 100%:
que el puerto que se ve sea el que se ataca, que HTTPS deje de registrarse como HTTP, que el
engaño no se delate por banner ni por prompt, y que las notificaciones salgan con el dato bueno.
— claude

## [2026-08-31] sesión | Beelzebub sensor por sensor: MCP, HTTP/HTTPS, TCP y notificaciones al 100%
Seis bloques cerrados y verificados en vivo: (1) el puerto que se ve es el que se ataca
(engine/puertos.py, host_port en /events y alertas); (2) HTTPS deja de registrarse como HTTP
—3 reglas Sigma ganaron 'HTTPS', las 6 de contains ya casaban—; (3) MCP guarda la herramienta
llamada en el comando y la batería ya manda inyección de prompt (dispara yara:AI_Prompt_Injection,
cierra el lab 20 a medias); (4) las fachadas web dejan de delatarse —una portada, un servidor por
familia (nginx/IIS), el cebo web sembrado sin duplicar— y quedan versionadas en seed_web_routes.py;
(6) el TCP contesta a lo que le llega (regex (?s), CRLF, cebo sin marca real), versionado en
seed_tcp_route.py; (7) las notificaciones ya no atascan la ingesta (salían en ~2 min por ráfaga,
ahora al instante) y un barrido web ya no manda un correo por petición (agrupa por protocolo).
Pendiente en su propia tanda: Telnet al 100% (parche de imagen para el prompt Cisco + generador del
telnet-23.yaml) y el resto de TCP. Suite 1903 verde, aislamiento 0 fugas, roles 37/37. 6 commits
sin subir (22 en total en la rama).
— claude

## [2026-08-31] plan | Incorporar el LLM a HTTP/HTTPS, TCP, MCP y Prometheus
Plan aceptado archivado en [[planes/2026-08-31]]. Llevar el patrón del shell SSH (reglas rápidas +
LLM para lo raro) a los protocolos que hoy son estáticos: el código pone el sobre del protocolo, el
LLM pone el contenido, Redis cachea, y ante fallo se cae a lo estático.
— claude

## [2026-08-31] sesión | El LLM llega a HTTP/HTTPS, MCP y Prometheus
Se llevó el patrón del shell SSH (reglas rápidas + LLM para lo raro) a los protocolos que eran
estáticos, con la regla de que el código pone el sobre del protocolo y el LLM el contenido. HTTP y
HTTPS generan páginas/APIs creíbles para rutas plausibles (escáner→sin LLM, barrido→laberinto);
MCP devuelve datos falsos por herramienta manteniendo el JSON-RPC exacto; Prometheus genera su API
de consulta dejando /metrics estático. Verificado en vivo por el honeypot real en los cuatro.
Piezas nuevas: engine/net_honeypot.py (común) y engine/web_honeypot_router.py. El LLM en TCP queda
fuera por una limitación de Beelzebub (LLMHoneypot solo soporta ssh/http; falla con «no prompt for
protocol selected») — cableado listo, pendiente parchear Beelzebub o servirlo como http. Suite 1925
verde, aislamiento 0 fugas. 5 commits más (27 sin subir en la rama).
— claude

## [2026-08-31] plan | Que el engaño no se delate: credibilidad, coherencia y personalidades por stack
Plan aceptado archivado en [[planes/2026-08-31]]. Cerrar los tells que descubrió Iván probando con
criterio de atacante: baliza canary visible, claves de ejemplo de AWS, datos incoherentes entre
endpoints, fechas de 2023, portada por defecto, personalidades por SO en vez de por stack web, y el
HTTPS/Prometheus rotulados como HTTP. Perfil de empresa único, honeytokens deterministas, y cinco
stacks web creíbles desde la raíz.
— claude

## [2026-08-31] sesión | Que el engaño no se delate: credibilidad y stacks web
Iván probó con criterio de atacante y salieron varios tells; todos cerrados y verificados en vivo:
(1) perfil de empresa único y determinista (engine/empresa_ficticia.py) que comparten todos los
backends LLM — se acabó el «dos dominios y los mismos tres nombres»; (2) prompts endurecidos (sin
ejemplo de AWS, sin example.com/192.0.2.x/555-01xx, fechas de 2026); (3) el MCP get-credentials
devuelve honeytokens deterministas rastreados (engine/honeytokens.py), no las claves de ejemplo de
AWS; (4) baliza canary disfrazada de pixel /assets/img/{hash}.svg relativo — el fuente ya no dice
canary/volcado/localhost:9000; (5) cinco stacks web (nginx+SPA, Apache+PHP, Tomcat/Spring,
WordPress, Portal .gob.mx) con fachada creíble desde la raíz, generación movida al engine
(web_facade.py) y apply que regenera la fachada al cambiar de stack; (6) HTTPS y Prometheus dejan de
rotularse «HTTP». Suite 1936 verde, aislamiento 0 fugas. 7 commits más (34 sin subir en la rama).
— claude

## [2026-08-31] plan | Clonar página real como personalidad + curar personalidad↔protocolo
Plan aceptado archivado en [[planes/2026-08-31]]. Dos features: (1) dar una URL, clonar su HTML
(con inline de CSS/imágenes) y usarlo como portada del stack elegido, sobre la maquinaria del
honeypot; (2) curar el catálogo para que cada protocolo ofrezca solo personalidades con sentido
(windows/ubuntu a solo SSH; fortigate/jenkins/synology a primera clase en HTTP) + guardarraíl.
— claude

## [2026-08-31] sesión | Clonar página real como personalidad + curar personalidad↔protocolo
Dos features verificadas en vivo: (1) dar una URL, clonar su HTML con CSS/imágenes incrustados y
servirlo como portada del stack elegido, sobre la maquinaria del honeypot (cloner.clonar_para_
personalidad + web_facade portada_html + endpoint /clone/web/apply + campo en la UI); formularios
al login del stack (sin el tell /tartarus/capture), SSRF-safe, fallback con gracia si el sitio
bloquea (Fonacot da 403 a un fetch). (2) Curación: windows/ubuntu a solo SSH, fortigate/jenkins/
synology a primera clase en HTTP, y guardarraíl que impide ofrecer un protocolo sin contenido.
Menú HTTP = solo web/appliances; SSH = shells; Telnet = cisco. Suite 1944 verde, aislamiento 0
fugas. 4 commits más (38 sin subir en la rama).
— claude

## [2026-08-31] plan | Cambiar el LLM a DeepSeek (OpenAI sin créditos)
Plan aceptado archivado en [[planes/2026-08-31]]. deepseek-chat (V3) es el modelo equivalente/mejor
que gpt-4o-mini y barato. El engine probaba OpenAI (clave muerta) primero por cascada; se añade
proveedor ACTIVO elegible y poder quitar una clave, en el cliente y la UI. Luego se retoma el
Bloque G (prompts editables por protocolo + fachada que no se delate) sobre DeepSeek.
— claude

## [2026-08-31] sesión | LLM cambiado a DeepSeek (OpenAI sin créditos)
deepseek-chat (V3) es el modelo equivalente/mejor que gpt-4o-mini y barato; reasoner (R1)
filtraría su razonamiento, así que chat es lo correcto. El engine elegía proveedor por presencia
de clave y probaba OpenAI (muerto) primero; ahora hay proveedor ACTIVO elegible (persistido en
TARTARUS_LLM_ACTIVE) que analyze prueba primero, y se puede quitar una clave. UI: selector de activo
+ botón Quitar + etiquetas de modelo DeepSeek. Verificado: DeepSeek activo (persiste al reinicio),
honeypot generando vía DeepSeek, 0 fallos de OpenAI. Nota: DeepSeek a veces antepone «.body:» a la
respuesta — se limpia en el Bloque G (prompts «output ONLY the body»). Suite 1949 verde.
— claude

## [2026-09-10] plan | familia weblogic y páginas de error por stack
Plan aceptado archivado en [[planes/2026-09-10]]. Añadir la familia `weblogic` (el 404 de
Oracle WebLogic que sirve el portal real de Fonacot) y conseguir que las diez familias de
`web_facade` sirvan cada una SU página de error, comprobado con un curl externo contra :8880.
Al medir salieron tres delatores más: jenkins anuncia Jetty y firma Tomcat, fortigate sirve la
maqueta de Apache diciendo «nginx», y las respuestas del motor salen SIN cabecera `Server`
(mientras las reglas estáticas sí la llevan), con 2 bytes de diferencia por un `TrimRight` del
parche de Go.
— claude

## [2026-09-10] plan | cuatro verbos deterministas más (ps, systemctl, crontab, ip)
Plan aceptado archivado en [[planes/2026-09-10]]. Pasar `ps aux`, `systemctl status`,
`crontab -l` e `ip a` del modelo al código. Medido en vivo antes de planear: el mismo
`crontab -l` contesta «no crontab for rrhh» en una pasada y lista dos tareas en la siguiente;
`ps aux` pierde `sshd` entre pasadas y su columna START cambia de idioma; y los cuatro tardan
1,3–2,7 s frente a los 0,04–0,13 s de un verbo determinista. La causa medida: lo que la persona
declara sale estable, lo que no declara se lo inventa el modelo cada vez.
— claude

## [2026-09-10] plan | el comparador de superficies y las personas web
Plan aceptado archivado en [[planes/2026-09-10]]. `comparar_superficies.py` da un 10/10 falso
en las 6 personas solo-web porque lee un `protocols.ssh.prompt` vacío y se lo manda igual al
editor de árbol, que contesta 400. Es el paso obligatorio de `verificar-protocolo`, así que un
tercio del catálogo está sin puerta de calidad. Se enruta por lo que la persona declara y se
añade la comparación de las tres superficies WEB (mapa de rutas, barrido interno, honeypot
desplegado), que hoy solo existía hecha a mano. Nota: la recomendación previa (las tuberías)
se descartó tras medirla — 7 de 1.013 comandos, el 0,5%.
— claude

## [2026-09-10] plan | tuberías y redirecciones en el SSH
Plan aceptado archivado en [[planes/2026-09-10]]. El arreglo de los verbos deterministas de
esta mañana afiló el motor y dejó al descubierto que canalizar contradice no canalizar: `ps aux`
dice PID 1676 y `ps aux | grep postgres` dice 892; `ls -a /etc` da 22 entradas y `ls -a /etc |
wc -l` responde 213. Las redirecciones son peor: `echo 'ssh-rsa…' >> authorized_keys` contesta
`/home/user` y el fichero nunca se crea, aunque `touch` sí persiste. Se corrige también el dato
que di al cerrar la sesión anterior: el «0,5% de comandos con tubería» salía de 1.013 eventos
que vienen todos de nuestros propios scripts — cero atacantes externos en la base.
— claude

## [2026-09-10] plan | los hitos de una sesión SSH
Plan aceptado archivado en [[planes/2026-09-10]]. Escalada a root con éxito, persistencia y
borrado de rastro (con timestomping) como hitos visibles para el analista. Medido: las reglas
Sigma detectan el INTENTO pero ninguna sabe si tuvo éxito; y `touch -t` se acepta en silencio
pero el `ls -l` siguiente sigue dando la fecha vieja, así que la técnica le falla al atacante en
la cara. Hallazgo mayor de paso: el INSERT del consumer no escribe la columna `tags`, así que
solo 8 de 23.022 eventos la tienen (los canarios) y cinco señales que ya se calculan
—HONEY_CRED_MATCH, PORTSCAN, WEB_FUZZING…— se pierden en disco.
— claude

## [2026-09-10] plan | paridad SSH Windows/Linux e inyección de prompt
Plan aceptado archivado en [[planes/2026-09-10]]. Las cuatro tandas de mejoras del día eran
todas POSIX. Medido: Windows tiene 29 verbos pero ninguna de ellas, y cuatro delatores vivos —
el honeypot NIEGA que existan `Set-ItemProperty`, `Write-Output`, `Clear-EventLog` y `wevtutil`,
cmdlets que trae todo Windows desde 2006. Los dos últimos son justo los verbos anti-forenses.
Batería: 41 pruebas POSIX contra 9 de Windows. De los dos laboratorios de Beelzebub, el de MCP
ya se cumple casi entero (4 herramientas trampa, JSON-RPC, regla Sigma, 213 eventos); el de
red-teamers de IA tiene un hueco medido: 31 intentos de inyección de prompt en la base y cero
detectados como tal, aunque el honeypot no filtra el escenario.
— claude

## [2026-09-10] plan | auditoría de realismo Linux/Windows y paridad de la consola
Plan aceptado archivado en [[planes/2026-09-10]]. Auditado con comandos que teclea un
administrador real: de 28 comandos Linux el motor resuelve 6, de 24 cmdlets Windows resuelve 2
y NIEGA 11. Contradicciones duras medidas: uptime dice 12 días y systemctl 26; who da un login
de 2025 sobre un arranque de 2026; free -m no cuadra con /proc/meminfo. Y el hueco que anula el
motor entero: la plantilla de árbol ignora el perfil, así que una persona Windows nace con árbol
POSIX y cae en `dialecto-discrepa` — el 100% al modelo.
— claude

## [2026-09-10] plan | la consola interna y la shell externa deben coincidir
Plan aceptado archivado en [[planes/2026-09-10]]. Medido: los 18 verbos deterministas dan
salida idéntica por los dos caminos, y las secuencias con estado también (cd→pwd, sudo su→root).
Pero de 14 comandos que caen al modelo, 9 difieren. La causa está en el código: `_content`
cachea en Redis y `_passthrough` no, así que cada llamada regenera. No es solo un problema de la
consola — dos atacantes distintos ven máquinas distintas.
— claude

## [2026-09-10] plan | la puerta de calidad, visible en la consola
Plan aceptado archivado en [[planes/2026-09-10]]. `ssh_prompt_qc` puntúa 23 comprobaciones y el
endpoint funciona, pero `grep prompt-quality ui/src/js/main.js` da CERO: el operador solo ve el
score un instante tras generar con IA. Medido: la persona desplegada lleva todo el día en 87/100
con tres avisos y nadie puede verlo. Además el serializador se come el `auto_fixable` que el
propio control calcula, que es la diferencia entre «esto lo arregla el motor» y «esto lo
escribes tú».
— claude

## [2026-09-10] cierre | jornada de SSH y realismo, nueve ciclos
Nueve commits sin subir (`039a800`..`9f1d41a`): familia weblogic y cada stack con su página de
error, cinco verbos más al código, el comparador de superficies arreglado para las personas web,
tuberías y redirecciones, los hitos de sesión con el borrado de rastro registrado, Windows a la
par de Linux, la auditoría de realismo, la caché del passthrough (dos atacantes veían máquinas
distintas) y el control de calidad visible en la consola. Suite 2.242 → **2.482**. Documentado:
`.agents/TRASPASO.md` reescrito, entrada ejecutiva del 10-sep en [[bitacora-ejecutiva]] —que
llevaba parada desde el 11-ago, hueco anotado en el ROADMAP— y [[prompt-siguiente-sesion]] al
día con los tres candidatos medidos para la próxima.
— claude

## [2026-09-10] plan | el saneador deja la salida vacía
Plan aceptado archivado en [[planes/2026-09-10]]. Medido antes de tocar nada: **12 de 30**
comandos que SÍ existen acaban en cadena vacía (10 de 20 en Windows, 2 de 10 en POSIX), y las 12
por una negación falsa del modelo que el saneador tira entera. Prototipo probado: un reintento
correctivo recupera **10 de 11**. El plan añade ese reintento, cinco verbos de Windows al motor
(`Get-ComputerInfo`, `Get-Volume`, `Get-Disk`, `Get-LocalGroupMember`, `Get-History`), unifica el
criterio POSIX de «existe» con el de `which` —15 de 15 se contradecían— y tapa el agujero del
barrido, donde la prueba del cmdlet real pasaba en verde con la salida vacía.
— claude

## [2026-09-10] plan | motor determinista para routers y firewalls
Plan aceptado archivado en [[planes/2026-09-10]]. Medido antes de tocar nada: `show
running-config` **sin `enable` vuelca el cebo entero 4 de 4 veces** —enable secret, comunidad
SNMP RW y clave IPsec en claro—, el modelo **repite el prompt como salida en 12 de 14** comandos
de modo y el saneador no tapa ninguno, y Beelzebub pinta **un prompt de bash en un Cisco**. Lo
que NO estaba roto: el volcado sale verbatim (114/114 y 149/149, 0 líneas inventadas). El plan
da a los aparatos lo que bash tiene desde B1: el modo como equivalente del directorio actual, el
privilegio en código, el volcado servido desde `config_serde`, y el prompt real del aparato
(séptimo cambio en el Go). Se verifica en un segundo SSH en :2223, sin tocar la clínica.
— claude

## [2026-09-10] plan | la inyección de prompt por HTTP
Plan aceptado archivado en [[planes/2026-09-10]]. Medido antes de tocar nada: **el 92 % de los
eventos son HTTP** y el laboratorio de red-teamers de IA solo mira SSH/TELNET/MCP. Mandé cuatro
inyecciones en vivo por query, ruta, cuerpo y cabecera: **las cuatro quedaron sin marcar**, y la
regla Sigma no casó ninguna (sobre SSH sí casa: la regla funciona, mira solo `command`, que en
HTTP es `GET /ruta`). Lo que NO está roto: el honeypot no filtra su prompt — el gate las 404ea
sin tocar el modelo. Es un problema de señal para el analista, no de fuga. La segunda mitad, el
barrido de 53 rutas frente a 4.750, resultó no ser una laguna de comportamiento: **ninguna de
las 4.750 llega al modelo** y 4.737 dan el mismo 404 de 259 bytes, así que correr la wordlist
entera es barato y lo que faltaba era decirlo.
— claude

## [2026-09-10] plan | que lo aprobado editando sea lo que se sirve
Plan aceptado archivado en [[planes/2026-09-10]]. Iván preguntó tres cosas con urgencia y se
midieron las tres. (2) Sí cumplimos el laboratorio: cadena de ataque completa, **0 comandos
negados** y **10 hitos** en cada familia. (3) Sí hay paridad en Linux: **18 de 20 comandos byte a
byte idénticos** entre la consola y una sesión SSH real; las dos diferencias son el reloj (bien)
y un `pwd` fantasma en el `history` (defecto). Pero midiendo salieron dos cosas peores: el modelo
**contesta al comando anterior** cuando el historial trae turnos silenciosos —con seis, Linux
acierta 1 de 4— que es el precio del propio motor determinista; y **editar una línea del árbol
regenera el contenido de todos los ficheros**, porque la clave de caché cuelga del sha1 del
escenario entero. Eso último es exactamente lo que Iván refinó: los nombres sobreviven al
guardar, el contenido que ya había aprobado no. Windows además nunca se ha desplegado, así que
su paridad no se ha comprobado jamás.
— claude

## [2026-09-10] plan | retener el artefacto (revisión de los labs de Beelzebub)
Plan aceptado archivado en [[planes/2026-09-10]]. Se revisó [[analisis-beelzebub-labs]] punto por
punto contra el código y la base. **Cinco afirmaciones se habían quedado viejas** —la inyección
de prompt ya se disparó (19 hitos), el sha256 falso del STIX ya está arreglado, el MCP ya habla
JSON-RPC, el desajuste de puertos no era tal, y la ventaja en el lab del honeypot LLM es mucho
mayor— y **una cifra estaba mal**: el documento dice «391 reglas Sigma activas» y el motor solo
carga **99** de 410; las otras 304 piden campos de EDR (`commandline`, `image`, `eventid`) que un
honeypot no tiene. Hay además un lab nuevo del 1-sep, el 29, que valida nuestra postura de
«guardar sin ejecutar». Lo que el documento acertó sigue vigente: **no capturamos un byte de lo
que el atacante trae**, y medido en vivo, `wget bot.pl` contesta el directorio actual y el
fichero no aparece en el `ls`.
— claude

## [2026-09-10] plan | cerrar los puntos mapeados de los labs
Plan aceptado archivado en [[planes/2026-09-10]]. Cierra los seis pendientes que quedaban de la
revisión de [[analisis-beelzebub-labs]]. Dos decisiones medidas antes de planear: **las 304 reglas
Sigma NO se traducen** —traducir los campos de EDR las haría cargar (204) y 76 dispararían
**~18.000 veces sobre tráfico inocente**, con «Archive via Custom Method» saltando 3.988 veces
sobre un `GET /legal-notice`—, así que lo que se cierra es la cifra y el hecho de que se pueda
volver a inflar; y **el aislamiento por cliente estaba mal dimensionado por mí**: la consola no
tiene pantalla de login, así que no es «terminar» sino construir. Se hacen el señuelo de la API
de Docker, el cebo corrupto que solo una IA repara y la inyección inversa de prompt.
— claude

## [2026-09-10] plan | documentar lo cubierto y cerrar el barrido de realismo
Plan aceptado archivado en [[planes/2026-09-10]]. Poner al día la bitácora ejecutiva, el ROADMAP y el traspaso, y luego modelar los puertos para que `netstat`, `ss`, `lsof`, `mount` y compañía dejen de improvisar.
— claude

## [2026-09-10] avance | barrido de realismo cerrado
`netstat`, `ss`, `lsof`, `mount`, `lsblk`, `route`, `arp`, `service --status-all` y `journalctl` —más los cuatro gemelos de Windows— los resuelve ya el motor sobre un modelo de puertos nuevo, con los MISMOS PID que `ps aux`. Verificado en una sesión SSH viva. Bitácora ejecutiva al día y ROADMAP sin deuda inexistente.
— claude

## [2026-09-10] plan | Ollama en el motor (LLM local para redes OT aisladas)
Plan aceptado archivado en [[planes/2026-09-10]]. El lado honeypot ya soporta Ollama; el `llm_client` del motor no, y sin eso el passthrough del shell necesita internet.
— claude
