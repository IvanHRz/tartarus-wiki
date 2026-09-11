# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **11-sep-2026 (madrugada)**, tras la tanda de afinado de la consola para la demo.
> Último commit de UI `4fc24f3`, subido. El objetivo de esta sesión ya está fijado por Iván: los
> **dos huecos que vio al mirar la Raspberry en la consola**.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PRIVADO**).
- Rama `feature/tier0-deployment-readiness`. Motor Python/FastAPI en `engine/`, consola JS vanilla
  en `ui/src` (`main.js` + `index.html` + `css/tartarus.css`), Postgres en `db/init.sql`,
  honeypots Beelzebub.
- **HAY OTRA SESIÓN DE CLAUDE trabajando el mismo repo** (la Raspberry / Ollama). Antes de tocar
  nada, lee `.agents/COORDINACION.md` y anota ahí qué vas a editar. Reparto vigente: la otra
  sesión lleva la Pi (Ollama, latencia, despliegue de campo); esta sesión lleva el motor y la
  consola. **Nunca `git add -A`**: la otra sesión tiene cambios sin commitear en `engine/` y en
  `.agents/ROADMAP.md`. Añade solo tus rutas explícitas.

## Cómo quiero que trabajes

Documentación en español llano, cronológica. Todo plan aceptado se archiva verbatim en
`wiki/planes/YYYY-MM-DD.md` (skill `registrar-plan`) **antes** de ejecutarlo; al cerrar, skill
`pendientes-roadmap`. Commits en español, **sin Co-Authored-By**, excluyendo `presentacion/`. No
subas a GitHub hasta que lo pida. **Verifica en vivo y enséñame números — y verifica CONTENIDOS,
no códigos de respuesta.** Cualquier borrado masivo en la base, pregúntame antes. Avanza sin
preguntar de más cuando la dirección esté clara. Al tocar cualquier control de la consola, skill
`sin-ambiguedad` (`python3 scripts/revisar_controles.py`). Antes de decir que algo funciona, corre
la batería (`verificar-protocolo`) y pega su salida. **No toques
`beelzebub/configurations/personalities/portal-gobmx.yml`** (trabajo en vivo mío). Los YAML de
`beelzebub/configurations/services/` **no están versionados** (llevan la clave). `.agents/` **sí**
se versiona desde el 10-sep.

## El objetivo de esta sesión: los dos huecos de la Raspberry en la consola

Los vi ayer al mirar la Pi ya registrada en «Trampas desplegadas». Están medidos y anotados en
`.agents/BITACORA.md` (entrada «Dos huecos que Iván señaló…») del 11-sep.

### Hueco 1 — la consola: aplanar «Trampas desplegadas» (rápido, es de UI)

Ayer se fundieron dos secciones en una con **dos grupos**: «Servicios señuelo» y «Equipos de
campo». Al verlo **no me sirve la separación**: los 3 equipos (la Raspberry `tartarus-sensor` +
los canarios `icmp-canary-dev-01` y `modbus-canary-01`) deberían estar **arriba, en una sola
lista** con el resto de trampas, no en un grupo aparte. Quiero **una rejilla plana**: cada tarjeta
se explica sola (si es un servicio honeypot o un equipo físico), sin cabecera de grupo pesada. Los
equipos, arriba. Reutiliza `loadTrapHoneypots` y `loadSensorsFamily`, que ya existen; se trata de
juntar su salida en un solo grid ordenado, no de reescribir. Guardarraíl:
`engine/tests/test_ui_navegacion.py` ya fija que la rejilla de equipos (`sensorsFamily`) y el
botón de alta sigan visibles.

### Hueco 2 — el importante: los ataques a la Pi NO llegan a mi Monitoreo

**No tiene sentido que para ver los ataques del RP5 tenga que entrar a otra liga
(`http://192.168.0.12:8888`) en vez de verlos en el Monitoreo que ya tengo.** Medido:

- La Pi tiene **3.765 eventos en su PROPIA base** (`http://192.168.0.12:8000/events`).
- Mi consola del Mac tiene **0 de ellos** (todos sus 155 eventos son del honeypot local).
- El agente de la Pi solo manda **latido** («estoy vivo»), no **eventos** («esto me atacó»). Por
  eso el detalle del equipo solo puede enlazar afuera.

Quiero **federación de eventos**: que lo que ataca a un equipo de campo aparezca en mi Monitoreo
central, junto con lo del Mac, y pueda filtrar por equipo. Esto **toca dos áreas** —el agente/motor
de la Pi (reenvío) y la ingesta del motor central (recepción + atribución por equipo/flock)— así
que coordínalo con la otra sesión (lee `COORDINACION.md`; el reenvío desde la Pi es su área).

Piezas que YA existen y hay que reutilizar (no reinventar): el endpoint **`/ingest/sensor`** con
HMAC y atribución por flock; el agente **`sensors/agente_equipo/`** que ya late contra la consola;
y **`events.honeypot_id`** ya guarda el `sensor_id`. La tensión de diseño a resolver: en una red
**OT aislada** la Pi puede no alcanzar la consola, así que el reenvío es **best-effort** —empuja
cuando hay camino, retiene cuando no—; el latido ya prueba que hoy sí hay camino. Y decidir la
demarcación: ¿la Pi reenvía cada evento en vivo, o en lotes? ¿la consola central los guarda como
propios o como «espejo» del equipo? Empieza por **entender el flujo actual** (cómo el consumer de
la Pi mete eventos en su base) antes de proponer nada.

**Empieza por el Hueco 1** (es corto y visible), luego diseña el Hueco 2 con calma y con la otra
sesión. Y antes de nada: **lee `.agents/COORDINACION.md` y `.agents/BITACORA.md`** (arriba están
las entradas del 11-sep con todo lo medido).

## Estado al abrir

- Suite: **2.708 pasando**, 10 saltadas. `cd engine && python3 -m pytest tests/ -q`.
- La Pi (`192.168.0.12`) está dada de alta en la consola como equipo `hardware`, en el flock
  **Default**, latiendo cada 30 s. Su honeypot SSH entra con `root`/`root` (persona
  `prod-web-01`). Admin de la Pi por el **:2222** (el 22 es el honeypot).
- El motor del Mac está en **DeepSeek**; la Pi en **Ollama** (`gemma3:4b`).
- Guion de demo de SSH listo: `scripts/demo/lab_ssh.sh` + `docs/DEMO_SSH.md`.
