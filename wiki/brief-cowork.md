---
tipo: brief
creado: 2026-08-07
actualizado: 2026-08-07
commit_ref: PR#12 (rama feature/tier0-deployment-readiness)
---

# Brief de cowork — para quien llega a ayudar a dirigir TARTARUS

> Léelo primero. Es el onboarding para un colaborador (humano o Claude en cowork) que va a **ayudar a
> dirigir el barco y a planear**. Para el detalle vivo: [[sintesis]] (una página), [[estado-y-rumbo]]
> (qué mejoramos + próximas acciones), [[roadmap]] (plan por fases), `log.md` (bitácora), ADRs y
> [[modulos|páginas de módulo]].

## 1. Qué es TARTARUS (en 6 líneas)

Plataforma de **engaño / respuesta a incidentes (deception / IR)**, self-hosted, modelo **MSSP
multi-cliente**. Despliega *honeypots* (trampas que imitan servidores reales, con respuestas por
**LLM**) y *cebos* (tokens y migajas sembrados en activos reales). Captura la interacción del
atacante, la puntúa (riesgo 0–100) y la mapea a **MITRE ATT&CK**, con detección **Sigma/YARA** inline,
kill-chain automático y reportería forense. La consola es **Canvas puro + JS vanilla** (sin
frameworks). Diferenciador vs. Thinkst Canary: LLM-native, analítica inline, todo propio.

## 2. Arquitectura (mapa mental)

- **8 servicios Docker**: `beelzebub` (honeypots LLM) · `engine` (FastAPI, el cerebro) · `ui` (Nginx +
  consola Canvas) · `postgres` · `redis` · `broker` (RabbitMQ) · `scanner` · `adminer`. Más sensores
  nativos (`icmp-canary`, `modbus-canary`).
- **Pipeline de eventos**: `Beelzebub → RabbitMQ → consumer.py → PostgreSQL`, con ramas a WebSocket
  (tiempo real), kill-chain tracer, notificador y scoring. Sensores de campo reportan por
  `POST /ingest/sensor` (HMAC).
- **Dos conceptos que NO hay que confundir**:
  - **Sensor** = la trampa (honeypot). Vive "al lado" en la red; nunca es un agente dentro de un
    servidor real. (Se ven en *Remote Sensors* / *Attack Map*.)
  - **Cebo** = token o migaja. **Sí** va dentro de activos reales; sin agente. (Se ven en *Canary
    Tokens* / *Breadcrumbs*.)
- **Multi-tenancy**: cada cliente es un **flock** (`flock_id`, `NULL == Default`). Consola de **dos
  niveles**: *madre* (visión global) vs *workspace* (un cliente). ADRs [[0002-multi-tenancy-flocks]],
  [[0006-consola-dos-niveles]].
- **Stack**: Python 3.12+ / FastAPI / **Polars** (nunca pandas) / asyncpg / Redis / RabbitMQ /
  PostgreSQL 15 / Beelzebub (Go) / Canvas+vanilla JS. HW objetivo: Apple Silicon M4, campo: RPi 5.

## 3. Estado actual (resumen — ver [[estado-y-rumbo]] para el detalle)

**PR #12** (rama `feature/tier0-deployment-readiness`, suite 882 verde) trae **Tier 0** (readiness:
gate 11/11, cierra la "ingesta ciega" #10, test de aislamiento) y el arranque de **Tier E** (sensores/
enrolamiento, honeypot **OT Modbus**, port-scan, cebos que beaconan, **API SOC read-only con token**,
dashboard alerts-centric). Antes, el salto a MSSP (flocks/RBAC/dos-niveles) ya estaba hecho.

**Abierto ahora**: 13 brechas de producto (Tier F del roadmap) — aislamiento fino, claridad de la
consola, y el motor de IA del honeypot. Ver [[estado-y-rumbo]] §2.

## 4. Reglas duras (no negociables)

- **C1**: sin pandas (Polars siempre). **C2**: `engine/main.py` < 600 líneas. **C3**: Canvas puro (sin
  D3/React/Vue/Cytoscape). **C4**: sin montar el socket de Docker. **C5**: llaves solo en `.env`
  (gitignored), nunca en código/config tracked/logs.
- **OPSEC (repo `Tartarus` es PÚBLICO)**: no meter a archivos *tracked* el nombre del cliente, la
  estrategia comercial/MSSP, ni comparaciones competitivas. El `.agents/ROADMAP.md` es gitignored a
  propósito. La **wiki** (este repo) es **privada**. Nota: "IQSEC" y "Thinkst" ya estaban en el repo
  público de antes (preexistente); el SIEM del cliente se mantiene fuera de nuevos archivos tracked.

## 5. Cómo trabajamos

- **Plan mode primero** para tareas no triviales: se investiga (agentes Explore en paralelo), se
  diseña, se pregunta lo ambiguo, se aprueba el plan, y recién ahí se ejecuta.
- **Verificación real**: `pytest` verde + **E2E contra el stack corriendo** (no solo unit). Cada bug
  se reproduce y se prueba el fix.
- **Commits**: co-autor `Claude Fable 5 <noreply@anthropic.com>`. En la wiki, las entradas de `log.md`
  se firman `— claude`. Se commitea/pushea **solo cuando el usuario lo pide**; si estás en `main`,
  ramea primero.
- **Modelos**: híbrido — **Opus** para arquitectura/decisiones; **Fable 5** para trabajo en volumen.
- **Idioma**: español. Sin adulación ni relleno. Editar > reescribir. Probar antes de declarar hecho.
- **Límite del entorno CLI**: `git filter-branch`/`rebase -i` están **bloqueados** (no se puede
  reescribir historial desde el agente).

## 6. Dónde está el cerebro

Esta wiki (`tartarus-wiki`, privada) es el **cerebro canónico** (código = QUÉ, wiki = POR QUÉ):
- `index.md` — mapa (léelo antes de cualquier consulta). · `log.md` — bitácora append-only.
- `wiki/adr/` — decisiones con alternativas (0001–0012). · `wiki/modulos/` — componentes clave.
- `wiki/postmortems/` — incidentes (p.ej. la ingesta ciega). · `wiki/releases/` — por versión.
- `wiki/deploy-checklist.md` — qué es "desplegable" + runbook de la API SOC.
- **El roadmap operativo** vive en `.agents/ROADMAP.md` (en el repo de código, gitignored).

## 7. Qué estudiar para poder dirigir

1. Este brief + [[sintesis]] + [[estado-y-rumbo]].
2. Los ADRs de la columna vertebral: [[0002-multi-tenancy-flocks]], [[0006-consola-dos-niveles]],
   [[0003-rbac-tres-roles]], [[0012-api-soc-menor-privilegio]], [[0011-dashboard-alerts-centric]].
3. El **gate de readiness** (`scripts/audit_gate.sh`) y el postmortem [[2026-08-07-ingesta-amqp-ciega]]
   — explican el criterio de "desplegable".
4. La **referencia de mercado**: la carpeta del POC (manual de consola + bitácora de pruebas) que
   inspira la simplicidad de la consola y el modelo sensor/cebo.
5. El **Tier F** del `ROADMAP.md`: las 13 brechas abiertas, con causa raíz y estimados.

## 8. Cómo ayudar (dirigir + planear)

- **Priorizar** el Tier F: seguridad (aislamiento fino), luego claridad de consola, luego features.
- **Cuestionar** decisiones (elige lo mejor, no lo primero); la regla de oro del producto es
  **intuición y facilidad de uso** para el analista.
- **Proponer** planes acotados por fase (una fan-out de investigación → diseño → E2E), y mantener la
  wiki y el roadmap al día tras cada avance.

— claude
