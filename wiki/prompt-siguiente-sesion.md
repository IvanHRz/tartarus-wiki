# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: 30-ago-2026, tras cerrar B8 (bloques 1-2) y B9 (bloques 0-1).

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo aparte, privado)
- Rama: `feature/tier0-deployment-readiness` · último commit: `0633b61`

## Cómo quiero que trabajes

- **Documentación en español llano**, cronológica, sin tecnicismos ni anglicismos innecesarios.
- **Todo plan aceptado se archiva verbatim** en `wiki/planes/YYYY-MM-DD.md` **antes** de ejecutarlo
  (skill `registrar-plan`).
- Actualiza `.agents/ROADMAP.md` (está en .gitignore) y vuélcalo a `wiki/roadmap-operativo.md`.
  Entrada cronológica en `wiki/log.md`.
- **Commits en español, sin `Co-Authored-By`**, excluyendo siempre `presentacion/`.
- **No subas a GitHub hasta que lo pida.**
- **Verifica en vivo contra el stack y enséñame números.** Y verifica **contenidos, no códigos de
  respuesta** — un 200 con el cuerpo equivocado ya me costó una sesión entera (ver abajo).
- Cualquier borrado masivo en la base: **pregúntame antes**.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta solo si es ambiguo o destructivo.

## Reglas de operación del stack (importantes)

- Arranque: **`make up-quick`**. **NUNCA `make up`** — hace `down -v` (borra la base) y además ejecuta
  `fix-bee`, que **borra `beelzebub/configurations/services/https-443.yaml`** sin nada que lo restaure.
- Engine en `:9001`, consola en `:8888`, SSH del honeypot en `:2222`.
- Suite: `cd engine && python3 -m pytest tests/ -q` (borra `__pycache__` antes de medir). **Va por
  1734 verde.**
- La UI se sirve por bind mount de `ui/src` → basta **Cmd+Shift+R**. Pero **`ui/nginx.conf` NO está
  montado, va dentro de la imagen**: un `docker restart tartarus-ui` **no** recoge sus cambios, hay
  que reconstruir con `docker compose -f docker-compose.yml -f docker-compose.dev-mac.yml up -d --build ui`.
- **Ojo al recrear contenedores**: Docker reasigna las IP y eso ya tumbó la consola una vez. Después de
  cualquier `up -d --build <servicio>`, comprueba que `curl -s localhost:8888/api/health` devuelve el
  **contenido** del engine y no solo un 200.
- La clave de OpenAI vive en `Entrada/GPT.rtf` y en `beelzebub/configurations/services/*.yaml` (ambos
  gitignored; el repo de código es PÚBLICO). Si necesitas leerlos, **enmascara la clave** en la salida.

## Dónde lo dejamos

Vengo de una tanda larga. Cerrado y verificado en vivo:

- **B7b** — motor de comandos de Windows (`dir`, `cd`, `type`, errores literales de PowerShell,
  prompt `PS C:\…>`).
- **B5b** — el árbol de cebos por industria ya es un sensor de verdad: cada archivo con secreto único
  y regla de reúso, no decorado.
- **B8 (1-2)** — **la alerta ya salta cuando alguien entra**. Era un fallo de atribución: el aviso de
  apertura del honeypot se contaba como comando tecleado y de paso pisaba la etiqueta MITRE que abría
  la puerta del aviso. Además: modelo de dos niveles (inmediato + resumen al cerrar sesión), el
  limitador dejó de comerse alertas (era por IP y todo llega por la misma), y **cada supresión queda
  ahora en el registro** — antes era muda, que es lo que mantuvo el problema invisible.
- **B9 (0-1)** — **desatascada la consola**. Y ojo con esto, que es la lección de la sesión: al
  arreglar el 502 puse el destino de nginx en una variable, y **cuando `proxy_pass` lleva variable
  nginx deja de recortar el prefijo del `location`**: todas las llamadas `/api/*` acababan en `/` y el
  engine contestaba **200** con su banner. Las 89 rutas daban «bien» y la consola seguía muerta.
  Resuelto con `rewrite … break`, y hay `engine/tests/test_nginx_proxy.py` que caza esa trampa.
  También: lo que despliega el asistente ya nace con su cliente (antes quedaba sin dueño e invisible
  en todas las vistas).

**Documentación completa**: `.agents/ROADMAP.md` (secciones B8 y B9), `wiki/roadmap-operativo.md`
(30-ago), `wiki/planes/2026-08-30.md` (los planes verbatim) y `wiki/registro-pruebas.md` (la tabla de
qué alerta y qué no, medida antes de tocar nada).

## Lo que sigue: B9 bloques 2, 3 y 4

El plan está aprobado y archivado en `wiki/planes/2026-08-30.md` (busca «Fase B9»). En orden:

### Bloque 2 — la fuga entre clientes (lo más grave y lo más grande)

Auditado con datos: de **186 rutas**, 47 declaran el filtro por cliente y 43 lo aplican bien; **130 no
lo declaran** y **al menos 37 leen datos de cliente sin ninguna separación**.

Decidí atacarlo **estructural + familias prioritarias**, no ruta por ruta:
1. **Primero el mecanismo**: una dependencia común obligatoria y **un test que recorra el
   `openapi.json` en vivo y falle** si un endpoint lee `events`/`detections`/`canary_tokens` sin
   filtro. Sin esa red, el trabajo se deshace en dos semanas.
2. **Luego, por familias, empezando por lo que sale del edificio**:
   - **`/report/engagement`** — el informe que se ENTREGA al cliente se genera sin flock desde la UI:
     puede llevar eventos, IP atacantes, credenciales y cadenas de ataque de otro cliente. Es la peor.
   - **Notificaciones** — el historial que se lee y, peor, la configuración que se **guarda**: desde
     mi flock se edita la global.
   - **`/audit`** — 583 acciones de todos los clientes.
   - **`/ws/events`** — acepta conexiones sin autenticar y no conoce el flock activo de la UI, así que
     el feed en vivo lo enseña todo. El filtro del servidor **ya existe** (`ws_manager._puede_ver`),
     solo hay que alimentarlo desde la UI.
   - **Contadores globales dentro de respuestas «de un flock»** (`consumer_ingested`, `loaded_rules`,
     `most_triggered`): un cliente con cero eventos ve 909 y deduce el volumen del otro.
   - **La UI no repinta a cero** al cambiar de flock: las cifras de Default se quedan en pantalla.
   - `/alert-ux/related/{ip}` y los memos de analista son globales; `POST /alert-ux/acknowledge/all`
     declara `flock_id` **sin el clamp RBAC**.
3. El resto (`/correlation`, `/mitre`, `/timeline`, `/detections`, `/analyze/*`) detrás del test.
   **Sus helpers de SQL ya aceptan `flock_id`**: es pasarlo, no reescribirlo.

**Anti-patrón a vigilar**, que ya mordió: `/correlation/sessions` daba 500 porque llamaba a la función
canónica sin `flock_id` y le llegaba el objeto `Depends` sin resolver. «Arreglarlo» con
`flock_id=None` habría dejado la ruta devolviendo las sesiones de todos los clientes, en silencio.

### Bloque 3 — el ping (decisión ya investigada y tomada)

**Opción (d), ni (a) NET_ADMIN, ni (b) macvlan, ni (c) dejarlo.** Las tres se descartaron con
evidencia:
- **(a)** dar de alta la IP mata el bucle pero **rompe el engaño**: si el kernel posee la dirección
  contesta con *su* TTL, así que el señuelo «windows» respondería como Linux y con `DUP!`. Además la
  imagen no trae ni el comando `ip` y corre como usuario 65532.
- **(b) macvlan es imposible en macOS**: con OrbStack el Mac no comparte dominio de difusión con el
  contenedor. En Linux de campo sí funcionaría.
- **(c)** mantendría un runbook que da un **falso PASS** delante de un cliente.

**Qué hacer**: en el laboratorio, recuperar el respondedor ARP con scapy —que ya funcionaba— **más
`sysctls: ["net.ipv4.ip_forward=0"]`** en el compose. Ahí estaba la pieza que faltaba: el bucle no lo
causaba el ARP sino el reenvío (verificado: `ip_forward=1`, 227 paquetes en 12 s y redirecciones ICMP
tipo 5). Sin NET_ADMIN, sin root, conservando `cap_drop: ALL`, y el engaño por TTL intacto. En campo,
la unidad systemd que **ya existe**, con el alta de la IP en el aprovisionamiento (`setup-rpi.sh`) —
que es justo lo que el README del propio sensor documenta en su tabla de problemas.

**Aviso para probarlo**: el filtro `_is_infra_source` se traga la demo si el ping sale de otro
contenedor del stack — el sensor dispara, el webhook llega y el evento se tira sin rastro. La prueba
tiene que venir de fuera.

Ya hecho: IP señuelo reapuntadas de `192.168.10.x` (subred inexistente, cero eventos en toda la
historia) a `192.168.97.240/.241`, y filtro para que el sensor no se realimente con su propio eco.

### Bloque 4 — el honeypot web

Corremos **Beelzebub v3.9.0, que es el último release**: no falta versión, falta usar lo que trae.
- **La regresión primero, o se repite**: el laberinto anti-escáner (`MazeHoneypot`) **desapareció el
  29-ago**. Causa: `personality_engine.py:286-290` **sustituye el bloque `commands` entero** al
  aplicar una persona HTTP. Con él muerto, `maze_tagger` etiqueta contra un plugin que ya no existe.
- **HTTP como debe ser**: hoy UNA regla `^.*$` devuelve la misma página con 200 a `/`, `/admin`,
  `/.env` y `/wp-admin` — firma de honeypot en la primera petición. Beelzebub permite rutas por regex
  con `statusCode`, `headers` y cuerpos propios.
- **Un cebo web de verdad**: el HTML no tiene ninguno. El mecanismo existe
  (`POST /canary-tokens/web` + `/canary/t/{token}`), falta que algo lo llame al aplicar la persona.
- **`name:` en los comandos**: Beelzebub rellena `Handler` gratis; hoy mantenemos `maze_tagger.py`
  entero para reconstruir por regex ese mismo dato.
- **HTTPS se guarda como puerto 80**: `consumer.py:384` detecta TLS por `TLSServerName`, vacío cuando
  se conecta por IP — **34 de 35 eventos mal**. Faltan por registrar `beelzebub-https` y
  `beelzebub-prometheus` en `sensor_registry`.
- **`make up` borra el YAML de HTTPS** (`Makefile:72`).

## Registrado y sin hacer (no lo pierdas de vista)

- **Telnet se salta el motor** y llama a `api.openai.com` por su cuenta, con la clave en el YAML.
  Es lo primero de la tanda siguiente: tiene coste por token y saca la clave del camino controlado.
- **MCP no habla MCP**: es HTTP con JSON pintado a mano; un cliente MCP real se cae en el primer
  mensaje. Beelzebub v3.9.0 trae estrategia MCP nativa.
- **Catálogo de servicios TCP de Beelzebub sin usar** (Redis, MySQL, SMB).
- **El plugin LLM sin límite de peticiones ni guardarraíles**, pudiendo activarlos por configuración.
- **El señuelo de Prometheus sirve la página de nginx**, idéntica a las de http-80 y https-443.
- **No hay tabla de despliegues**: no queda rastro de lo desplegado.
- **Colisión de prefijos `/sensors`**: dos routers con el mismo prefijo y tablas distintas.
- **El prompt del shell salta al reconectar** (Beelzebub guarda la sesión por IP+usuario; es de
  upstream y afecta también a Linux).
- **`PUT /personalities/{id}` reescribe el YAML curado** y no borra los canarios si omites el campo.
- **Aplicar una persona por API no reinicia Beelzebub** (solo lo hace la UI) y **no hay forma de saber
  qué persona está aplicada**.
- **Reglas `decoy_reuse` huérfanas** se acumulan y se evalúan para siempre.
- **Dos catálogos de industria que no concuerdan** (el del árbol virtual de B2 y el del ZIP real de B5b).
- **La tabla maestra §10 del ROADMAP no es fuente de verdad**: ~14 de sus 20 filas marcadas PENDIENTE
  están hechas.

## Por dónde empezar

Empieza por el **bloque 2** (la fuga entre clientes), que es lo más grave. Antes de nada, comprueba
que la consola sigue viva:

```bash
curl -s localhost:8888/api/health   # tiene que devolver el JSON del engine, no un banner de 47 bytes
cd engine && python3 -m pytest tests/ -q   # 1734 verde
```
