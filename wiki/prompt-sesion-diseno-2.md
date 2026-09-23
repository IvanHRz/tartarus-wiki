---
tipo: guia
creado: 2026-09-23
actualizado: 2026-09-23
tags: [sesion, prompt, consola, diseno]
---

# Prompt para la sesión de diseño (segunda parte) — lo que quedó de `{#tokens-de-diseno}`

> **✅ EJECUTADO el 23-sep-2026.** Doce commits. Se cerraron `{#clases-que-no-hacen-nada}`,
> `{#fusiones-medidas}`, `{#canary-modal-sin-escape}`, `{#dos-empates-de-z-index}` y
> `{#etiqueta-en-ingles-ajustes-ia}`; `{#dos-modales-sin-bajar}` bajó de 126 a 66 `style=` y sigue
> abierta a propósito. Los veinte commits ya los alcanza una rama compartida.
>
> **Tres cifras de este prompt salieron mal al medirlas**, y conviene saberlo si se reutiliza como
> plantilla: chocaban **cinco** ficheros y no siete, las clases sin regla eran **26** y no 27 —una
> era un falso positivo del extractor de la propia entrada— y la lección que aquí se llama `L-040`
> es hoy **`L-047`**, renumerada al fusionar.
>
> El plan que salió de aquí está en `wiki/planes/2026-09-23.md`, con su cosecha.

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
>
> **Por qué éste.** La sesión del 22-sep dejó `{#tokens-de-diseno}` hecha en lo esencial —19
> commits, cambio visual cero demostrado— pero con **tres cosas sin cerrar y una que urge**: los 19
> commits **no los alcanza ninguna rama del repo**, hay una lista de fusiones medida esperando el
> visto bueno de Iván, y quedan dos modales con 126 `style=` ya repartidos en clases.
>
> **Se puede correr a la vez que** [[prompt-sesion-rp5]] (la Pi) y la de «puertas de máquina», que
> tienen sus propias copias y no tocan `ui/`.
>
> Las cifras de abajo están **medidas el 22-sep-2026 al cerrar**, no copiadas.

---

Trabajo en TARTARUS, plataforma de decepción (honeypots) para respuesta a incidentes.

Código: `~/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
Rama `feature/tier0-deployment-readiness`, PR #25. Motor Python/FastAPI en `engine/`, consola JS
vanilla en `ui/src` (`index.html` + `css/tartarus.css` + **seis ficheros en `js/`**, el grande es
`js/main.js`), Postgres en `db/init.sql`, honeypots Beelzebub. Motor en `localhost:9001`.
Wiki aparte: `~/Documents/Wikis/wiki-tartarus` (repo propio, **público**).

**Antes de tocar nada**, en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` →
`.agents/COORDINACION.md` (hay más sesiones en este repo; **declárate con la plantilla del
principio** y comprueba con `python3 scripts/revisar_sesiones.py`) → `.agents/ROADMAP.md`.

## Lo primero, y es lo único que urge

**Los 19 commits de la sesión anterior no están en la rama.** Viven en la copia `Tartarus-diseno`,
en HEAD desprendida, y son alcanzables **sólo** por la rama local `diseno/tokens-de-diseno`, que se
creó al cerrar justo para que no desaparecieran. Mientras no se fusionen, `sesion_paralela.sh
cerrar diseno` se los llevaría por delante: el árbol está limpio, así que no se negaría.

Medido al cerrar: la rama principal iba **25 commits por delante**, y la fusión toca 20 ficheros.
**Ningún fichero de `ui/` choca** —el trabajo de diseño entra limpio—; los conflictos son los siete
de siempre:

```
.agents/BITACORA.md   .agents/COORDINACION.md   .agents/LECCIONES.md
.agents/ROADMAP.md    .agents/TRASPASO.md       .gitignore
engine/tests/test_skills_con_guardarrail.py     (los dicts TOPES y COMPROBADORES)
```

Los cinco primeros son documentos compartidos y se resuelven **quedándose con los dos lados**, que
es para lo que existe la regla de insertar con anclas. En `test_skills_con_guardarrail.py` hay que
conservar las entradas de las dos sesiones, no elegir una.

**Y después de fusionar, medir.** Es `L-030`: van diez entradas del ROADMAP corregidas por darlas
por buenas sin mirar, y una fusión que no trae nada **no falla, se queda callada**.

## El encargo

Cuatro cosas, en este orden. Todas tienen su medición hecha: no hay que volver a medir.

### 1. `#fusiones-medidas` (P2·M) — esto necesita que Iván decida, no que tú decidas

Es lo único de la sesión anterior que **movería píxeles**, y por eso se dejó fuera. Está todo
medido y sin aplicar. Se le enseña a Iván y se aplica en **un solo commit**, que es el único donde
el arnés admite diferencias:

- **`.section-subtitle`** — de sus diez elementos, ocho se pintan a 11 px apagado y **dos a 14 px a
  plena luz**: dos subtítulos que no parecen subtítulos. Sigue exenta en
  `_HTML_SIN_ESTILO_CONOCIDAS` por eso.
- **`.ai-provider-card`** (`index.html:1709`) — su `style=` sobrescribe a su propia clase, 6 px de
  radio contra `--r-8` y 8 px de relleno contra `--sp-12`, y **sólo una de sus cinco tarjetas lo
  lleva**: se pintan distinto entre sí.
- **La paleta de Tailwind conviviendo con la de GitHub** — `#22c55e`×6 (contra `--green` `#3fb950`),
  `#eab308`×4, `#ef4444`×4, `#f97316`×5, `#8b949e`×12 (contra `--muted` `#7d8590`). El verde es un
  empate 8-7 que no ha ganado nadie.
- **Los sub-píxel y los `rem`** — `11.5px`×8, `10.5px`×4, `12.5px`×4, y los seis en `rem`
  (`.72 .78 .8 .85 .88 .9`), que cuelgan de un tamaño de raíz que nadie fija.
- **Una sola cáscara de modal** — hoy tres velos (`.7`/`.6`/`.55`), tres desenfoques
  (4px/2px/ninguno), dos radios (12/8), dos `max-height` (85vh/88vh) y un fondo al 88 %
  (`.dpl-modal`). Más `Escape` en `.canary-modal-overlay`, que es el único que no lo escucha.
- **Un solo aspecto de campo** — hoy dos fondos (`--bg2` contra `--bg`) y **cinco tamaños de letra**,
  tres de ellos en `rem`.

El arnés genera el antes/después elemento por elemento. **Enséñaselo antes de aplicar nada.**

### 2. `#dos-modales-sin-bajar` (P2·M) — 126 `style=`, con el reparto ya hecho

Quedan **171 atributos `style=` en `index.html`**, y 126 están en dos modales:
`#trapConfigModal` **69** y `#personaEditorModal` **57**. El de Ajustes de IA ya se hizo de ensayo.
El reparto en clases **con significado** está medido: 12 clases cubren 48 de los 69 del primero
(`.sc-bloque`, `.sc-opcion`, `.sc-rotulo`, `.sc-guardar`…), 9 cubren 39 de los 57 del segundo.

**Los dos riesgos del editor de personas, y el primero es una trampa de verdad:**

- Sus **13 campos** llevan `width:100%` en línea **porque `.filter-input` declara `width: 180px`**
  —no `max-width`—, así que el inline **gana** y es lo que les da su columna. Es el caso contrario
  al que hizo nacer `revisar_anchos.py`. **Quitarlos sin regla de sustitución los encoge a 180 px**,
  y **ningún guardarraíl lo vería**: el detector busca choques `width`/`max-width`, no
  encogimientos. La regla nueva tiene que ir **después** de `.filter-input` en el fichero: misma
  especificidad, manda el orden.
- Sus **cinco `style="margin:0"`** sobre `.pe-label`/`.pe-sub` **no son redundantes con el reset**:
  matan el `margin-top:4px` y el `margin-left:6px` de sus clases. Y sólo 4 de los 8 `.pe-label` los
  llevan, así que hace falta modificador, no fusión.

**No se persigue el cero.** Lo congela el trinquete `revisar_tokens.py::estilos_en_linea`, hoy en
**335**. Llegar a cero exigiría decenas de clases de una declaración, y este repo usa clases con
significado (`.proto-ssh`, `.scan-error`, `.btn-blue`), no CSS atómico.

### 3. `#clases-que-no-hacen-nada` (P1·S) — 27 clases que el JS aplica y el CSS no define

Salieron al comprobar si se podía ampliar `test_toda_clase_del_html_existe_en_el_css` a los
`class="…"` de las plantillas de los seis JS. **No se amplió porque se pone rojo con 27.** Familias
enteras sin una sola regla: las siete `detection-*`, las cuatro `aux-*`, las dos `ti-*`, más
`breadcrumb-card`, `flock-card`, `personality-card`, `empty-hint`, `mono`, `feed-table`,
`badge-info`, `badge-ok`, `sesion-cerrar`, y tres de `deploy_hub.js`.

**Es el mismo defecto que estiró la cabecera en septiembre**: `.report-dropdown` y sus tres
hermanas se declaraban sólo en el HTML sin una regla, y al abrir el menú los siete botones caían en
el flujo y empujaban la cabecera de 70 a 210 px. Iván lo vio antes que la batería.

Darles regla o quitarlas, y **entonces** ampliar el test. El fixture de JS ya se amplió a los seis
ficheros (`js_todos`) y salió verde; el que falta es el del HTML.

### 4. Las cuatro pequeñas, si da tiempo

`#revisar-anchos-ciego` (P2·S) · `#dos-empates-de-z-index` (P2·S) ·
`#canary-modal-sin-escape` (P2·S) · `#modal-actions-sin-usar` (P3·XS) ·
`#etiqueta-en-ingles-ajustes-ia` (P3·XS, `index.html:1806` en inglés).

## Lo que acaba de pasar y no hay que deshacer

| | al empezar el 21-sep | al cerrar el 22 |
|---|---:|---:|
| variables declaradas | 13 | **55** |
| hex a pelo (usos en el CSS) | 159 | **65** |
| `rgba`/`rgb` a pelo | 130 | **39** |
| atributos `style=` | 398 | **335** |
| `outline: none` sueltos | 5 | **3** |

- **El arnés es lo que hace verificable todo esto**: `e2e/huella.ts` +
  `e2e/instantanea_visual.spec.ts` vuelcan 45 propiedades calculadas y la caja de cada elemento en
  25 vistas —incluidos los diez modales del HTML, ocho de los cuales no abría ninguna prueba— y
  comparan con **tolerancia cero** en los estilos. **No lo toques sin entenderlo**: costó cuatro
  arreglos conseguir que dos pasadas idénticas dieran cero.
- **`scripts/revisar_tokens.py` + skill `tokens-que-no-mienten`**: once cifras derivadas, seis de
  cero duro y tres de trinquete. Antes no había nada — ni stylelint, ni prettier, ni una prueba que
  contara variables.
- **Cuatro defectos visibles arreglados**, todos de variables usadas **sin respaldo**, que no es «el
  valor por defecto» sino una declaración inválida que el navegador tira entera.
- **El `?v=` de la hoja es ahora el hash de su contenido**, y se mantiene solo. Si cambias el CSS,
  vuelve a colgarlo del hash **en el mismo commit** o `revisar_tokens.py` se pone rojo.
- **Los `outline: none` bajaron de 5 a 3** y los cinco `:focus` de los campos están fundidos en uno.

## Las trampas de esta consola

1. **`:8888` NO sirve tu copia.** Sirve la de `~/Documents/Tartarus`. La copia de diseño tiene la
   suya en **`:8895`** (`tartarus-ui-diseno`). Para las pruebas:
   `TARTARUS_UI_URL=http://localhost:88XX npx playwright test`. Ocupados: 8888, 8895, 8897, 8899.
2. **El arnés se graba con el árbol LIMPIO.** `TARTARUS_INSTANTANEA=grabar` escribe la referencia;
   si la grabas con tu cambio ya metido, el verde no prueba nada. Se hizo mal una vez el 22-sep.
   Y **la primera pasada de `grabar` sólo calienta la caché de API: la buena es la segunda.**
   Comprueba que dos pasadas seguidas dan cero antes de creerle.
3. **`L-047`, y es la que más va a doler.** En esta consola hay comprobadores que leen el CSS con
   expresiones regulares, y **mover un valor de sitio los deja en verde sin significado**. No
   fallan: enmudecen. Pasó **cuatro veces** el 22-sep. **Antes de mover un valor, `grep` del nombre
   de la propiedad por `scripts/` y `engine/tests/`.** Los sitios concretos:
   · **`z-index` de `.intel-popover` (90) y `.event-detail` (100)** — los lee
     `test_ui_navegacion.py:_z_index_de` con `int()`. Tokenizarlos da `ValueError`. Y **ni siquiera
     se les puede poner un comentario que diga `z-index:` con dos puntos**: esa función no quita
     comentarios, y el de `.intel-popover` se salva hoy por ese único carácter.
   · **Los seis `max-width` de `_topes_por_clase`** (`canary-modal-box`, `col-cmd`,
     `field-input-sm`, `filter-select-sm`, `infra-metrics`, `intel-popover`) — sostienen el cero
     duro de anchos muertos. Se ciegan tokenizando el valor **o agrupando el selector**, y esto
     último es más fino de lo que parece: `.x, .y { max-width: 110px }` devuelve `{'y': 110}`, así
     que agrupar pierde **todas menos la última** y el número no llega a cero.
   · **Los comentarios cuentan como código** en cualquier guion que no los quite.
4. **El gancho de pre-commit NO corre la batería si tu commit no lleva un `.py`.**
   `.pre-commit-config.yaml:53` filtra `files: '\.py$'`, así que verás «Run pytest … Skipped» y el
   gancho en verde mientras decenas de pruebas vigilan `index.html`, `main.js` y `tartarus.css`.
   **Corre la batería a mano antes de cada commit de consola.** Está registrado como
   `#pre-commit-ciego-a-los-documentos` (P1·S), con las tres salidas medidas.
5. **Un ancla del ROADMAP va con llaves SÓLO en su definición.** Citarla en prosa con
   `` `{#ancla}` `` la duplica y `test_cada_punto_de_lo_siguiente_apunta_a_su_entrada_del_roadmap`
   deja de saber a cuál mirar. En prosa va sin llaves: `` `#ancla` ``.
6. **`e2e/sin_solapes.spec.ts` vigila que no se encimen letras**, y una reforma de maquetación es
   justo lo que puede meter solapes en silencio. Córrelo a menudo, no al final.
7. **`lxml` recupera**: de un HTML roto te devuelve un árbol correcto, así que no sirve para
   validar. `scripts/revisar_envoltorios.py` usa pila propia y corre dentro de la suite.
8. **Una prueba geométrica en verde no dice cuánta holgura le queda** → `L-039`. El menú de
   «Descargar» llevaba desde el 16-sep cabiendo **por 19 píxeles** con su prueba en verde.

## Cómo se trabaja aquí

- **Verifica en vivo y enseña números**, y verifica **contenidos**, no códigos de respuesta.
- **Guardarraíl en rojo**: ninguna prueba cuenta hasta verla fallar contra su defecto. Y comprueba
  **la causa del color**: que la inyección cambió de verdad el fichero, y contra qué diana corrió.
- **Derivado, no copiado**: las listas se calculan desde el código, no se mantienen a mano.
- **Nunca `git add -A`**: rutas explícitas siempre. Commits en español, sin `Co-Authored-By`,
  excluyendo `presentacion/`. El título dice **qué estaba mal**, no qué tocaste.
- **Nada de borrados masivos en la base sin preguntar a Iván**, y no toques
  `beelzebub/configurations/personalities/portal-gobmx.yml` — trabajo en vivo suyo, sin commitear.
  Un comando destructivo **nunca** se encadena a un `cd`: usa `git -C <ruta>` → `L-029`.
- **🔒 CONGELACIÓN: no se empuja nada al repo de código hasta el 1 de octubre.** Hay un gancho
  `pre-push` que lo impide y caduca solo. El CI está parado por la cuota de Actions, así que **toda
  la verificación es local y el commit tiene que decirlo**. La wiki **sí** se empuja. Respaldo:
  `bash scripts/respaldo_local.sh`.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta sólo si es ambiguo o
  destructivo. Documentación en español claro, sin anglicismos.

## Verificación

```bash
cd engine && python3 -m pytest tests/ -q         # 3.513 pasando · 11 saltadas al 22-sep
TARTARUS_UI_URL=http://localhost:88XX npx playwright test    # 186 pasando, 0 en rojo
python3 scripts/revisar_tokens.py                # 0 de 11 en rojo
python3 scripts/revisar_anchos.py                # 104 campos · 0 sin rótulo · 0 anchos muertos
python3 scripts/revisar_envoltorios.py && python3 scripts/revisar_controles.py
python3 scripts/revisar_rol_consola.py && python3 scripts/validate_docs.py
```

Trinquetes vigentes de tu frente: `revisar_tokens.py::hex_a_pelo` **0**,
`::fuera_de_escala` **61**, `::estilos_en_linea` **335**. **Ninguno sube.** Si sube, se arregla o se
revierte.

## Lo que hay fuera de este frente, para no pisarlo

Hay otras dos sesiones con prompt propio y copia propia, y **ninguna toca `ui/`**:
«puertas de máquina» (`#hmac-exigir`, `#shims-sin-auth`, `#sensor-a-cualquier-cliente`) y la de
campo/RPi5 ([[prompt-sesion-rp5]]).

Del resto del ROADMAP, lo abierto de consola que **no** entra aquí y sigue con ancla:
`#personalidades-menu` (P1·L, 82 controles) · `#identidad-una-sola-vez` (P1·L) ·
`#atacantes-sin-redundancia` (P1·M) · `#api-sin-consola` (P1·M) · `#dos-roles-visibles` (P1·M) ·
`#replicar-en-protocolo` (P1·M) · `#aplicar-a-todos-miente` (P1·S) ·
`#pre-commit-ciego-a-los-documentos` (P1·S) · `#ajustes-unificado` (P2·L, siete modales donde
Thinkst tiene una pantalla) · `#editor-persona-82-controles` (P2·L) ·
`#accion-principal-en-rojo` (P2·S, la acción principal va en el rojo de error) ·
`#campos-que-caben-sin-guion` (P2·S) · `#skill-interfaz` (P2·S).

Al cerrar: skill `destilar-leccion` (**mira cuál es la última antes de numerar** — la última es
`L-050` al cerrar el 23-sep, y hay once copias escribiendo a la vez; pídelo con `destilar_leccion.py --siguiente`), luego `pendientes-roadmap`, y `registrar-plan`
cuando Iván acepte el plan. **La wiki es pública: lee el plan antes de pegarlo ahí.**
