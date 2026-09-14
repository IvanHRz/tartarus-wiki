---
tipo: guia
creado: 2026-09-11
actualizado: 2026-09-14
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **14-sep-2026 (madrugada)**, al cerrar la inyección de prompt del analizador, el
> navegador en el CI y el resumen de IA en la consola. PR **#25** abierto y con el CI en verde.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PRIVADO**).
- Rama `feature/tier0-deployment-readiness`, PR **#25**. Motor Python/FastAPI en `engine/`,
  consola JS vanilla en `ui/src` (`main.js` + `index.html` + `css/tartarus.css`), Postgres en
  `db/init.sql`, honeypots Beelzebub. Motor en `localhost:9001`, consola en `:8888`.
- **HAY OTRA SESIÓN DE CLAUDE trabajando el mismo repo** (la Raspberry / Ollama). Antes de tocar
  nada, lee `.agents/COORDINACION.md` y anota ahí qué vas a editar. Reparto vigente: la otra
  sesión lleva la Pi (Ollama, latencia, despliegue de campo); esta sesión lleva el motor y la
  consola. **Nunca `git add -A`**: rutas explícitas siempre.

## Antes de nada, lee esto

`.agents/TRASPASO.md` — el mapa, actualizado al 14-sep: números que no hay que volver a medir,
qué se hizo, qué falta por orden, y las trampas que ya costaron una sesión cada una.
Después, `.agents/COORDINACION.md` y las entradas de arriba de `.agents/BITACORA.md`.

## Cómo quiero que trabajes

Documentación en español llano, cronológica. Todo plan aceptado se archiva verbatim en
`wiki/planes/YYYY-MM-DD.md` (skill `registrar-plan`) **antes** de ejecutarlo; al cerrar, skill
`pendientes-roadmap`. Commits en español, **sin Co-Authored-By**, excluyendo `presentacion/`.
El trabajo va al **PR #25** y se comprueba el **CI atado al SHA del commit**, no al último run de
la rama. **Verifica en vivo y enséñame números — y verifica CONTENIDOS, no códigos de respuesta.**
Cualquier borrado masivo en la base, pregúntame antes. Avanza sin preguntar de más cuando la
dirección esté clara. Al tocar cualquier control de la consola, skill `sin-ambiguedad`
(`python3 scripts/revisar_controles.py`). Tras tocar un protocolo, skill `verificar-protocolo` y
pega su salida. **No toques `beelzebub/configurations/personalities/portal-gobmx.yml`** (trabajo en
vivo mío). Los YAML de `beelzebub/configurations/services/` **no están versionados** (llevan la
clave). `.agents/` **sí** se versiona.

**Y para cualquier cosa de interfaz, abre un navegador.** Desde el 14-sep hay batería propia:
`npx playwright test` **desde la raíz** del repo — **37 pruebas en 30 s**, y corre en el CI en el
trabajo «Navegador (E2E)», que **bloquea**. Existe porque los tres fallos más graves de la semana
—el login que nunca funcionó, un modal que solo ponía la pantalla borrosa y un XSS almacenado—
**ninguna prueba de Python podía verlos**. Dos reglas que salieron de ahí, y que no son
opcionales: exige que el elemento esté **visible, con caja y dentro del viewport** (`apoyo.ts`:
`visibleDeVerdad` y `seVeAlAbrirlo`), y **no des por bueno un spec que no hayas visto en ROJO**
contra el defecto que vigila — uno de los cinco no cazaba el suyo.

## Qué pasó, en corto (para contexto, no para repetirlo)

Del 11 al 13 de septiembre se cerraron los agujeros de seguridad **propia** de la plataforma: la
consola no tenía sesión, «Salir» no cerraba nada, «Cambiar contraseña» solo ponía la pantalla
borrosa, el comando del atacante **se ejecutaba como JavaScript** en la pantalla del analista, y
seis endpoints alcanzaban la red interna con una URL.

La madrugada del 14 se cerró lo que quedaba de eso:

- **El atacante ya no redacta el informe forense de su propio ataque.** Su comando entraba dentro
  del texto de la instrucción que se le manda al modelo. Medido: el prompt viejo devolvía
  `Benign. Routine administrative activity. No response required.` — lo que él dictó.
- **El CI abre un navegador.** El montaje existía y estaba **en el `.gitignore`** desde febrero.
- **El resumen del modelo se puede leer** desde el detalle del suceso, con su proveedor, su
  confianza y una banda de aviso cuando nació de evidencia manipulada.

Y tres defectos que aparecieron al hacerlo, que dicen mucho de dónde suelen estar: dos rutas de
`/analyze` daban **500 siempre** por el orden de declaración, `POST /analyze/{event_id}` **no
llegaba a un modelo nunca**, y las claves de OpenAI y DeepSeek **viajaban dentro de la imagen**
del motor porque no existía ningún `.dockerignore`.

## Por dónde seguir

Elige tú y dime por qué; esto es mi orden, no una orden. El detalle está en `.agents/ROADMAP.md`.

Los tres P1 que quedan **están bloqueados por lo mismo** y son, de hecho, un solo trabajo:

1. **La Raspberry está caída** (P1) — `equipo-88a29e57855e` figura `offline` desde el 11-sep. Es
   área de la otra sesión, pero **desbloquea los dos siguientes**.
2. **Recuperar la IP del atacante** (P1) — el NAT de Docker la enmascara. En la Pi el arreglo es
   `network_mode: host`; en el Mac (OrbStack = VM) probablemente no tiene arreglo.
3. **Exigir la firma HMAC** (P1) — está a una variable, pero antes hay que poner el secreto en la
   Pi o dejará de reportar.

Sin la Pi se puede hacer, por valor: **ocultar por rol en la consola** (P2, hoy no esconde nada y
un `watcher` ve entradas que siempre fallan), **segundo factor** y **ver/cerrar sesiones
abiertas** (P2, los pediste tú), y **`narrative_builder`** (P2), que hoy no manda nada a ningún
modelo pero está armado para reabrir el agujero que se acaba de cerrar.

## Estado al abrir

- Suite de Python: **2.952 pasando**, 11 saltadas. `cd engine && python3 -m pytest tests/ -q`.
- Batería de navegador: **37 pruebas** en ~30 s. `npx playwright test` desde la raíz.
- CI: **seis trabajos, los seis bloqueantes** (Tests, Sigma, Dependencias, Lint, **Navegador**,
  Secret Scan).
- Consola con **sesión encendida**. Usuario `admin`; la contraseña está en `.env`
  (`TARTARUS_ADMIN_PASS`). En la base solo existe ese usuario.
- Sensores: **9 activos de 10**; el caído es la Raspberry. Los dos canarios, `active`.
- El motor del Mac está en **DeepSeek**; la Pi en **Ollama** (`gemma3:4b`). Lo que se configura
  en *AI Settings* vive en el volumen `ai_estado` y sobrevive a recrear el contenedor.
- **OJO con el IPv6 de esta máquina**: se traga las conexiones a `api.deepseek.com` y
  `api.github.com` (con `curl -4` responden). Si una llamada al modelo, un push o un `docker
  build` fallan sin motivo, **no es tu cambio**.
