# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.

---

Trabajo en **TARTARUS**, plataforma de decepción para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (github.com/IvanHRz/tartarus-wiki — privado)
- Rama: `feature/tier0-deployment-readiness`

## Cómo quiero que trabajes

- **Documentación en español llano**, cronológica, sin tecnicismos ni anglicismos innecesarios.
- **Todo plan aceptado se archiva verbatim** en `wiki/planes/YYYY-MM-DD.md` **antes** de ejecutarlo.
- Actualiza `.agents/ROADMAP.md` (está en .gitignore) y vuélcalo a `wiki/roadmap-operativo.md`.
- **Commits en español, sin `Co-Authored-By`**, excluyendo siempre `presentacion/` (48 MB de binarios).
- **No subas a GitHub hasta que lo pida.**
- **Verifica en vivo contra el stack**, no por suposición. Si mides algo, enséñame el número.
- Avanza sin preguntar de más cuando la dirección sea clara; pregunta solo si es ambiguo o destructivo.

## Arranque del stack

- **`make up-quick`. NUNCA `make up`**: hace `down -v` y **borra la base de datos**.
- El engine está en **`:9001`**, no en 9000 (puerto fantasma de OrbStack). La consola en `:8888`.
- La UI se sirve por bind mount: los cambios en `ui/src` se ven con **Cmd+Shift+R**, sin rebuild.
- Antes de medir tests tras mutar código, **borra `__pycache__`**: un `.pyc` obsoleto ya dio un falso
  verde durante un buen rato.

## Seguridad, sin excepciones

- La clave de OpenAI está en `Entrada/GPT.rtf` y en los YAML de
  `beelzebub/configurations/services/`. Ambas rutas están en `.gitignore`. **El repo de código es
  público.**
- **Al leer esos ficheros para depurar, filtra siempre la salida** (longitudes con `awk`, redacción
  con `sed`). Ya se volcó la clave a la conversación una vez por hacer un `sed` sin filtro.
- **Cualquier borrado masivo en la base: pídemelo a mí antes.**

## Estado al 28 de agosto de 2026

Suite en **1387 pruebas verdes**. Última ventana de observación: 20 minutos con todos los invariantes
en 0 (riesgo descuadrado, detecciones sin flock, eventos sin flock, errores).

Lo cerrado en las dos sesiones anteriores está en `.agents/ROADMAP.md` y en `log.md` de la wiki. En
resumen: atribución de ataques por sensor (puerto → sensor → cliente), reparación de detecciones que
nacían sin cliente, filtrado del ruido de barrido en Discovered Hosts, reparación de una regresión de
CSS mía, y unificación de secciones duplicadas entre pestañas.

---

# Lo que toca hacer, en orden

## 1. AI Settings: la clave se guarda donde nadie la lee — **empieza por aquí**

**Síntoma**: metes la clave de OpenAI en *AI Settings*, pulsas **Test**, y responde
`{"status":"error","message":"No AI provider configured"}`.

**Ya está diagnosticado. No lo vuelvas a investigar desde cero**, solo confírmalo y arréglalo.
La causa está en `engine/engine/settings_router.py`, y son tres capas:

1. `ENV_FILE = Path(__file__).parent.parent.parent / ".env"`. Dentro del contenedor el módulo vive en
   `/app/engine/settings_router.py`, así que tres `.parent` dan `/` → **escribe en `/.env`**, la raíz
   del contenedor.
2. **El `.env` del proyecto no está montado** en el engine. Los únicos montajes son `./engine → /app`
   y `./beelzebub/configurations → /app/bee-config`.
3. **Nadie lee `/.env`**: `docker compose` lee el `.env` del *host*.

Medido en vivo el 28-ago: `/.env` dentro del contenedor tiene `OPENAI_API_KEY` de 164 caracteres, y
`printenv OPENAI_API_KEY` en ese mismo contenedor devuelve **vacío**.

Por eso el fallo despista: al guardar, `llm.configure()` sí configura el cliente **en memoria**, así
que funciona hasta el siguiente reinicio del engine, y luego vuelve a `provider: template` en
silencio.

**Qué quiero:**
- Que la clave **persista de verdad** a través de reinicios (montar el `.env` del host, o apuntar
  `ENV_FILE` a una ruta montada y releerla al arrancar).
- Un **test** que fije que `ENV_FILE` cae dentro de una ruta montada y no en `/`.
- Que la consola **no mienta**: si el proveedor solo vive en memoria, que lo diga.
- Arreglar de paso la casilla **«Beelzebub sync»**: `main.js` llama a
  `POST /api/settings/beelzebub/ai`, endpoint **marcado como DEPRECADO en su propio docstring**
  porque escribe en `.env` y Beelzebub lee la clave del **YAML**. Debe llamar a
  `POST /services/{file}/llm`.

**No confundas los dos LLM.** Son distintos y solo uno está roto:

| | Dónde vive la clave | Estado 28-ago |
|---|---|---|
| **Honeypot (Beelzebub)** | `beelzebub/configurations/services/*.yaml`, campo `openAISecretKey` | **Funciona.** `ssh -p 2222 admin@localhost` responde como `prod-web-01` |
| **Engine (AI Settings)** | debería ser `.env`; hoy `/.env` del contenedor | **Roto** |

El botón **Test** prueba el LLM **del engine**, no el del honeypot.

## 2. Puesta a cero de los flocks, para llevar control

La idea es dejar los clientes a cero, hacer pruebas en **uno o dos como mucho**, llevar un registro
de qué aparece dónde, y **si algo asoma en un cliente que no toqué, investigar por qué**.

**Estado de partida, medido el 28-ago:**

| Flock | Eventos | Detecciones | Cebos | Sensores |
|---|---|---|---|---|
| Default Flock (por defecto) | 1486 | 1019 | 18 | 6 |
| Iván | 1 | 2 | 0 | 0 |
| IR | 0 | 0 | 0 | 0 |
| Pruebita | 0 | 0 | 0 | 0 |

Fíjate: **IR y Pruebita ya están a cero**. Lo que se veía dentro de IR era el bug de
`.admin-section` (auditoría y notificaciones visibles en todos los clientes), **ya reparado**.

**Tres cosas que hay que respetar al hacer la limpieza:**

- **`sensor_registry` NO se vacía.** Sus 6 filas sostienen la atribución por puerto: sin ellas, todo
  el tráfico vuelve a caer en el flock por defecto y perdemos lo construido el 27-ago.
- **13 tablas llevan `flock_id`**: `breadcrumbs`, `canary_tokens`, `correlation_sessions`,
  `detections`, `events`, `flock_assignments`, `honey_credentials`, `hosts`, `kill_chain_traces`,
  `notify_config_flock`, `remote_sensors`, `sensor_registry`, `users`. Un borrado parcial deja
  huérfanos.
- **Respaldo antes, recuentos antes y después.** Y **pídeme confirmación explícita** antes de
  ejecutar el borrado: es masivo.

**Qué quiero como entregable:**
- Un **script de puesta a cero** reproducible (respaldo → borrado → verificación), no comandos
  sueltos, para poder repetirlo cada vez que empecemos una tanda de pruebas.
- Un **registro de pruebas** en la wiki: qué ataqué, contra qué puerto, y en qué cliente apareció.
- Configurar **un cliente de prueba con su propio puerto** registrado en `sensor_registry`, para
  poder comprobar el aislamiento de verdad: si ataco el puerto de A, no debe aparecer nada en B.

## 3. Verificación de aislamiento (el objetivo real de lo anterior)

Tras la puesta a cero, la prueba que de verdad importa: **atacar el sensor de un cliente y comprobar
que no aparece nada en los demás**. Si aparece, hay que averiguar por qué — y esa es la pregunta que
llevo haciendo desde el principio.

Si algo asoma donde no debe, sospecha primero de estos dos patrones, que ya han aparecido dos veces:

- **Contenido global pintado dentro de la vista de un cliente** (no es filtración de datos, es que la
  consola no distingue lo de la plataforma de lo del cliente). Ya rotulados así: los honeypots de
  Beelzebub y el corpus de reglas del motor.
- **Endpoints que no aceptan `flock_id`**: hay **62 de 91 endpoints GET** sin filtro por cliente.
  Está en el ROADMAP como pendiente, con el inventario.

## 4. Pendientes menores, si queda tiempo

- `.canary-field` y `.canary-report-save` no existen en el CSS (faltan **desde antes** de estas
  sesiones; están en la lista de excepciones del test que vigila las clases fantasma).
- 22 eventos sin sensor: Prometheus (2113) y Modbus (502) no están en `sensor_registry`.
- Los 1424 eventos históricos siguen sin traducir.
- Error al crear un flock con nombre duplicado.
- **Beelzebub, dos límites ya documentados y sin arreglo por configuración** (v3.9.0): no mantiene
  estado de sesión (`cd` no funciona) y **no persiste su clave de host**, así que al reconectar por
  SSH salta `REMOTE HOST IDENTIFICATION HAS CHANGED`. Desbloqueo:
  `ssh-keygen -R "[localhost]:2222"`. Lo segundo **delata el honeypot** y merece una solución real
  algún día (volumen para las claves, o fork).

---

**Empieza confirmando el diagnóstico de AI Settings en vivo** (con la salida filtrada) y proponme el
plan. No ejecutes la puesta a cero hasta que yo la confirme.
