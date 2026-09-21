---
tipo: guia
creado: 2026-09-20
actualizado: 2026-09-20
tags: [sesion, prompt, bateria]
---

# Prompt — sesión «la batería, una a la vez»

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> **Esta sesión NECESITA el stack** y el turno de la batería en exclusiva. La otra de esta noche
> ([[prompt-sesion-rol-consola]]) no lo necesita: podéis correr a la vez.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
- Rama única: **`feature/tier0-deployment-readiness`**. Motor Python/FastAPI en `engine/`, consola
  JS sin frameworks en `ui/src/`, Postgres, Beelzebub. Motor en `:9001`, consola en `:8888`.
- Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus`.

## Antes de nada

Lee en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` → `.agents/COORDINACION.md` →
la cabecera de `.agents/ROADMAP.md`.

**Crea tu propia copia de trabajo y decláratela** — no trabajes en `/Users/ivanhuerta/Documents/Tartarus`:

```bash
cd /Users/ivanhuerta/Documents/Tartarus
scripts/sesion_paralela.sh nueva bateria        # crea ../Tartarus-bateria
# declara tu sección en .agents/COORDINACION.md con la plantilla del principio
python3 scripts/revisar_sesiones.py             # tiene que salir verde
```

**No hagas `npm install` dentro de tu copia**: `node_modules` es un enlace simbólico y lo rompe.

## Tres cosas que tienes que saber antes de empezar

1. **NO HAY CI.** GitHub Actions no arranca ningún trabajo desde las 06:20Z del 20-sep por un
   problema de facturación de la cuenta (`#ci-caido-por-facturacion`). **Toda verificación es
   local y el commit tiene que decirlo.** Y duele justo aquí: el CI es lo único que corre sobre
   una **base vacía**, que es donde se ven los fallos que el portátil esconde.
2. **Hay otras sesiones en el mismo repo.** Lee `.agents/COORDINACION.md` y anota ahí qué vas a
   tocar **antes** de tocarlo. Y ojo: ese fichero **viaja por rama**, así que si alguien sale de
   otra rama no os veis.
3. **Nunca `git add -A`.** Rutas explícitas. Commits en español, sin `Co-Authored-By`.
   Y **no toques `beelzebub/configurations/personalities/portal-gobmx.yml`**: es trabajo en vivo
   de Iván. (Esta madrugada un `git reset --hard` mal dirigido se lo llevó por delante; se
   recuperó del alijo del pre-commit, pero no lo repitas.)

## Tu trabajo: `{#bateria-sigue-intermitente}` (P1)

**La batería no da el mismo número dos veces.** Medido: `155 · 153 · 157` en tres pasadas
seguidas con el stack en exclusiva. Cada fallo cuesta media hora de descarte a quien lo pilla, y
lo pilla todo el mundo: es lo que más estorba del repo ahora mismo.

**No son un defecto, son varios.** Ya hay dos cerrados con veredicto y su causa escrita en la
entrada del ROADMAP, y de ellos sale lo más útil que te puedo dar:

- **`fases_coherentes.spec.ts:96`** comparaba dos poblaciones distintas (el informe suma TODOS los
  sucesos; el VRA esconde por defecto a los atacantes revisados, y cada fichero marca su IP al
  terminar). «Dos números correctos, leídos seguidos, parecen una contradicción.»
- **`menu_usuario.spec.ts:79`** y **`notificaciones.spec.ts:119`** son **`#rafaga-carga-inicial`
  vestido de intermitencia**: al arrancar salen 18 cargadores y 33 peticiones en vuelo con sólo 6
  conexiones por host, así que un endpoint de 7 ms tarda **15,2 s** y el `expect.poll` de 15 s se
  queda en el filo. Esa entrada **deja de ser una molestia de arranque: es la causa raíz de al
  menos dos de estos fallos**.

**Especímenes sin perseguir:** `ventana_tiempo.spec.ts:135` (1 de 3 pasadas, 5 de 5 en solitario)
y los que caigan en tu primera pasada.

### Cómo se trabaja esto aquí

Lee primero la skill **`perseguir-intermitente`** (`.claude/skills/perseguir-intermitente/`).
Sus reglas, que no son negociables:

- **Una intermitencia no se cierra con «ya no lo vi».** Se cierra con un **veredicto** —producto
  o prueba— y su evidencia.
- **Córrelo cinco veces en solitario** antes de opinar. Si pasa 5 de 5 solo y falla acompañado,
  el defecto es de interferencia, no de la prueba.
- **Instrumenta el navegador en vez de deducir.** Si crees que hay una carrera, demuéstralo con un
  `MutationObserver` o con marcas de tiempo, no con una corazonada. (Ayer yo gasté varias pasadas
  instrumentando el DOM por una intermitencia que resultó ser **la aserción**, no una carrera:
  pedía `'RUTA'` y las mayúsculas las ponía el CSS. Es `L-026`. **Antes de instrumentar, lee la
  aserción y pregunta de qué depende su valor aparte del código que dices estar probando.**)
- **No subas un `timeout` ni metas un `waitForTimeout` para que pase.** La batería **no reintenta**
  ni aquí ni en el CI, y es deliberado: un verde al segundo intento es un defecto que sólo se ve a
  ratos.

### Lo que reclamas y lo que no tocas

- **Reclamas:** `e2e/*.spec.ts` y lo que el veredicto señale. El **turno de la batería** —lo toma
  `sesion.setup.ts` solo, pero anúncialo en COORDINACION porque el stack es uno.
- **No tocas:** `ui/src/js/*.js` ni `scripts/rol_*` (los lleva la otra sesión de esta noche),
  `ui/src/index.html` ni `ui/src/css/` (los lleva OpenCode), `beelzebub/`, la Raspberry.

### Cómo sabes que has terminado

```bash
cd /Users/ivanhuerta/Documents/Tartarus-bateria
npx playwright test                      # desde la RAÍZ; hoy son 162 pruebas en 31 ficheros
```

Tres pasadas seguidas con el mismo número. **No cites «142/142»**: esa cifra no se reproduce desde
el 17-sep y está desmentida por escrito en `CLAUDE.md`.

Y al cerrar: `destilar-leccion` (con su `### Cosecha` en el plan archivado) **antes** de
`pendientes-roadmap`.
