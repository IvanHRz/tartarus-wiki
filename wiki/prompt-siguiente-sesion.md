# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (privado)
- Rama: `feature/tier0-deployment-readiness`

## Cómo quiero que trabajes

- **Documentación en español llano**, cronológica, sin tecnicismos ni anglicismos innecesarios.
- **Todo plan aceptado se archiva verbatim** en `wiki/planes/YYYY-MM-DD.md` **antes** de ejecutarlo.
- Actualiza `.agents/ROADMAP.md` (en .gitignore) y vuélcalo a `wiki/roadmap-operativo.md`. Entrada
  cronológica en `wiki/log.md`.
- **Commits en español, sin `Co-Authored-By`**, excluyendo siempre `presentacion/` (48 MB de binarios).
- **No subas a GitHub hasta que lo pida.**
- **Verifica en vivo contra el stack**, no por suposición. Si mides algo, enséñame el número.
- Avanza sin preguntar de más cuando la dirección sea clara; pregunta solo si es ambiguo o destructivo.
- **Cualquier borrado masivo en la base: pídemelo antes.**

## Arranque del stack

- **`make up-quick`. NUNCA `make up`** (hace `down -v` y borra la base).
- Engine en **`:9001`** (no 9000). Consola en **`:8888`**. Honeypot SSH en **`:2222`**.
- UI por bind mount: cambios en `ui/src` se ven con **Cmd+Shift+R**, sin rebuild.
- Antes de medir tests tras mutar código, **borra `__pycache__`** (un `.pyc` viejo dio un falso verde).
- Suite: `cd engine && python3 -m pytest tests/ -q` (hoy **1400 verdes**).

## Seguridad, sin excepciones

- La clave de OpenAI está en `Entrada/GPT.rtf` y en los YAML de `beelzebub/configurations/services/`
  (ambas en `.gitignore`; el repo de código es **público**). **Al leerlas para depurar, filtra
  siempre la salida** (longitudes con `awk`, prefijo/sufijo enmascarados). Ya se volcó una vez.
- El fichero de runtime del engine `engine/.ai_runtime.env` (clave del AI Settings) también está
  gitignoreado. **La clave nunca a ficheros rastreados.**

## Estado actual (lo que YA funciona)

El foco de las últimas sesiones ha sido **el honeypot SSH creíble** (Beelzebub + LLM). Cerrado:

- **AI Settings arreglado**: la clave del engine persiste (fichero montado `engine/.ai_runtime.env`,
  recargado al arrancar); el Test guarda antes de probar y no miente (401 claro). Modelo global
  gpt-4o-mini; el **honeypot SSH usa gpt-4o** (gpt-4o-mini no daba la talla para el shell con estado).
- **Shell SSH con estado**: `cd`/`pwd`/`ls` coherentes, `ls` == `ls -lsa` (árbol con marcadores `/`
  para carpetas), `cd` a un fichero → `Not a directory`, `cat` genera contenido plausible. Es
  **LLM-first**: se quitaron los 61 handlers estáticos que fijaban prod-web-01 y chocaban con
  cualquier persona a medida. Techo honesto: ~90-95% (el LLM glitchea a veces).
- **Sistema de personas (disfraces)**: `personalities/*.yml` (versionadas). Editar prompt, **probar
  sin aplicar** (`POST /personalities/{id}/probe`), aplicar (`apply` — solo cambia `plugin.prompt`,
  conserva modelo/clave). El prompt de verdad vive en la persona; «Aplicar» lo copia al YAML vivo.
- **Generador de entornos por IA**: `POST /personalities/generate-scenario` — describes al cliente y
  gpt-4o genera el **ESCENARIO** (hostname, árbol de ficheros del negocio, usuarios) y el endpoint le
  antepone un bloque de **REGLAS FIJAS** afinadas (estado, cd permisivo, consistencia de ls, tipos,
  contenido, anti-detección). Botón «✨ Generar personalidad a medida (IA)» en el modal de config SSH
  y en el editor de personas. Guarda el contexto usado («Generado para: …»).
- **«Aplicar» reinicia Beelzebub solo** (llama a `restartBeelzebub()` → `/services/restart` → flag
  `.restart-requested` → watchdog launchd cada 60 s hace `docker restart tartarus-beelzebub`).
- **Despliegue opt-in**: un flock nuevo no despliega nada; los honeypots de Beelzebub son «Laboratorio
  compartido» (una sola instancia en puertos fijos; el engine NO puede crear contenedores — regla C4).
- Scripts de limpieza: `scripts/puesta_a_cero.sh` (vacía datos, conserva inventario) y
  `scripts/reinicio_de_fabrica.sh` (deja solo el flock por defecto). Piden confirmación.

Arquitectura del honeypot para tenerlo claro: **una sola instancia de Beelzebub**, imagen mínima
(sin `sh`), config montada en `:ro`. El SSH responde por LLM con el prompt de la persona aplicada.

---

# Lo que toca hacer (dos partes)

## Parte A — Realismo del shell (empezar por aquí, alto valor)

En mi última prueba por SSH salieron varios **tells** (cosas que delatan que es un simulador):

1. **`REMOTE HOST IDENTIFICATION HAS CHANGED`** en cada reconexión. Beelzebub **no persiste su clave
   de host SSH**; se regenera en cada reinicio, y ahora «Aplicar» reinicia siempre → un atacante ve
   que la huella cambia y sospecha. **Es el fix #1.** Investigar si Beelzebub v3.9.0 admite una ruta
   de clave de host fija que podamos **montar en un volumen escribible** (hoy el mount es `:ro`); si
   no lo soporta por configuración, evaluar alternativa (fork/otra vía) y consultarme. Requiere tocar
   `docker-compose.yml` (recreate de Beelzebub, **sin** `down -v`, no toca la BD).
2. **`cat` de un PDF/docx** → el LLM respondió meta («no uses cat para PDFs»). Un shell real vuelca
   binario. Añadir a las REGLAS FIJAS: `cat`/`head`/`tail`/`strings` de binario/PDF/imagen vuelcan
   contenido plausible; **nunca** meta ni servicial.
3. **`nano` → command not found** (nano existe en Ubuntu). Quiero que **editores y pagers**
   (`nano`, `vi`, `vim`, `less`, `more`) «abran» el fichero (muestran su contenido y vuelven al
   prompt) para **mantener al atacante dentro**. Cubrir todos los comandos que usaría un atacante.
4. **Locale**: puse una empresa hospitalaria de CDMX y los documentos salieron **en inglés** y con
   carpetas/archivos sin sentido. El contenido debe ir **en el idioma del país/empresa** (español para
   México) y con **estructuras coherentes** por industria.
5. **serverName a medida**: el banner sigue `usuario@prod-web-01` aunque el `hostname` del comando sea
   a medida. Al aplicar la persona, tematizar también el `serverName` del YAML (banner == hostname).
6. **Timestamps**: que el prompt permita fijar la «época»/fechas de los ficheros (jugar con el tiempo).

Ubicaciones: las REGLAS FIJAS y el meta-prompt del generador están en
`engine/engine/personalities_router.py` (`_SSH_RULES`, `_META_SSH`); la persona base en
`beelzebub/configurations/personalities/ubuntu-server.yml`; el YAML vivo (gitignoreado) en
`beelzebub/configurations/services/ssh-22.yaml`.

## Parte B — Constructor de entornos por árbol (la visión de producto)

Quiero llevar el generador a un **constructor por árbol**, estilo Thinkst «Windows File Share» pero
con IA (ver `Archivos_ejemplo/Canary Console opciones en protocolos.pdf` y `wiki/diseno-despliegue.md`
§9-10). Requisitos:

1. **Menús desplegables que definimos NOSOTROS**: un catálogo de **industrias** y de **departamentos**
   (elige industria + departamento) + **una sola barra** de personalización encima. (Ya no dos cajas
   de texto libres — no les vi el caso.) **Primero propónme el catálogo de industrias y departamentos
   y lo confirmo.**
2. **Vista de árbol** de carpetas/archivos de la personalidad generada (desplegable, editable) **y** la
   **shell de prueba** al lado, para ver cómo lo vería un atacante. (Existe el banco `probe`; falta la
   vista de árbol.)
3. **Plantillas base** por industria/departamento (IT, Seguridad, RH, Finanzas, Salud, OT…),
   coherentes y en el idioma correcto — «estructuras ya hechas de cómo actuar» para el LLM, con
   múltiples ficheros navegables con contenido.
4. **Integración con canary tokens (credenciales falsas)**: en el menú, preguntar si crear tokens de
   credenciales, crearlos y **decir en qué ruta del árbol insertarlos**, para que el atacante los
   recolecte y los pruebe (y disparen alerta). Conectar con la sección de cebos / `/deploy/execute`.
5. **Realismo máximo**: pensar TODOS los parámetros que delatan un simulador; mantener al atacante el
   mayor tiempo posible.
6. **Determinismo** del árbol para `ls`/`cd` (el árbol como estructura de datos, no solo texto en el
   prompt; ahorra tokens y garantiza consistencia). Evaluar **Cowrie** si se necesita 100%.

## Cómo quiero arrancar

**Empieza por la Parte A** (los tells de realismo, sobre todo la clave de host). Confírmame primero
en vivo el tema de la clave de host de Beelzebub (con salida filtrada) y proponme el plan. Para la
Parte B, propónme antes el **catálogo de industrias/departamentos** y la maqueta del árbol; no
construyas el constructor hasta que lo confirme.

Contexto ampliado en `wiki/diseno-despliegue.md` (modelo, manual vs botón, árbol §9-10) y en
`wiki/log.md` / `.agents/ROADMAP.md` (todo lo cerrado, cronológico).
