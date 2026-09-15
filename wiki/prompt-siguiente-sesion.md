---
tipo: guia
creado: 2026-09-11
actualizado: 2026-09-15
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **15-sep-2026 (tarde)**, al cerrar la cuarta auditoría por partes de la consola
> (Análisis: tres secciones fundidas en una, fases pulsables, catálogo de reglas al menú de
> usuario y credenciales). PR **#25**, CI **verde en los seis trabajos** sobre `450700e`.

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

`.agents/TRASPASO.md` — el mapa, actualizado al **15-sep por la tarde**: los números que no hay
que volver a medir, qué se hizo en las cuatro auditorías de la consola, qué falta por orden, y las
trampas que ya costaron una sesión cada una. Después, `.agents/COORDINACION.md`, la sección **«POR
DÓNDE SE RETOMA»** al principio de `.agents/ROADMAP.md`, y las entradas de arriba de
`.agents/BITACORA.md`.

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

**Y para cualquier cosa de interfaz, abre un navegador.** `npx playwright test` **desde la raíz**
del repo — **104 pruebas en ~1 min 12 s**, y corre en el CI en el trabajo «Navegador (E2E)», que
**bloquea**. Existe porque los tres fallos más graves de septiembre —el login que nunca funcionó,
un modal que solo ponía la pantalla borrosa y un XSS almacenado— **ninguna prueba de Python podía
verlos**. Tres reglas que salieron de ahí, y que no son opcionales:

- Exige que el elemento esté **visible, con caja y dentro del viewport** (`e2e/apoyo.ts`:
  `visibleDeVerdad` y `seVeAlAbrirlo`).
- **No des por bueno un spec que no hayas visto en ROJO** contra el defecto que vigila. Dos
  guardarraíles pasaron en verde contra código roto porque miraban el TEXTO del fichero.
- Si una prueba comprueba que algo está **vacío**, siembra en `flockQuieto()` — el segundo cliente
  de la batería. Si no, pasará ella sola y fallará en la batería entera.

## Qué pasó, en corto (para contexto, no para repetirlo)

Del 11 al 13 de septiembre se cerraron los agujeros de seguridad **propia** de la plataforma: la
consola no tenía sesión, «Salir» no cerraba nada, «Cambiar contraseña» solo ponía la pantalla
borrosa, el comando del atacante **se ejecutaba como JavaScript** en la pantalla del analista, y
seis endpoints alcanzaban la red interna con una URL. La madrugada del 14 se cerró lo que quedaba:
**el atacante ya no redacta el informe forense de su propio ataque**, **el CI abre un navegador**
y **el resumen del modelo se puede leer**.

Del 14 por la tarde al 15 por la tarde hicimos **cuatro auditorías por partes de la consola** —
Monitoreo, Análisis, el mapa de ataques, e ingesta y conteos — a partir de lo que yo iba viendo en
pantalla. El patrón se repitió en las cuatro: **lo que yo señalaba como «raro» era siempre un
defecto real**. Salió de ahí:

- **Tres relojes en la misma pantalla.** Con el «Periodo» en «todo» y 541 sucesos, un panel decía
  «0 events». Ahora la ventana la manda una sola pieza (`_ventanaQ()`).
- **La línea de tiempo escondía el 45 %** de los sucesos (296 de 541).
- **Los relojes de los sensores mienten** entre 2 y 31 días: hay `sello_efectivo(alias)` y toda
  consulta que ordene por tiempo tiene que usarlo.
- **Tres secciones describían al mismo atacante** con los mismos datos. Se fundieron en una fila
  que se despliega; Análisis pasó de 8 secciones a 6.
- **El «a veces 5 atacantes y a veces 4»** que reporté dos veces era **basura de la propia batería
  cayendo en mi cliente**. Ahora las pruebas tienen los suyos.

## Por dónde seguir

Elige tú y dime por qué; esto es mi orden, no una orden.

1. **Los tres P1 siguen bloqueados por la Raspberry** (P1), que figura `offline` desde el 11-sep.
   Recuperar la IP real del atacante y exigir la firma HMAC dependen de ella. Es área de la otra
   sesión, pero desbloquea lo demás.
2. **`/api/scan/status` se pide 21 veces en 32 segundos** con el escáner parado (P2, S): un cuarto
   del tráfico del ciclo de refresco. Es lo más barato y lo que más se nota.
3. **El perfil VRA exige 3 sucesos** (P2, S): un atacante con uno o dos sale en el mapa pero no en
   «Atacantes», y eso no se dice en ninguna parte. Es justo el tipo de desacuerdo entre paneles
   que yo detecto como «algo mal conectado».
4. **Tres vocabularios de fase** conviven todavía (P2, M), y `kill_chain_tracer` escribe en una
   tabla que no lee nadie (P3).
5. Sin la Pi y por valor: **ocultar por rol en la consola** (P2, hoy no esconde nada), **segundo
   factor** (P2) y **`narrative_builder`** (P2), que no manda nada a ningún modelo pero está
   armado para reabrir el agujero de inyección que cerramos el 14.

## Estado al abrir

- Suite de Python: **3.028 pasando**, 11 saltadas. `cd engine && python3 -m pytest tests/ -q`.
- Batería de navegador: **104 pruebas** en ~1 min 12 s, 18 ficheros. `npx playwright test` desde
  la raíz.
- CI: **seis trabajos, los seis bloqueantes** (Tests, Sigma, Dependencias, Lint, **Navegador**,
  Secret Scan). En verde sobre `450700e`.
- Consola con **sesión encendida**. Usuario `admin`; la contraseña está en `.env`
  (`TARTARUS_ADMIN_PASS`). En la base solo existe ese usuario.
- **Clientes (flocks):** «Default Flock» es el mío, con **541 sucesos y 0 de prueba**. «Pruebas
  automáticas» y «Pruebas automáticas · sin ruido» son de la batería: no los mires como datos.
- Sensores: **9 activos de 10**; el caído es la Raspberry. Los dos canarios, `active`.
- Reglas Sigma: **88** base versionada, este motor carga **103** (15 de cebo) y **95 pueden
  disparar** con tráfico de honeypot.
- El motor del Mac está en **DeepSeek**; la Pi en **Ollama** (`gemma3:4b`). Lo que se configura en
  *AI Settings* vive en el volumen `ai_estado` y sobrevive a recrear el contenedor.
- **OJO con el IPv6 de esta máquina**: se traga las conexiones a `api.deepseek.com` y
  `api.github.com` (con `curl -4` responden). Si una llamada al modelo, un push o un `docker
  build` fallan sin motivo, **no es tu cambio**.
