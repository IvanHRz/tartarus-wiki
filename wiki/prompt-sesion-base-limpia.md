---
tipo: guia
creado: 2026-09-20
actualizado: 2026-09-20
tags: [sesion, prompt, bateria, ci, base-limpia]
---

# Prompt — sesión «la batería contra una base recién nacida»

> **⚠️ Esta wiki es PÚBLICA** (`IvanHRz/tartarus-wiki`) y el repo de código no. Antes de archivar
> aquí un plan o una bitácora, léelo y quita credenciales, clientes reales y la receta de un fallo
> abierto — regla 0 del schema.
>
> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> **Esta sesión NECESITA el turno de la batería** aunque levante su propio stack: el cerrojo lo
> toma igual (ver abajo). Es la continuación natural de [[prompt-sesion-bateria]].

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
- Rama única: **`feature/tier0-deployment-readiness`**. Motor Python/FastAPI en `engine/`, consola
  JS sin frameworks en `ui/src/`, Postgres, Beelzebub. Motor en `:9001`, consola en `:8888`.
- Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus`.

## Antes de nada

Lee en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` → `.agents/COORDINACION.md` →
la cabecera de `.agents/ROADMAP.md`.

**Crea tu propia copia de trabajo y decláratela:**

```bash
cd /Users/ivanhuerta/Documents/Tartarus
scripts/sesion_paralela.sh nueva limpia         # crea ../Tartarus-limpia
# declara tu sección en .agents/COORDINACION.md con la plantilla del principio (se INSERTA)
python3 scripts/revisar_sesiones.py             # tiene que salir verde
```

**No hagas `npm install` dentro de tu copia**: `node_modules` es un enlace simbólico y lo rompe.

## Tres cosas que tienes que saber antes de empezar

1. **NO HAY CI HASTA EL 1 DE OCTUBRE.** No es una avería: se agotó la cuota de GitHub Actions de
   la cuenta y no se renueva hasta entonces (`#ci-caido-por-facturacion`). Ya está mitigado —
   `paths-ignore` para documentos y los seis trabajos con `if: … draft == false`— pero **hasta
   octubre toda verificación es local y el commit tiene que decirlo**.
2. **NO SE EMPUJA A GITHUB HASTA EL 1 DE OCTUBRE.** Hay un gancho de `pre-push` puesto el 20-sep
   a las 23:41 que lo impide y **caduca solo** ese día. No es un error: empujar ahora no verifica
   nada y gasta cuota. **Commitea normal** — y para que las demás copias lo vean, adelanta la rama
   **en local**: `git -C /Users/ivanhuerta/Documents/Tartarus merge --ff-only <tu commit>` (mira
   antes que no pise nada sin commitear). Si de verdad hiciera falta: `TARTARUS_PERMITIR_PUSH=1`.
   **La wiki sí se empuja**: es otro repo y no tiene Actions.
3. **Hay otras sesiones en el mismo repo.** `.agents/COORDINACION.md`, y **se inserta con anclas,
   nunca se reescribe entero**: una reescritura desde una lectura vieja borra lo de la otra y git
   la acepta sin decir nada. Ojo: ese fichero **viaja por rama**.
4. **Nunca `git add -A`.** Rutas explícitas. Commits en español, sin `Co-Authored-By`.
   Y **no toques `beelzebub/configurations/personalities/portal-gobmx.yml`**: es trabajo en vivo
   de Iván, sin commitear, y un `git reset --hard` mal dirigido ya se lo llevó una vez (`L-029`).
   Comando que borra → ruta explícita, nunca encadenado a un `cd`.

## Tu trabajo: correr la batería entera contra una base vacía

**Lo único que el CI hacía y el portátil no es arrancar sobre una base recién nacida.** Aquí hay
meses de datos —~75.000 filas de auditoría, seis clientes, sucesos de todas las pasadas— y una
prueba escrita contra eso pasa cinco veces en local y se cae en el CI. Es `L-027`, y van tres.

Desde el 20-sep por la noche esa red existe otra vez en local:

```bash
scripts/base_limpia.sh                  # levanta un stack aparte, corre la batería, lo apaga
scripts/base_limpia.sh e2e/x.spec.ts    # sólo un fichero
DEJAR_EN_PIE=1 scripts/base_limpia.sh   # no apagar, para mirar la consola en :8877
```

Proyecto de compose distinto y volúmenes propios, así que **el stack de trabajo no se toca**.
Beelzebub no se levanta, igual que hacía el CI.

**Lo que nadie ha hecho todavía es correrla ENTERA contra esa base.** Sólo se ha probado un
fichero (5 passed, 1 skipped). La batería son **162 pruebas en 31 ficheros** y contra la base de
trabajo da **162 · 162 · 162** desde anoche.

### Lo que esa pasada tiene que contestar, en este orden

**1. ¿Cuáles de los siete `test.skip` condicionales disparan con la base vacía?**
`{#saltos-que-dependen-del-stack}` (P3) está anotado como **no reproducido** justo porque en seis
pasadas sobre la base de trabajo hubo **cero saltadas**, y la siguiente medición escrita ahí es
exactamente ésta. El criterio para juzgarlos es `L-022`: **un salto legítimo se cumple en UN
entorno y en el otro no; si se cumple en los dos, es una prueba borrada sin borrarla.**

Ya hay uno confirmado y sirve de patrón: **`auditoria.spec.ts:42`** (`total < 2`, «hay menos de
dos páginas de auditoría para recorrer»). Con 75.000 filas aquí **nunca se salta**; con una base
limpia **siempre**, porque cinco filas no hacen segunda página. O sea que la paginación **no se
ejercitaba nunca en el entorno que era el CI**. Es correcto que se salte, y aun así es `L-022`
esperando: la salida es **sembrar** las filas que la prueba necesita en vez de saltarse.

Los otros seis, con su condición: `equipos_en_la_red.spec.ts:62` (inventario de `hosts` vacío —
y `escaner`/`deploy_hub` lanzan barridos **reales** en la misma pasada),
`ventana_tiempo.spec.ts:242` (la banda dice 0 sucesos), `trampas.spec.ts:46` y `:73` (qué persona
tiene aplicada cada honeypot — **con la base limpia no hay YAML de servicios versionados, así que
esperan saltar**), `notificaciones.spec.ts:101` (si hay contraseña SMTP guardada).

**2. ¿Qué se cae con la base vacía y aquí pasa?** Eso **no** es una prueba nerviosa: es el defecto
que el CI cazaba y hoy nadie caza. Mira primero si la aserción **enumera datos que sólo tienes tú**
(`L-027`), antes de instrumentar nada.

**3. Los cinco especímenes sin veredicto de `{#bateria-sigue-intermitente}`** (P2):
`fases_coherentes:60`, `trampas:86`, `analisis_ia:106`, `deploy_hub:119`, `equipos_en_la_red:106`.
Dejaron de salir tras arreglar el motor anoche, pero **nadie les dio veredicto** y «ya no lo vi»
no cierra una intermitencia. Una base limpia es donde más probable es que vuelvan a enseñarse.

### Un detalle que te va a morder si no lo sabes

**`base_limpia.sh` toma el turno de la batería aunque use su propio stack.**
`e2e/sesion.setup.ts` llama a `tomarTurno()` sin mirar contra qué stack corre, y el cerrojo vive
en el `.git` **común** a todas las copias. Consecuencias: (a) si otra sesión está corriendo la
batería, tu pasada limpia **muere en el arranque**; (b) mientras corres tú, bloqueas la suya **sin
necesidad**, porque no compartís ni base ni motor. Anúncialo en COORDINACION. Si te estorba, es
una entrada de ROADMAP de esfuerzo XS —que el turno se pida sólo cuando `TARTARUS_UI_URL` apunta
al stack de trabajo— y **mídelo antes de escribirlo**.

## Cómo se trabaja esto aquí

Skills obligatorias: **`perseguir-intermitente`** (el método entero: cinco pasadas en solitario,
línea base, instrumentar en vez de deducir, y **veredicto** producto-o-prueba con su evidencia; y
sus dos secciones nuevas de anoche) y **`guardarrail-en-rojo`** para todo lo que toques de `e2e/`
o `engine/tests/`.

- **Nada de subir un `timeout`, meter un `waitForTimeout` ni usar `PLAYWRIGHT_RETRIES`.** La
  batería no reintenta a propósito.
- **Un salto que quites se ve en ROJO contra el defecto que dice vigilar.** Si no, es la misma
  prueba muerta con otra cara.
- **Antes de acusar a una prueba, mira si el motor está saturado.** Anoche el 100 % de los fallos
  de un espécimen eran del motor, no de la prueba: `docker stats tartarus-engine` (100 % de un
  núcleo = bucle de eventos) y cronometra un endpoint trivial. Y para encontrar al culpable,
  **cronometra todos los endpoints en reposo y ordénalos** (`L-031`).

## Lo que reclamas y lo que no tocas

- **Reclamas:** `e2e/*.spec.ts`, `e2e/apoyo.ts`, `scripts/base_limpia.sh`,
  `docker-compose.limpio.yml`, y lo que el veredicto señale. El **turno de la batería**.
- **No tocas:** `ui/src/js/*.js` y `scripts/rol_*` (sesión `rol`, en `../Tartarus-rol`),
  `ui/src/index.html` y `ui/src/css/` (OpenCode, en `../Tartarus-oc`), `beelzebub/`, la Raspberry.
  `engine/engine/` **sólo si un veredicto lo señala y lo hablas antes**.

## Cómo sabes que has terminado

```bash
scripts/base_limpia.sh                                   # la batería entera, base vacía
cd /Users/ivanhuerta/Documents/Tartarus-limpia && npx playwright test   # y contra la de trabajo
```

Las dos verdes, **y el recuento de saltadas de cada una escrito y explicado** — que es el
entregable de verdad de esta sesión: hoy nadie sabe cuál es. **No cites «142/142»**: no se
reproduce desde el 17-sep y está desmentido en `CLAUDE.md`. La referencia buena es
**162 · 162 · 162 en 1,8 min** sobre la base de trabajo (20-sep, noche).

Si `base_limpia.sh` se vuelve parte del cierre de toda sesión, dilo en `CLAUDE.md` — con el CI
apagado hasta octubre, es la única red que queda.

Y al cerrar: `destilar-leccion` (con su `### Cosecha` en el plan archivado) **antes** de
`pendientes-roadmap`.
