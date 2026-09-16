---
tipo: guia
creado: 2026-09-11
actualizado: 2026-09-16
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **16-sep-2026 (noche)**, al cerrar la reconciliación del ROADMAP y el ciclo de vida
> de los cebos. PR **#25**, CI **verde en los seis trabajos** sobre `fd31b32`.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PRIVADO**).
- Rama `feature/tier0-deployment-readiness`, PR **#25**. Motor Python/FastAPI en `engine/`,
  consola JS vanilla en `ui/src` (`main.js` + `index.html` + `css/tartarus.css`), Postgres en
  `db/init.sql`, honeypots Beelzebub. Motor en `localhost:9001`, consola en `:8888`.
- Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo propio, privado).
- **HAY OTRA SESIÓN DE CLAUDE trabajando el mismo repo** (la Raspberry / Ollama). Antes de tocar
  nada, lee `.agents/COORDINACION.md` y anota ahí qué vas a editar. Reparto vigente: la otra
  sesión lleva la Pi (Ollama, latencia, despliegue de campo); esta sesión lleva el motor y la
  consola. **Nunca `git add -A`**: rutas explícitas siempre.

## Antes de nada, lee esto

`.agents/TRASPASO.md` — el mapa: los números que no hay que volver a medir, qué se hizo, qué falta
por orden y **las trampas que ya costaron una sesión cada una**. Después `.agents/COORDINACION.md`,
la cabecera de `.agents/ROADMAP.md` y las últimas entradas de `.agents/BITACORA.md`.

**Y desconfía de las listas de pendientes, incluidas las mías.** El 16-sep comprobé cinco entradas
del plan a mano y **cuatro estaban desfasadas o eran falsas** — dos las había escrito yo esa misma
semana. Se reconciliaron las 169 abiertas contra el código: quedan **258 entradas, 97 cerradas y
161 abiertas**, y las cerradas llevan su evidencia (fichero y símbolo). Aun así: **comprueba en el
código antes de ponerte con algo.** Lo vigila `engine/tests/test_roadmap_coherente.py`.

## Cómo quiero que trabajes

Documentación en español llano, cronológica. Todo plan aceptado se archiva verbatim en
`wiki/planes/YYYY-MM-DD.md` (skill `registrar-plan`) **antes** de ejecutarlo; al cerrar, skill
`pendientes-roadmap`. Commits en español, **sin Co-Authored-By**, excluyendo `presentacion/`.
El trabajo va al **PR #25** y se comprueba el **CI atado al SHA del commit**, no al último run de
la rama.

**Verifica en vivo y enséñame números — y verifica CONTENIDOS, no códigos de respuesta.** Y con
eso me refiero al RESULTADO, no al mecanismo: el 16-sep di por cerrado un pendiente porque «el
guion existe», y el defecto que describía seguía intacto en disco.

Cualquier borrado masivo en la base, pregúntame antes. Avanza sin preguntar de más cuando la
dirección esté clara. Al tocar cualquier control de la consola, skill `sin-ambiguedad`
(`python3 scripts/revisar_controles.py`). Tras tocar un protocolo, skill `verificar-protocolo` y
pega su salida. **No toques `beelzebub/configurations/personalities/portal-gobmx.yml`** (trabajo en
vivo mío). Los YAML de `beelzebub/configurations/services/` **no están versionados** (llevan la
clave); `.agents/` **sí** se versiona.

**Para cualquier cosa de interfaz, abre un navegador.** `npx playwright test` **desde la raíz** —
**128 pruebas en ~2 min 30 s**, 22 ficheros, y corre en el CI en el trabajo «Navegador (E2E)», que
bloquea. **La batería NO reintenta, ni aquí ni en el CI**, y es deliberado. Tres reglas que no son
opcionales:

- Exige que el elemento esté **visible, con caja y dentro del viewport** (`e2e/apoyo.ts`:
  `visibleDeVerdad`, `seVeAlAbrirlo`).
- **No des por bueno un spec que no hayas visto en ROJO** contra el defecto que vigila.
- Si una prueba comprueba que algo está **vacío**, siembra en `flockQuieto()`. Y si siembra, que
  **reconozca lo suyo al terminar** (`/api/alert-ux/acknowledge/{ip}`): sembrar 60 sucesos en el
  cliente compartido tumbó a otra prueba.

**Si algo sale intermitente, no te encojas de hombros.** Cinco veces en solitario y cinco dentro de
la suite: si sólo falla acompañado, busca qué carga el motor. Las cuatro intermitencias de esta
semana eran **defectos del producto**, no pruebas nerviosas.

## Qué pasó, en corto (contexto, no para repetirlo)

Del 11 al 13 de septiembre se cerraron los agujeros de seguridad **propia**: la consola sin sesión,
«Salir» que no cerraba, el comando del atacante ejecutándose como JavaScript en la pantalla del
analista, seis endpoints hacia la red interna. La madrugada del 14, lo que quedaba: **el atacante
ya no redacta el informe forense de su propio ataque** y **el CI abre un navegador**.

Del 14 al 15 hicimos **cinco auditorías por partes de la consola**, y el patrón se repitió en las
cinco: **lo que yo señalaba como «raro» era siempre un defecto real** — tres relojes en la misma
pantalla, una línea de tiempo que escondía el 45 % de los sucesos, tres secciones describiendo al
mismo atacante, y el honeypot SSH sirviendo una clínica privada mientras la tarjeta lo llamaba
«Ubuntu estándar».

El 15 por la noche y el 16, el **informe que se entrega al cliente**: cubría siete días sin
decirlo, llamaba a un modelo externo **siempre y en silencio**, escondía elementos de sus listas
sin avisar, y sólo se bajaba en HTML o PDF. Ahora respeta el periodo, declara qué cubre y si lo
escribió una IA, dice cuánto esconde, y **se baja también en Markdown** con sus 24 secciones.

El 16 por la tarde, **dos detectores que no producían nada**: el barrido web no escribía en ningún
sitio y su aviso se lo comía el propio barrido; y el escaneo de puertos **no podía dispararse
nunca** —pedía 10 puertos distintos y la plataforma expone 7—.

## Por dónde seguir

Elige tú y dime por qué; esto es mi orden, no una orden. Los anclas `{#id}` llevan a su entrada en
el ROADMAP.

1. **`plant_token()` acuña cebos que nacen huérfanos** (P1, M) {#plant-token-sin-hash}. Devuelve
   un `bool` y nunca el hash, así que nadie puede guardarlo: **cada pasada de
   `scripts/deploy_canary_tokens.py` son 10 reglas Sigma irretirables**. Pasa hoy, no es deuda
   histórica. **Lo más urgente de lo que no depende de la Raspberry.**
2. **Se registra la regla de cebo ANTES de insertar su fila** (P2, S)
   {#registrar-antes-de-insertar}, con el INSERT en un `try/except` que sólo avisa.
3. **Segundo factor** (P2, L) {#segundo-factor}. Lo pedí yo y está abierto de verdad: cero `totp`
   en todo el repo. Ojo al radio: `e2e/sesion.setup.ts` abre sesión una vez y reparte la cookie a
   las 128 pruebas, así que tiene que ser **opcional por usuario y apagado por defecto**, con
   códigos de recuperación.
4. **Tres vocabularios de fase conviven** (P2, M) {#vocabularios-fase}, y `kill_chain_tracer`
   escribe en una tabla que no lee nadie.
5. **Recuperar la IP real del atacante** (P1, M) {#ip-real-atacante} y **exigir la firma HMAC**
   (P1, S) {#hmac-exigir}: los dos dependen de la Raspberry, que sigue `offline` desde el 11-sep.
   Es área de la otra sesión, pero desbloquea lo demás.

## Estado al abrir

- Suite de Python: **3.167 pasando**, 12 saltadas. `cd engine && python3 -m pytest tests/ -q`.
- Batería de navegador: **128 pruebas**, 22 ficheros, **sin reintentos**. `npx playwright test`.
- CI: **seis trabajos, los seis bloqueantes**. Verde sobre `fd31b32`.
- ROADMAP: **258 entradas, 97 cerradas, 161 abiertas** — reconciliado el 16-sep.
- Consola con **sesión encendida**. Usuario `admin`, contraseña en `.env` (`TARTARUS_ADMIN_PASS`).
- **Clientes (flocks): 6.** «Default Flock» es el mío, con **630 sucesos**. «Pruebas automáticas» y
  «Pruebas automáticas · sin ruido» son de la batería: **no los mires como datos**.
- Sensores: **9 activos de 10**; el caído es la Raspberry.
- Reglas Sigma: **88** base versionada, este motor carga **103** (15 de cebo, **9 huérfanas**) y
  **95 pueden disparar**. YARA: **439** reglas en **95** ficheros. Honeypots: **10**.
- **🔴 `scripts/reconcile_decoy_rules.py --apply` — mira el dry-run antes.** El 16-sep ese guion
  daba por huérfanas **dos trampas ARMADAS** porque su inventario miraba dos de las cuatro fuentes.
  Ya mira las cuatro y **falla cerrado** sin Redis, pero la costumbre de mirar los números primero
  se queda.
- El motor del Mac está en **DeepSeek**; la Pi en **Ollama** (`gemma3:4b`). Lo de *AI Settings*
  vive en el volumen `ai_estado` y sobrevive a recrear el contenedor.
- **Sobre el IPv6 de esta máquina:** se traga las conexiones a `api.github.com` (con `curl -4`
  responden). **Lo de `api.deepseek.com` quedó DESMENTIDO el 15-sep**: contesta en 1,18 s. Si una
  llamada al modelo tarda, busca el motivo, no lo achaques a la red.
