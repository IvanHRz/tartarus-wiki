---
tipo: guia
creado: 2026-09-20
actualizado: 2026-09-20
tags: [sesion, prompt, rol, consola]
---

# Prompt — sesión «el rol no llega al hub de despliegue»

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> **Esta sesión NO necesita la batería de navegador** hasta el final, así que no compite por el
> turno con [[prompt-sesion-bateria]]. Podéis correr a la vez.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `~/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
- Rama única: **`feature/tier0-deployment-readiness`**. Motor Python/FastAPI en `engine/`, consola
  JS sin frameworks en `ui/src/`. Motor en `:9001`, consola en `:8888`.
- Wiki aparte: `~/Documents/Wikis/wiki-tartarus`.

## Antes de nada

Lee en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` → `.agents/COORDINACION.md` →
la cabecera de `.agents/ROADMAP.md`. Y la skill **`rol-que-no-miente`**, que es tuya entera.

**Crea tu propia copia de trabajo y decláratela:**

```bash
cd ~/Documents/Tartarus
scripts/sesion_paralela.sh nueva rol            # crea ../Tartarus-rol
# declara tu sección en .agents/COORDINACION.md con la plantilla del principio
python3 scripts/revisar_sesiones.py             # tiene que salir verde
```

**No hagas `npm install` dentro de tu copia**: `node_modules` es un enlace simbólico y lo rompe.

## Tres cosas que tienes que saber antes de empezar

1. **NO HAY CI.** GitHub Actions no arranca ningún trabajo desde las 06:20Z del 20-sep por
   facturación de la cuenta (`#ci-caido-por-facturacion`). Verificación local, y que el commit lo
   diga.
2. **Hay otras sesiones en el mismo repo.** `.agents/COORDINACION.md`, y **se inserta con anclas,
   nunca se reescribe entero**: una reescritura desde una lectura vieja borra lo de otro y git la
   acepta sin decir nada.
3. **Nunca `git add -A`.** Rutas explícitas. Commits en español, sin `Co-Authored-By`.
   No toques `beelzebub/configurations/personalities/portal-gobmx.yml`: trabajo en vivo de Iván.

## Tu trabajo: `{#rol-fuera-de-main-js}` (P1·M) + `{#controles-sin-selector}` (P3·XS)

**El reparto por rol se derivó del código y cubre 63 controles — pero sólo mira un fichero.**
`scripts/revisar_rol_consola.py` analiza **sólo `ui/src/js/main.js`**. En `ui/src/js/` hay **8
ficheros nuestros** (más `chart.umd.js`, que es librería de terceros).

**Y el que falta es el que importa.** `deploy_hub.js` tiene **cinco `fetch` mutantes** —
`POST /api/scan`, `/api/honey-credentials`, `/api/canary-tokens/bundle`, `/api/deploy/execute`,
`/api/deploy/generate`— sobre controles como `#btnDplDeploy` que **nacen por `innerHTML`** y a los
que `aplicarRol()` **no llega nunca**, porque abrir el modal no la llama.

**Es el mismo fallo estructural del popover de una IP, en un tercer sitio.** Hoy queda contenido
sólo porque `#btnDeployOpen` y `#btnDeployFromHub` están declarados como aperturas — o sea, **por
la lista a mano que este trabajo vino a quitar**. Es contención por accidente, no por diseño.

### La decisión que traes tú

Un listener de `deploy_hub.js` puede tener su receptor en `main.js`, y al revés. Hay que decidir
si el grafo control→ruta es **por fichero o común**, y escribir por qué. El analizador ya acepta
varios ficheros; el coste está en esa decisión, no en el código.

### De propina, `{#controles-sin-selector}`

Viven en tus mismas líneas: `ui/src/js/main.js:8213` y `:8326` son dos
`document.createElement('button')` sin selector estable. Darles un `id` baja el trinquete
`TOPES["revisar_rol_consola.py::sin_resolver"]`.

> **⚠️ Baja de 3 a 1, NO a 0**, y el ROADMAP dice que a 0. El tercero (`:4320`) es una variable
> que el analizador no puede seguir y un `id` no lo arregla. **Si te sale 0, hiciste algo que no
> tocaba.**

> **⚠️ Y dar el `id` no basta.** Un botón que nace al abrir un modal no pasa por `aplicarRol()`,
> que corre al arrancar la consola. Hay que llamarla **después** de meter el modal en el
> documento, o el botón sale vivo para quien no puede usarlo — que es peor que antes, porque el
> comprobador se pone verde. Ése es el modo de fallo de esta tarea: **salir verde estando mal.**

### Lo que reclamas y lo que no tocas

- **Reclamas:** `scripts/rol_consola_ast.js`, `scripts/revisar_rol_consola.py`,
  `ui/src/js/deploy_hub.js`, el bloque de rol de `ui/src/js/main.js` (y sus `:8213`/`:8326`),
  `engine/tests/test_rol_en_consola.py`.
- **No tocas:** `e2e/*.spec.ts` (los lleva la otra sesión), `ui/src/index.html` ni
  `ui/src/css/tartarus.css` (los lleva OpenCode en `../Tartarus-oc`), `engine/engine/`,
  `beelzebub/`, la Raspberry.

### Cómo sabes que has terminado

```bash
python3 scripts/revisar_rol_consola.py            # «Todo control que escribe está capado ✓»
python3 scripts/revisar_rol_consola.py --escribir # la tabla se DERIVA, jamás se escribe a mano
cd engine && python3 -m pytest tests/ -q          # 3.408 pasando, 11 saltadas
```

Y **en el navegador, con un usuario `watcher`**: abrir el hub de despliegue y ver los cinco
controles grises. Eso **ninguna prueba de Python lo puede ver**, y es exactamente por lo que este
agujero llevaba abierto tres sitios seguidos.

Guardarraíles: la skill **`guardarrail-en-rojo`** es obligatoria si tocas `engine/tests/` o `e2e/`
— **verlo en ROJO contra su defecto**, y lee su §6 y §7, que son de ayer y van de esto:
un detector que no sigue a los ayudantes locales, y una aserción que enumera lo que había en tu
base en vez de comprobar la forma.

Y al cerrar: `destilar-leccion` (con su `### Cosecha`) **antes** de `pendientes-roadmap`.
