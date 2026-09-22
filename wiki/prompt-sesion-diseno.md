---
tipo: guia
creado: 2026-09-21
actualizado: 2026-09-21
tags: [sesion, prompt, consola]
---

# Prompt para la sesión de diseño — `{#tokens-de-diseno}`

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
>
> **Por qué éste y no otro.** Es lo que Iván pidió desde el principio —«nos falta orden, mejor uso
> del espacio, pensar en un mejor diseño gráfico… trabajar con la intuición del usuario»— y es la
> **causa** de casi todo lo que se ha ido arreglando a mano estas dos semanas. La sesión de la
> cabecera (21-sep) lo dejó fuera a propósito para no convertir un cambio medible en un repintado
> que no se puede verificar; ahora le toca.
>
> **Se puede correr a la vez que** [[prompt-sesion-rp5]] (la Pi) y [[prompt-sesion-bateria]]
> (pide el turno de la batería, esta sesión no lo necesita hasta el final).
>
> Las cifras de abajo están **re-medidas el 21-sep-2026**, no copiadas de la entrada.

---

Trabajo en TARTARUS, plataforma de decepción (honeypots) para respuesta a incidentes.

Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
Rama `feature/tier0-deployment-readiness`, PR #25. Motor Python/FastAPI en `engine/`, consola JS
vanilla en `ui/src` (`main.js` + `index.html` + `css/tartarus.css`), Postgres en `db/init.sql`,
honeypots Beelzebub. Motor en `localhost:9001`, consola en `localhost:8888`.
Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo propio, **público**).

**Antes de tocar nada**, en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` →
`.agents/COORDINACION.md` (hay más sesiones de Claude en este mismo repo; **declárate ahí con la
plantilla del principio** y comprueba con `python3 scripts/revisar_sesiones.py`) →
`.agents/ROADMAP.md`. Cada sesión trabaja en **su propia copia**:
`scripts/sesion_paralela.sh nueva diseno`.

## El encargo

`{#tokens-de-diseno}` en `.agents/ROADMAP.md` — **P1, esfuerzo L**. No hay sistema de diseño.
Medido el 21-sep sobre `ui/src/css/tartarus.css` (4.059 líneas):

```
variables CSS declaradas       13   (12 colores + --mono)
colores escritos a pelo       133   (38 hex + 95 rgba) → los tokens cubren el 8 %
tamaños de letra distintos     22   en 294 declaraciones
   ...y no son 22 escalones:   16 en px + 6 en rem, dos sistemas conviviendo
espaciados distintos          119   en 442 declaraciones — no existe escala
border-radius distintos        10
style= en línea               371   (234 en index.html + 137 inyectados desde main.js)
familias de campo               3   incompatibles
sistemas de modal               4   con 4 anchos y 3 z-index
```

**El orden de trabajo lo dice la entrada, y ese orden importa:** (1) tokens en `:root`
—espaciado, escala tipográfica, radios, sombras, duraciones—; (2) **una sola** familia de campo y
**un solo** sistema de modal; (3) bajar los 371 `style=` a la hoja, que es donde se pueden
auditar. Reusa `.kv-row`/`.kv-label`/`.kv-value`, la única pieza sana que dejó el barrido del
14-sep.

**Empieza por el paso de una tarde que ya está identificado:** hay **cinco variables usadas y
nunca declaradas** —`--accent`, `--bg-alt`, `--bg1`, `--fg`, `--text-muted`—. No rompen nada
porque todas llevan valor de respaldo, **y los respaldos no coinciden entre sí**:
`var(--accent, #58a6ff)` en `:2558` frente a `var(--accent, #4a9eff)` en `:3060`. Es una segunda
paleta fantasma encima de la que sí existe.

```bash
python3 -c "import re,pathlib;c=pathlib.Path('ui/src/css/tartarus.css').read_text();u=set(re.findall(r'var\((--[a-z0-9-]+)',c));d=set(re.findall(r'^\s*(--[a-z0-9-]+)\s*:',c,re.M));print(sorted(u-d))"
```

## Lo que acaba de pasar y no hay que deshacer

La noche del 21-sep se rehízo **la cabecera** (`{#cabecera-rigida}`, cerrada). Lo que dejó:

- `#hdr` y `.hdr-right` con `flex-wrap`, y una `@media (max-width: 1500px)` que esconde el
  subtítulo. **Antes de eso, a 768 px el menú de usuario se salía de la pantalla** y era la única
  puerta a cerrar sesión. Lo vigila `e2e/cabecera.spec.ts` a 1280, 1024 y 768.
- `.hdr-right #flockSelector { max-width: 280px }` — el selector de **cliente** llevaba meses
  cortado a todos los anchos (110 px de caja para opciones de 228). `.filter-select-sm` **no se
  relajó**: la comparten más secciones, y ése es el patrón a seguir — **acotar por contenedor,
  nunca relajar la clase compartida**.
- El orden de la barra es deliberado: *qué estás mirando* (periodo, cliente) · *qué puedes hacer*
  (descargar, desplegar) · *cómo va todo* (escáner, motor) · *tú* (el menú, al final). Y es
  además una restricción dura: `#reportDropdown` mide 320 px y cuelga con `right: 0`, así que el
  borde derecho de su botón tiene que estar a **≥ 320 px** del borde izquierdo o el menú se sale.
- «AI Settings» ya no existe: se llama **«Ajustes de IA»** en los 51 sitios, motor incluido.
- `.gear-menu` ya no existe: es **`.user-menu`**.
- **0 de 104 campos sin rótulo** (`{#etiquetas-del-resto-de-la-consola}`, cerrada). El patrón es
  `.notify-campo` + `<label for>` encima. Si la fila es horizontal, el `flex` y el `max-width`
  que el campo llevara en línea **se mudan al envoltorio**.

## Las trampas de esta consola, que ya costaron sesiones

1. **`:8888` NO sirve tu copia de trabajo.** Sirve la de `/Users/ivanhuerta/Documents/Tartarus`.
   Cada copia tiene su consola (`docker ps | grep ui`). Para las pruebas:
   `TARTARUS_UI_URL=http://localhost:88XX npx playwright test`. **Se me olvidó dos veces la noche
   del 21 y me creí dos «guardarraíles en rojo» que no probaban nada** → `L-037`.
2. **Lee el CSS para entender, mide en el navegador para decidir.** Esa noche la lectura del CSS
   se equivocó dos veces donde la medición acertó a la primera. Hay Playwright con Chromium; un
   spec de usar y tirar que imprima cajas cuesta dos minutos.
3. **`lxml` recupera.** De un HTML roto te devuelve un árbol correcto, así que no sirve para
   validar. `scripts/revisar_envoltorios.py` usa pila propia y corre dentro de la suite: si metes
   un `</div>` entre un `<select>` y sus `<option>`, te lo canta con la línea.
4. **`revisar_anchos.py` es un CERO DURO** en dos cosas: ningún campo con `id` sin rótulo (valen
   las dos formas, `for=` y envolvente) y ningún `<label for>` apuntando al vacío o pisándose con
   otro. **Lo que NO puede ver**: un campo cortado porque su clase lo capa y el contenido no cabe
   —no hay `width` en línea con que chocar—. Eso es `{#campos-que-caben-sin-guion}` y sólo se ve
   midiendo.
5. **`e2e/sin_solapes.spec.ts` ya vigila que no se encimen letras.** Una reforma de tipografía y
   espaciado es exactamente lo que puede meter solapes en silencio: córrelo a menudo, no al final.
6. **Un verde sin holgura es una trampa que aún no saltó** → `L-039`. El menú de «Descargar»
   llevaba desde el 16-sep cabiendo **por 19 píxeles** con su prueba en verde; ensanchar otra cosa
   170 px lo tiró. Cuando una aserción sea geométrica, que el mensaje lleve el margen medido.
7. **Si tu comprobador lleva una lista de ids a ignorar, cámbiala por una pila** → `L-038`. Dos
   veces el mismo día una lista de excepciones intentó responder una pregunta de anidamiento.

## Cómo se trabaja aquí

- **Verifica en vivo y enseña números**, y verifica **contenidos**, no códigos de respuesta.
- **Guardarraíl en rojo**: ninguna prueba cuenta hasta verla fallar contra su defecto. Y
  **comprueba la causa del color**: que la inyección cambió de verdad el fichero, y contra qué
  diana corrió.
- **Derivado, no copiado**: las listas se calculan desde el código, no se mantienen a mano.
- **Nunca `git add -A`**: rutas explícitas siempre. Commits en español, sin `Co-Authored-By`,
  excluyendo `presentacion/`.
- **Nada de borrados masivos en la base sin preguntar a Iván.**
- **No toques `beelzebub/configurations/personalities/portal-gobmx.yml`** — trabajo en vivo suyo,
  sin commitear. Un comando destructivo **nunca** se encadena a un `cd`: usa `git -C <ruta>` →
  `L-029`.
- **🔒 CONGELACIÓN: no se empuja nada al repo de código hasta el 1 de octubre.** Hay un gancho
  `pre-push` que lo impide y caduca solo. El CI está parado por la cuota de minutos de Actions, así
  que **toda la verificación es local y el commit tiene que decirlo**. La wiki **sí** se empuja.
  Respaldo local: `bash scripts/respaldo_local.sh`.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta sólo si es ambiguo o
  destructivo. Documentación en español claro, sin anglicismos.

## Verificación

```bash
cd engine && python3 -m pytest tests/ -q          # 3.480 pasando · 11 saltadas al 21-sep
TARTARUS_UI_URL=http://localhost:88XX npx playwright test   # 174; 3 intermitentes conocidos
python3 scripts/revisar_anchos.py                 # 104 campos · 0 sin rótulo · 0 rótulos rotos
python3 scripts/revisar_envoltorios.py
python3 scripts/revisar_controles.py              # skill sin-ambiguedad
python3 scripts/validate_docs.py
```

Los tres intermitentes ya registrados son `fases_coherentes:60` y `:96` e
`ingesta_y_conteos:657`: **en solitario dan verde 3 de 3**, así que no son tuyos. Si te sale otro,
córrelo cinco veces en solitario antes de acusar a tu cambio.

Al cerrar: skill `destilar-leccion` (la cosecha del plan y el libro de lecciones — la última es
`L-039`, **mira cuál es la última antes de numerar, hay cuatro copias escribiendo a la vez**),
luego `pendientes-roadmap`, y `registrar-plan` cuando Iván acepte el plan.
