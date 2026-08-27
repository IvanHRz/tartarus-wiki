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
