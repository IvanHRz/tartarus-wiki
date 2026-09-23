---
tipo: guia
creado: 2026-09-21
actualizado: 2026-09-21
tags: [sesion, prompt, seguridad, campo]
---

# Prompt para la sesión de las puertas de máquina — `{#hmac-exigir}` · `{#shims-sin-auth}` · `{#sensor-a-cualquier-cliente}`

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
>
> **Por qué éste y no otro.** TARTARUS tiene tres entradas que no usa una persona sino una máquina
> —la ingesta de sensores, el latido y los tres shims de honeypot— y **las tres siguen aceptando a
> quien no se identifica**. No por descuido: cerrarlas de golpe es literalmente lo que dejó nueve
> de los diez honeypots sin cerebro tres días el 13-sep, así que se construyó un contador para
> poder decidir con datos. **El contador ya tiene datos.** Esta sesión es la que los lee y cierra.
>
> Y es lo que bloquea el despliegue de campo: un sensor en casa de un cliente atraviesa internet.
>
> **Se puede correr a la vez que** [[prompt-sesion-diseno]] (toda la consola: `ui/src/`) y
> [[prompt-sesion-rp5]] (la Pi). Ésta es `engine/` y `sensors/`, no toca ni un fichero de los
> suyos. **Necesita el turno de la batería sólo al final.**
>
> Las cifras de abajo están **medidas el 21-sep-2026 por la noche**, en vivo, no copiadas de
> ninguna entrada.

---

Trabajo en TARTARUS, plataforma de decepción (honeypots) para respuesta a incidentes.

Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
Rama `feature/tier0-deployment-readiness`, PR #25. Motor Python/FastAPI en `engine/`, agentes de
campo en `sensors/`, consola JS vanilla en `ui/src`, Postgres, honeypots Beelzebub.
Motor en `localhost:9001`, consola en `localhost:8888`.
Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo propio, **público**).

**Antes de tocar nada**, en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` →
`.agents/COORDINACION.md` (hay más sesiones de Claude en este mismo repo; **declárate ahí con la
plantilla del principio** y comprueba con `python3 scripts/revisar_sesiones.py`) →
`.agents/ROADMAP.md`. Cada sesión trabaja en **su propia copia**:
`scripts/sesion_paralela.sh nueva puertas`. **No hagas `npm install` dentro**: `node_modules` es un
enlace simbólico y lo rompe.

## El encargo: cerrar las tres puertas de máquina, en este orden

### 1 · `{#hmac-exigir}` (P1 · S) — encender la exigencia de firma

Lo que ya está hecho, y es mucho: el motor **comprueba** toda petición firmada (una firma
falsificada se rechaza y lleva marca de tiempo, así que no se puede reinyectar una capturada), el
latido heredado ya declara el verificador desde el 21-sep, y hay un contador **que persiste** y
publica **desde cuándo** vale su cero — porque antes vivía en un diccionario del proceso y «cero»
significaba «nadie desde el último reinicio».

Lo que falta es **quitar una línea** (`TARTARUS_HMAC_ENFORCE=false` de
`docker-compose.dev-mac.yml`) sin tirar a nadie. Y el contador ya dice a quién tirarías:

```
tartarus_ingesta_sin_firmar_desde 1789880405
tartarus_ingesta_sin_firmar_total{ruta="/ingest/sensor",              remitente="192.168.97.1"}   20
tartarus_ingesta_sin_firmar_total{ruta="/sensors/{sensor_id}/heartbeat", remitente="192.168.97.1"}  4
tartarus_ingesta_sin_firmar_total{ruta="/sensors/heartbeat",          remitente="192.168.97.1"}    1
tartarus_ingesta_sin_firmar_total{ruta="/sensors/heartbeat",          remitente="192.168.147.1"}   1
```

**Lo primero es separar el grano de la paja, y hay paja conocida:** parte de esos 20 los metió la
sesión de la base limpia el 21-sep con guiones sueltos de Python que postean sin firmar
(`scripts/sesion_consola.py` abre sesión, pero la ingesta va por HMAC, que es otra cosa). **Un
remitente que es tu propio portátil no es un equipo de campo**, y encender pensando que sí lo es
sería tirar a ciegas al revés. Los `_ultimo` de cada línea distinguen lo vivo de lo viejo.

**Y hay un llamador sin firmar que NO es paja, y está en el código:**

```
engine/engine/deployer.py:198
  echo "*/1 * * * * curl -sf -X POST {engine_url}/sensors/$SENSOR_ID/heartbeat …" | crontab -
```

Un `curl` pelado, instalado por el propio despliegue en cada aparato. **Eso es lo que hay que
firmar antes de encender**, y es la mitad del trabajo de esta sesión. Pasos en
`docs/FIRMA_DE_SENSORES.md`; el ayudante de firma que ya usan los agentes está en `sensors/`.

**La prueba negativa YA NO FALTA** (actualizado el 22-sep): otra sesión escribió
`e2e/latido_sin_firma.spec.ts` esa misma noche — intentar el latido desde fuera **sin firma** y
comprobar qué pasa. Léela antes de escribir nada: lo que queda es que con la exigencia encendida
compruebe que se **rechaza**, no sólo que se apunta. `engine/tests/test_todos_firman.py` ya deriva del código quién
tiene que firmar —no de una lista a mano, que es como se olvidaron los tres shims—: **apóyate en
él, no escribas otra lista.**

### 2 · `{#shims-sin-auth}` (P1 · M) — 🟡 medio hecho: cuentan y no rechazan

Los tres shims (`/v1/{chat,web,mcp}/completions`) son por donde el honeypot le pide cerebro al
motor. Hoy **cuentan** quién llega sin credencial y **no rechazan a nadie**:

```
tartarus_shim_sin_credencial_total{ruta="/v1/chat/completions",honeypot="model:gpt-4o"} 226
```

**Y ya se sabe de quién es buena parte de esas 226, medido el 21-sep por otra sesión: de
`verificar-protocolo`**, que es una skill obligatoria de esta casa. O sea que el contador mezcla
honeypots de verdad con nuestras propias comprobaciones — separarlo es la primera mitad del
trabajo, igual que arriba.

Misma disciplina que arriba: **mira quién es antes de cerrar**. El 13-sep se cerró de golpe una
puerta parecida y nueve de los diez honeypots se quedaron sirviendo la plantilla de reserva
—rápido y con 200 OK, que es lo que lo hizo invisible tres días (`L-028`)—. Si cierras, **la
comprobación es el CONTENIDO de un comando resuelto**, nunca el código de respuesta ni el tiempo.

### 3 · `{#sensor-a-cualquier-cliente}` (P1 · S) — un hueco de tenant, y necesita decisión

`POST /sensors/{sensor_id}/flock` (`engine/engine/sensor_registry_router.py:408`) comprueba el
**rol** con `rbac.can_mutate` inline —por eso el barrido de rol lo da por bueno— pero **no lleva
`Depends(flock_scope)`**: el flock destino llega crudo en el cuerpo. Un `manager` acotado al
cliente A puede mandar el identificador de B y **mover allí el sensor, y con él a quién se le
atribuyen sus alertas**.

Ningún guardarraíl lo ve: `test_rbac_console_writes` pregunta por el rol y
`test_flock_openapi_guard` sólo mira las rutas que **declaran** `flock_id`. Es `L-019` otra vez —
`can_mutate` mira el NIVEL del rol, nunca SOBRE QUÉ cliente se actúa.

**No se arregló a propósito y por eso va el último: quién puede mover un sensor entre clientes es
una decisión de producto.** Mídelo, propón las dos o tres opciones con lo que rompe cada una, y
pregúntale a Iván antes de cambiarlo.

## Lo que esta casa ya aprendió y te va a morder si no lo sabes

1. **Una sonda sin permisos miente.** El 401 se convierte en dato: tapó que nueve de diez
   honeypots estaban muertos. Usa `scripts/sesion_consola.py` y **desconfía del permiso antes que
   del producto**. Si un comando de comprobación no imprime nada, eso **no** es que esté bien.
2. **Verifica el CONTENIDO, no el código de respuesta.** Un honeypot puede dar 200 OK en 0,2 s y
   estar sirviendo la plantilla de reserva (`L-028`, `sustrato-que-miente`).
3. **Un control positivo ejecuta el defecto de verdad** → `L-035`. Si el defecto destruye algo, se
   reproduce **contra el stack desechable** (`scripts/base_limpia.sh`), no contra el de trabajo. El
   21-sep costó la contraseña SMTP de la plataforma, que no es recuperable.
4. **Ninguna prueba cuenta hasta verla fallar contra su defecto**, y hay que comprobar la causa del
   color: que la inyección cambió de verdad el fichero y contra qué diana corrió.
5. **Un guardarraíl verde no dice cuánta holgura le queda** → `L-039`.

## La red que sustituye al CI, y es obligatoria

**No hay CI hasta el 1 de octubre** (cuota de GitHub Actions). Lo único que el CI hacía y el
portátil no era **arrancar sobre una base vacía**, y eso ya existe en local:

```bash
scripts/base_limpia.sh                   # stack aparte, volúmenes vírgenes, sin Beelzebub
DEJAR_EN_PIE=1 scripts/base_limpia.sh    # sin apagar, para mirar la consola en :8877
REPORTERO=line,json PLAYWRIGHT_JSON_OUTPUT_FILE=/tmp/censo/limpia-1.json scripts/base_limpia.sh
python3 scripts/censo_bateria.py --entorno 'limpia=/tmp/censo/limpia-*.json' \
                                 --entorno 'trabajo=/tmp/censo/trabajo-*.json'
```

**Es obligatorio antes de cerrar cualquier sesión que toque `e2e/`**, y esta sesión lo tocará por
la prueba negativa. Tres avisos de uso, los tres medidos:

- **El JSON del censo no se deja en `test-results/`**: Playwright vacía esa carpeta al arrancar y
  se lleva los censos anteriores.
- **El turno es por stack y por pid**, pero **no ve a quien no haya hecho `pull`**. Medido con un
  vigía sobre el `.git` común: otra copia corrió **cinco baterías** dentro de una ventana de
  medición y **tres tandas de cifras se fueron a la basura**. Mira el cerrojo *mientras* mides:
  `ls $(git rev-parse --git-common-dir)/tartarus-e2e*.lock`. **Un número medido bajo contención no
  es el número.**
- **La cifra de la batería se saca, no se cita**: pasó de 162 a 176 en un día.

## Cómo se trabaja aquí

- **Verifica en vivo y enseña números.** Antes de afirmar una causa, mídela.
- **Derivado, no copiado**: las listas se calculan desde el código, no se mantienen a mano.
- **Nunca `git add -A`**: rutas explícitas siempre. Commits en español, sin `Co-Authored-By`.
- **Nada de borrados en la base sin preguntar a Iván**, y no toques la personalidad que él tiene
  sin commitear en la copia principal. Un comando destructivo **nunca** se encadena a un `cd`:
  usa `git -C <ruta>` → `L-029`.
- **🔒 CONGELACIÓN: no se empuja nada al repo de código hasta el 1 de octubre.** Hay un `pre-push`
  que lo impide y caduca solo. Toda la verificación es local y **el commit tiene que decirlo**. La
  wiki **sí** se empuja — y es **pública**: al archivar un plan, fuera valores de `.env`, nombres
  de clientes reales y **la receta reproducible de un fallo que siga abierto**. Esa regla nació
  porque la receta de este mismo agujero del latido estuvo publicada ahí.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta sólo si es ambiguo o
  destructivo — y el punto 3 del encargo **es** de los que se preguntan.

## Verificación

```bash
cd engine && python3 -m pytest tests/ -q     # 3.493 pasando · 11 saltadas al 21-sep noche
python3 scripts/puedo_exigir_firma.py        # el comando que decide si ya se puede encender
curl -s localhost:9001/metrics/tartarus | grep sin_firmar
npx playwright test --list | tail -1         # 176 en 33 ficheros · CERO test.skip
python3 scripts/validate_docs.py && python3 scripts/revisar_sesiones.py
```

Al 21-sep por la noche la batería da **176 · 176 · 176** sobre la base de trabajo y **0 saltadas en
los dos entornos**. Si te sale un fallo, **córrelo cinco veces en solitario antes de acusar a tu
cambio** y mira si hay otra batería corriendo. Los dos conocidos que quedan salen **sólo sobre base
limpia** y no son de motor: `exportacion.spec.ts:40` (`{#menu-descargas-fuera-de-pantalla}`) y
`editor_persona_rotulos.spec.ts:50`/`:64` (`{#rotulos-persona-sin-catalogo}`), los dos de la
consola y entregados medidos.

Al cerrar: skill `destilar-leccion` (la cosecha del plan y el libro de lecciones — **mira cuál es
la última antes de numerar, hay varias copias escribiendo a la vez**; el 21-sep hubo tres
colisiones en dos días), luego `pendientes-roadmap`, y `registrar-plan` cuando Iván acepte el plan.
