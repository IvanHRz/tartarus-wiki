---
tipo: guia
creado: 2026-09-11
actualizado: 2026-09-17
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> **Éste es el prompt del motor y la consola.** Para una sesión de la Raspberry / despliegue de
> campo, usa [[prompt-sesion-rp5]], que lleva su propio estado medido y sus trampas.
> Actualizado: **20-sep-2026 (madrugada)**, al dejar la firma HMAC en monitoreo y los tres shims
> contando. PR **#25**, último empujón `f854217`, CI verde en los seis.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PRIVADO**).
- Rama `feature/tier0-deployment-readiness`, PR **#25**. Motor Python/FastAPI en `engine/`,
  consola JS vanilla en `ui/src` (`main.js` + `index.html` + `css/tartarus.css`), Postgres en
  `db/init.sql`, honeypots Beelzebub. Motor en `localhost:9001`, consola en `:8888`.
- Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo propio, privado).
- **HAY OTRA SESIÓN DE CLAUDE** en el mismo repo (la Raspberry / Ollama). Antes de tocar nada lee
  `.agents/COORDINACION.md` y anota ahí qué vas a editar. Reparto vigente: la otra lleva la Pi;
  ésta, el motor y la consola. **Nunca `git add -A`**: rutas explícitas siempre.

## Antes de nada, lee esto

`.agents/TRASPASO.md` — el mapa: los números que no hay que volver a medir, «Lo siguiente, por
orden» y **las trampas que ya costaron una sesión cada una** (son muchas y son reales; léelas).
Después `.agents/COORDINACION.md`, la cabecera de `.agents/ROADMAP.md` y las últimas entradas de
`.agents/BITACORA.md`.

**Y desconfía de las listas de pendientes, incluidas las mías.** El 16-sep se reconciliaron las
169 abiertas contra el código y **cuatro de cada cinco entradas comprobadas a mano estaban
desfasadas o eran falsas**. Hoy el plan va por **360 entradas, 117 cerradas y 243 abiertas** (sácalo, no lo cites: el contador está en `.agents/TRASPASO.md`), con
ocho bloques nuevos con ancla. **Comprueba en el código antes de ponerte con algo**: lo vigila
`engine/tests/test_roadmap_coherente.py`, que exige que cada punto de «Lo siguiente» señale su
entrada con `{#ancla}` y que esa entrada no esté cerrada.

## Cómo quiero que trabajes

Documentación en **español llano y cronológico**. Todo plan aceptado se archiva verbatim en
`wiki/planes/YYYY-MM-DD.md` (skill `registrar-plan`) **antes** de ejecutarlo; al cerrar, skill
`pendientes-roadmap`. Commits en español, **sin `Co-Authored-By`**, excluyendo `presentacion/`.
El trabajo va al PR **#25** y **el CI se comprueba atado al SHA del commit**, no al último run de
la rama.

**Verifica en vivo y enséñame números — y verifica CONTENIDOS, no códigos de respuesta.** Y con
eso me refiero al RESULTADO, no al mecanismo: se han cerrado pendientes porque «el guion existe»
con el defecto intacto en disco.

**Y mira las SALTADAS, no sólo las verdes.** El 17-sep, sacar los conteos del CI atados al SHA en
vez de repetirlos de memoria destapó que la prueba escrita para demostrar que rotar el secreto JWT
«no fue un gesto» **no corría en ningún entorno** —se saltaba en local y en el CI— y que, de haber
corrido, **habría pasado sin rotación**: forjaba un token de dos partes que `_verify_token`
rechaza antes de mirar la firma. Van cuatro casos de prueba que documentaba un agujero como
correcto. Queda `{#saltos-sin-inventario}` para inventariarlas todas.

**Cualquier borrado masivo en la base, pregúntame antes.** Avanza sin preguntar de más cuando la
dirección esté clara.

**Las skills del proyecto no son opcionales** (`.claude/skills/`, y están listadas en `CLAUDE.md`
§10). Las que más se disparan:

- `sin-ambiguedad` — al añadir, renombrar o quitar cualquier control (`python3
  scripts/revisar_controles.py`).
- **`consola-usable`** — al tocar `index.html`, cualquier JS de `ui/src/js/` o el CSS.
- **`perseguir-intermitente`** — **nueva, 17-sep**: cuando la batería falle una pasada y pase la
  siguiente, o un fallo no se reproduzca en solitario. Nada de «ya no lo vi».
- `verificar-protocolo` — tras tocar un protocolo, una persona, un prompt o un árbol. Pega su
  salida o no se dice que funciona.
- `medir-no-suponer` — antes de afirmar una causa o que algo está arreglado.

**Para cualquier cosa de interfaz, abre un navegador.** `npx playwright test` desde la raíz — 157
pruebas, 27 ficheros. **No reintenta, y es deliberado.** Ojo con el «bloquea en el CI»: bloquean
**140**; las **2** de `trampas.spec.ts` se saltan allí porque exigen un honeypot con la persona
tramposa aplicada, y en el CI no hay honeypots. Tres reglas no
opcionales: exige el elemento visible, con caja y en el viewport (`e2e/apoyo.ts`); **no des por
bueno un spec que no hayas visto en ROJO**; y si una prueba comprueba que algo está vacío, siembra
en `flockQuieto()` — pero si tu prueba **siembra**, va a `flockDePruebas()`, y sus aserciones son
de **subconjunto**, nunca de igualdad.

**🔴 La batería: una a la vez, y aun así falla.** Dos cosas que ahorran media hora cada una.

**Una a la vez.** Las tres copias de trabajo comparten stack, y `sesion.setup.ts` **vacía los dos
clientes de prueba al arrancar**: la segunda batería que empieza le borra los datos a la primera.
Desde el 18-sep hay turno (`e2e/cerrojo.ts`, fichero en el `.git` común): si otra copia lo tiene,
la batería **muere en el arranque diciendo quién**. Antes de culpar a tu cambio de una racha rara,
`ps aux | grep '[p]laywright'`.

**Y aun así falla.** Vaciar el cliente quitó **una** causa, no todas: 20-sep **155·153·157** con el
stack en exclusiva. La frase «vaciado, 142/142 tres veces seguidas» **no se reproduce: no la
cites**. Lo que queda está inventariado en `{#bateria-sigue-intermitente}` (P1), y cada espécimen
**pasa 5 de 5 en solitario** — si tu spec hace eso, no lo has roto tú.

```bash
docker exec tartarus-postgres psql -U tartarus -d tartarus -tA -F' | ' -c "
SELECT f.name, COUNT(e.id), COUNT(DISTINCT e.source_ip)
FROM flocks f LEFT JOIN events e ON e.flock_id=f.id GROUP BY f.name ORDER BY 2 DESC;"
```

## Estado al abrir

- Python **3.393 pasando**, **9 saltadas** aquí y **2** en el CI — y desde el 18-sep esas nueve
  están **declaradas** en `engine/tests/test_saltos_vivos.py`: si añades una prueba con `skip`,
  hay que apuntarla ahí, y **no se puede declarar en los dos entornos** (eso es una prueba que no
  corre en ninguno; van seis en este repo). Navegador **157**, de las que **155 bloquean** en el
  CI — y **no dan 157/157 tres veces seguidas** en el portátil.
- Consola con sesión: `admin`, contraseña en `.env` (`TARTARUS_ADMIN_PASS`). **Segundo factor
  disponible y apagado**; la batería y los guiones entran con `servicio-local`
  (`TARTARUS_SERVICE_PASS`), que **nunca** puede tener 2FA.
- **6 flocks.** «Default Flock» es el mío, **630 sucesos** — los dos de «Pruebas automáticas» son
  de la batería: no los mires como datos.
- Sensores **9 de 10**; el caído es la Raspberry. Sigma **94 cargadas** (88 base + 6 de cebo, **0
  huérfanas**), 86 pueden disparar. YARA 439. Honeypots 10, **los diez con cerebro**.
- Motor en DeepSeek; la Pi en Ollama.

## Por dónde seguir

**Elige tú y dime por qué; es mi orden, no una orden.** El detalle, con su medición y el comando
que la produce, está en `.agents/ROADMAP.md`.

**👁 Antes de elegir, mira lo que está en monitoreo** — son dos y **no necesitan código**:

```bash
curl -s localhost:9001/metrics/tartarus | grep -E "sin_firmar_desde |sin_firmar_total\{|shim_sin_credencial_total\{"
```
· `{#hmac-exigir}`: se enciende cuando haya **cero remitentes sin firmar durante una semana** Y
`TARTARUS_HMAC_SECRET` esté en el systemd de la Pi. Ventana abierta el 19-sep 22:53.
· `{#shims-sin-auth}`: los tres shims cuentan y **no rechazan**. Se cierra poniendo un token de
verdad en los YAML de `beelzebub/configurations/services/` (no versionados) y
`TARTARUS_SHIM_TOKEN` en el motor. **Cerrar esa puerta de golpe dejó nueve de los diez honeypots
sin cerebro tres días**; hay una prueba que fija el modo aviso a propósito.

Y los P1 que sí son código:

1. **El guion que monta la Raspberry nunca la enrola** (P1, **M** — no S, lo midió campo)
   `{#hardware-nunca-enrola}`. `sensor-enroll.sh` sólo escribe el `flock_id` en un fichero: no
   guarda el `sensor_id`, no arranca el agente y no configura `TARTARUS_HMAC_SECRET`. Se funde
   con `{#rpi-agente}`. La Pi es área de la sesión de campo; coordínalo.
2. **La batería sigue fallando aunque su cliente se vacíe y haya turno** (P1, M)
   `{#bateria-sigue-intermitente}`. 20-sep: **155·153·157** en exclusiva. Es lo que más estorba a
   todo el mundo — cada fallo cuesta media hora de descarte. Ya hay dos especímenes cerrados con
   veredicto y el método probado: **cinco pasadas en solitario**, y si pasa, es de este
   inventario. Empieza por los de `ventana_tiempo`, que son los que más salen.
3. **Un cliente no puede conseguir la imagen de Docker** (P1, M) `{#docker-sin-imagen}`. El que
   más bloquea fuera del equipo, y nadie lo ha tocado en cuatro días: sin `Dockerfile`, sin
   registry, sólo `arm64`, y el compose cae a la de upstream **sin los seis parches**, con la
   clave de host SSH cambiando en cada reinicio.

3. ~~**Las credenciales cebo se comparan sin mirar de qué cliente son**~~ — **HECHO el 17-sep
   (mañana)**, con A/B por la cola real: el cebo del cliente A daba 98 y `HONEY_CRED_MATCH` en el
   suceso del B, y hoy da 85 sin etiqueta. En su lugar, de la misma familia:
   **borrar una regla de asignación deja sus sucesos en `flock_id NULL`, que es el Default Flock**
   (P2, S) `{#asignacion-borrada-deja-huerfanos}` — o sea, en tu vista.
4. **El cebo corrupto está construido y no lo llama nadie** (P1, M) `{#cebo-corrupto-sin-cablear}`.
   Comprobado el 17-sep: `gen_cred_corrupta` y `es_corrupto` sólo los llama su propio test. Es la
   pieza de decepción contra agentes de IA más avanzada que hay y está desconectada.
5. **Un cliente no puede conseguir la imagen de Docker** (P1, M) `{#docker-sin-imagen}` y
   **el despliegue en la RPi5 en un paso** (P1, M) `{#rpi5-un-paso}`.
6. **La barra de notificaciones** (P1, M) `{#campos-sin-etiqueta}` — 13 campos, cero `<label>`, y
   guardar tras recargar **borra la contraseña SMTP**. Cuelga de `{#tokens-de-diseno}` (P1, L),
   que es el paraguas de todo lo de interfaz.
7. **La carga inicial ahoga lo que el operador pide a mano** (P1, M) `{#rafaga-carga-inicial}`.
   Medido: 18 cargadores de golpe, **33 peticiones en vuelo**, 6 conexiones por host, y un clic
   durante la carga tarda **15,2 s** para un endpoint de **7 ms**. Ya se probó y **descartó**
   estrangularlo en tandas; el arreglo bueno es **no pedir datos de paneles ocultos**.

**Bloqueado por la Raspberry** (offline desde el 11-sep): `{#rpi-agente}`, `{#ip-real-atacante}`.
Y **`{#hmac-exigir}` NO se puede decidir hoy** aunque parezca que sí: el contador de quién manda
sin firmar (`hmac_verifier._sin_firma`) es un **diccionario en memoria** que se borra en cada
reinicio, así que «cero» significa «nadie desde el último reinicio». Cierra antes
`{#contador-sin-firmar-en-memoria}`.
