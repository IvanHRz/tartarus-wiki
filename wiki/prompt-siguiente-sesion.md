---
tipo: guia
creado: 2026-09-11
actualizado: 2026-09-13
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **13-sep-2026 (tarde)**, al cerrar tres jornadas seguidas de seguridad de la
> propia plataforma. Último commit **`ed7281a`**, PR **#25** abierto y con el CI en verde.

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

`.agents/TRASPASO.md` — el mapa, actualizado al 13-sep: números que no hay que volver a medir,
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

**Y para cualquier cosa de interfaz, abre un navegador.** No es una recomendación: los tres fallos
más graves de esta semana —el login que nunca funcionó, un modal que solo ponía la pantalla
borrosa y un XSS almacenado— **ninguna prueba de la suite podía verlos**, porque los tres eran de
lo que se renderiza y no de lo que está en el fichero. Hay Playwright con Chromium instalado. Exige
que el elemento esté **visible y con caja de tamaño no nulo**, no solo presente en el DOM.

## Qué pasó estos tres días (para contexto, no para repetirlo)

La plataforma dejó de tener agujeros de seguridad propia. Estaban todos, y todos medidos:

- La consola **no tenía sesión**; al encenderla apareció que el middleware saltaba `/auth/`
  entero, así que `GET /api/auth/users` respondía **200 sin cookie** y cualquiera podía crearse un
  `global_admin`.
- **«Salir» no cerraba nada** (la clave de sesión de Redis se escribía y se borraba, pero nadie la
  leía) y esa clave era la **cabecera del JWT**, idéntica en todos los tokens: todas las sesiones
  compartían una.
- **«Cambiar contraseña» no abría nada**, solo ponía la pantalla borrosa.
- El comando que teclea un atacante en el SSH del honeypot **se ejecutaba como JavaScript** en la
  pantalla del analista (XSS almacenado, probado en un navegador).
- **Seis endpoints** dejaban alcanzar la red interna con una URL; el clonador —el único que tenía
  validación— era el de menos alcance.

Y **tres veces una prueba fijaba el agujero como si fuera lo correcto**. De ahí salió la regla 7
de la skill `medir-no-suponer`, que conviene leer antes de escribir cualquier guardarraíl.

## Por dónde seguir

Elige tú y dime por qué; esto es mi orden, no una orden. El detalle de cada uno está en
`.agents/ROADMAP.md`.

1. **El atacante puede escribir el informe forense de su propio ataque** (P1). `llm_analyzer`
   mete su comando **dentro del texto de la instrucción** del modelo, y el resumen se persiste en
   `events.llm_summary`. En una plataforma de decepción es de lo que más importa: altera lo que yo
   leo para decidir cómo responder.
2. **Nada en el CI abre un navegador** (P2). Hay un `e2e/` de marzo sin configuración y fuera del
   CI, y los guiones de esta semana se quedaron en un directorio temporal.
3. **La Raspberry está caída** (P1) — figura `offline` en `/sensors/status`. Es área de la otra
   sesión, pero que no se pierda.
4. **Recuperar la IP del atacante** (P1): el NAT de Docker la enmascara, los eventos locales salen
   todos con `192.168.97.1`.
5. **Exigir la firma HMAC** (P1): está a una variable, pero antes hay que poner el secreto en la
   Pi o dejará de reportar.

## Estado al abrir

- Suite: **2.924 pasando**, 11 saltadas. `cd engine && python3 -m pytest tests/ -q`.
- Consola con **sesión encendida** (`TARTARUS_SESSION_AUTH=true`). Usuario `admin`; la contraseña
  está en `.env` (`TARTARUS_ADMIN_PASS`). En la base solo existe ese usuario.
- La barra de la consola tiene **7 controles**: el ⚙ desapareció y todo vive en el menú del
  usuario (contraseña, notificaciones, usuarios, auditoría, salir).
- Sensores: **9 activos de 10**; el caído es la Raspberry. Los dos canarios, `active`.
- El motor del Mac está en **DeepSeek**; la Pi en **Ollama** (`gemma3:4b`).
- **OJO con las claves de OpenAI del repo: las dos dan 401.** No son el problema que estés
  depurando.
