---
tipo: guia
creado: 2026-09-23
actualizado: 2026-09-23
tags: [sesion, prompt, seguridad, campo]
---

# Prompt para la sesión del secreto por sensor — `{#un-secreto-por-sensor}` · `{#hub-deja-el-aparato-mudo}`

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
>
> **Por qué éste y no otro.** La firma HMAC **se exige desde el 22-sep**, y eso cambió la
> naturaleza de este pendiente: mientras no se exigía, un secreto compartido era una dureza que
> faltaba; ahora es **el camino crítico del despliegue de campo**. Un aparato sin secreto no
> reporta —401 y silencio— y el alta (`POST /sensors/enroll`) ata identidad y cliente pero **no
> entrega ninguno**. O sea que hoy la única forma de que un aparato nuevo hable es meterle a mano
> el secreto de toda la flota, y cada despliegue multiplica el daño de que uno caiga en malas
> manos.
>
> **Y es lo que desbloquea el hub.** Iván decidió el 23-sep que el guion de despliegue lleve el
> **token de un solo uso** y **nunca** el secreto. Con secreto por sensor eso pasa a ser trivial;
> sin él, no se puede hacer bien. El orden importa y está escrito en el ROADMAP.
>
> **Se puede correr a la vez que** las sesiones de consola (`ui/src/`) y la de la Pi. Ésta es
> `engine/engine/` y `sensors/`, y **no toca ni un fichero de interfaz**.
>
> Las cifras de abajo están **medidas el 23-sep-2026**, en vivo.

---

Trabajo en TARTARUS, plataforma de decepción (honeypots) para respuesta a incidentes.

Código: `~/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**). Rama
`feature/tier0-deployment-readiness`, PR #25. Motor Python/FastAPI en `engine/`, agentes de campo
en `sensors/`, consola JS vanilla en `ui/src`, Postgres, honeypots Beelzebub.
Motor en `localhost:9001`, consola en `localhost:8888`.
Wiki aparte: `~/Documents/Wikis/wiki-tartarus` (repo propio, **público**).

**Antes de tocar nada**, en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` →
`.agents/COORDINACION.md` (hay más sesiones de Claude en este repo; **declárate ahí con la
plantilla del principio** y comprueba con `python3 scripts/revisar_sesiones.py`) →
`.agents/ROADMAP.md`. Cada sesión trabaja en **su propia copia**:
`scripts/sesion_paralela.sh nueva secreto`. **No hagas `npm install` dentro**: `node_modules` es un
enlace simbólico y lo rompe.

## El encargo

### 1 · `{#un-secreto-por-sensor}` (P1 · M) — el secreto deja de ser uno para todos

Hoy `TARTARUS_HMAC_SECRET` es **uno compartido**: un sensor robado o comprometido puede firmar
como cualquier otro, **incluido el de otro cliente**. La entrada del ROADMAP ya trae el cómo
—columna de secreto en `sensor_registry`, alta que lo genera y lo entrega **una sola vez**, y que
el verificador elija por `X-Tartarus-Sensor-Id` con el compartido **como respaldo durante la
migración**—. Léela entera antes de empezar: tiene el porqué y el orden.

**El riesgo de esta sesión, y es de verdad:** la firma ya se exige. Un paso mal dado deja mudo al
equipo de campo que ya está reportando, y **mudo no grita**. El respaldo al secreto compartido no
es cortesía: es lo que permite migrar sin ventana de silencio. Compruébalo antes de quitarlo.

### 2 · `{#hub-deja-el-aparato-mudo}` (P1 · M) — sólo DESPUÉS del punto 1

Está medido a fondo en el ROADMAP y hay tres cosas que conviene no redescubrir: el hub **ni
siquiera llega a pedir el guion** hoy, enrolarse **no basta** para reportar, y minar el token
obliga a cambiar la firma del endpoint. La decisión de producto ya está tomada y escrita ahí.

**Ojo con el reclamo:** `deploy_router.py` aparece pedido por `skills-y-campo` en un bloque suyo, y
su **misma sección** dice arriba que no toca `engine/engine/`. **Pregunta en `COORDINACION` cuál
vale antes de tocarlo.** `engine/engine/deployer.py` sí está libre.

### 3 · Si sobra tiempo, dos baratos y libres

- `{#el-gancho-no-ve-los-documentos}` (P2 · XS): un commit que sólo toca `.agents/*.md` **se salta
  la suite entera**, y hay pruebas cuyo único objeto son esos documentos. Pasó el 22-sep: tres
  quedaron en rojo y aparecieron al día siguiente **atribuidas a otro commit**. Es `L-040`.
- `{#shim-sin-identidad-de-honeypot}` (P2 · S): localizado a **tres líneas** de Go y con el nombre
  ya decidido. Lo único caro es que **reinicia Beelzebub** y corta las sesiones SSH; avísalo.

## Lo que esta casa ya aprendió y te va a morder si no lo sabes

1. **Verifica el CONTENIDO, no el código de respuesta.** Un honeypot puede dar 200 OK en 0,2 s y
   estar sirviendo la plantilla de reserva (`L-028`). Y un sensor mudo devuelve 401 sin que nadie
   mire.
2. **Un control positivo ejecuta el defecto de verdad** → `L-035`. Si destruye algo, se reproduce
   contra el stack desechable (`scripts/base_limpia.sh`), no contra el de trabajo.
3. **Ninguna prueba cuenta hasta verla fallar contra su defecto**, y hay que comprobar la causa
   del color.
4. **Un comprobador que lee el código de otro fichero tiene que desnudarlo antes de buscar**
   (`L-003`, tres evidencias). El ayudante está en `scripts/codigo_desnudo.py` y **su salida vuelve
   a parsear** desde el 22-sep, así que sirve también para detectores que reanalizan.
5. **Una sonda sin permisos miente.** Usa `scripts/sesion_consola.py` y desconfía del permiso antes
   que del producto. Si un comando de comprobación no imprime nada, eso **no** es que esté bien.
6. **`make` ya distingue tu copia del stack** (22-sep): `test`, `e2e` y `verify` miran **tu**
   árbol; compose mira el del stack y avisa. Si traes un verde de `make test` anterior a esa
   fecha, era del árbol de otro.

## La red que sustituye al CI, y es obligatoria

**No hay CI hasta el 1 de octubre** (cuota de GitHub Actions). Lo único que el CI hacía y el
portátil no era arrancar sobre una base vacía, y eso existe en local:

```bash
scripts/base_limpia.sh                   # stack aparte, volúmenes vírgenes, sin Beelzebub
REPORTERO=line,json PLAYWRIGHT_JSON_OUTPUT_FILE=/tmp/censo/limpia-1.json scripts/base_limpia.sh
python3 scripts/censo_bateria.py --entorno 'limpia=/tmp/censo/limpia-*.json' \
                                 --entorno 'trabajo=/tmp/censo/trabajo-*.json'
```

**Obligatorio antes de cerrar cualquier sesión que toque `e2e/`.** Tres avisos medidos:

- **`REPORTERO` es variable de `base_limpia.sh`, no de Playwright.** Para una pasada suelta hace
  falta `--reporter=line,json`; si no, el censo no se escribe y te enteras al final.
- **El JSON del censo no se deja en `test-results/`**: Playwright vacía esa carpeta al arrancar.
- **El turno es por stack y por pid**, y no ve a quien no haya hecho `pull`. Mira el cerrojo
  *mientras* mides: `ls $(git rev-parse --git-common-dir)/tartarus-e2e*.lock`.

## Cómo se trabaja aquí

- **Verifica en vivo y enseña números.** Antes de afirmar una causa, mídela.
- **Derivado, no copiado**: las listas se calculan desde el código, no se mantienen a mano.
- **Nunca `git add -A`**: rutas explícitas siempre. Commits en español, sin `Co-Authored-By`.
- **Nada de borrados en la base sin preguntar a Iván**, y un comando destructivo **nunca** se
  encadena a un `cd`: usa `git -C <ruta>` → `L-029`.
- **🔒 CONGELACIÓN: no se empuja nada al repo de código hasta el 1 de octubre.** Hay un `pre-push`
  que lo impide y caduca solo. El commit tiene que decirlo.
- **La wiki SÍ se empuja, y es PÚBLICA.** Al archivar un plan: fuera valores de `.env`, nombres de
  clientes reales, **direcciones de despliegues vivos** y **la receta reproducible de un fallo que
  siga abierto**. El *qué* se cuenta; el *cómo tumbarlo* va al ROADMAP, que es privado.
  **Esto ya falló dos veces** (`{#receta-publicada-otra-vez}`): las dos por revisar de memoria en
  vez de con una lista. Revisa el texto **buscando anclas abiertas**, no sólo credenciales.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta sólo si es ambiguo o
  destructivo — y el reclamo de `deploy_router.py` **es** de los que se preguntan.

## Verificación

```bash
cd engine && python3 -m pytest tests/ -q     # 3.575 pasando · 11 saltadas al 23-sep
python3 scripts/puedo_exigir_firma.py        # vigila que nadie se quede mudo
curl -s localhost:9001/metrics/tartarus | grep -E "sin_firmar|sin_credencial"
npx playwright test --list | tail -1         # 179 en 34 ficheros · CERO test.skip
python3 scripts/revisar_guardarrailes.py     # forma 1 tiene que seguir en CERO duro
python3 scripts/validate_docs.py && python3 scripts/revisar_sesiones.py
```

**Y la comprobación que de verdad cierra esta sesión**, porque es la que el sistema no da solo:
que el equipo de campo **siga reportando** después de migrarlo, mirando el contenido —su último
latido en la consola— y no el código de respuesta. Hay un equipo físico dado de alta y activo; su
dirección está en el ROADMAP, no aquí.

Al cerrar: skill `destilar-leccion` (mira cuál es la última lección antes de numerar, hay varias
copias escribiendo a la vez), luego `pendientes-roadmap`, y `registrar-plan` cuando Iván acepte el
plan.
