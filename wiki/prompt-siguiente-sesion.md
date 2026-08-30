# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: 30-ago-2026, tras cerrar la **fase B9 completa** (bloques 0-1, 2, 3 y 4), subirla a
> GitHub y hacer el análisis comparativo contra los labs de Beelzebub.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo aparte, privado)
- Rama: `feature/tier0-deployment-readiness` · último commit: `a67f55e` · **todo subido**

## Cómo quiero que trabajes

- **Documentación en español llano**, cronológica, sin tecnicismos ni anglicismos innecesarios.
- **Todo plan aceptado se archiva verbatim** en `wiki/planes/YYYY-MM-DD.md` **antes** de ejecutarlo
  (skill `registrar-plan`).
- Actualiza `.agents/ROADMAP.md` (está en .gitignore) y vuélcalo a `wiki/roadmap-operativo.md`.
  Entrada cronológica en `wiki/log.md`.
- **Commits en español, sin `Co-Authored-By`**, excluyendo siempre `presentacion/`.
- **No subas a GitHub hasta que lo pida.**
- **Verifica en vivo y enséñame números.** Y verifica **contenidos, no códigos de respuesta**: un 200
  con el cuerpo equivocado ya me costó una sesión entera.
- Cualquier borrado masivo en la base: **pregúntame antes**.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta solo si es ambiguo o destructivo.

## Una lección que ya costó dos sustos: comprueba antes de creer

Dos veces en la última sesión el plan daba por existente algo que **nunca había estado en git** (el
respondedor ARP del sensor de ping y el laberinto anti-escáner del honeypot web). Se habían probado
en vivo sobre ficheros no versionados y se perdieron.

Así que: cuando yo —o el ROADMAP, o este mismo prompt— diga «recuperar X», «volver a activar X» o «X
dejó de funcionar», **compruébalo primero** (`git log --all -S'<símbolo>'`, `git grep` en todas las
ramas, mirar dentro del contenedor). Si no aparece, el trabajo es escribirlo, no restaurarlo.

Lo mismo con las causas: el mismo dato («227 paquetes en 12 s») estaba atribuido a dos causas
distintas en sitios distintos del repo. Se resolvió **midiendo**, no eligiendo.

## Reglas de operación del stack

- Arranque: **`make up-quick`**. `make up` ya avisa y pide escribir BORRAR, pero sigue borrando la
  base si confirmas.
- Engine en `:9001`, consola en `:8888`, SSH del honeypot en `:2222`, HTTP `:8880`, HTTPS `:8443`,
  MCP `:3001`, Prometheus señuelo `:2112` (las métricas REALES de Beelzebub, en `:9112`).
- Suite: `cd engine && python3 -m pytest tests/ -q`. **Va por 1810 verde**, 9 saltados.
- Auditoría de aislamiento entre clientes: `python3 scripts/audit_flock_isolation.py --loops 1` →
  **0 fugas** en 39 superficies.
- La UI se sirve por bind mount de `ui/src` → basta **Cmd+Shift+R**. Pero **`ui/nginx.conf` NO está
  montado**: hay que reconstruir con
  `docker compose -f docker-compose.yml -f docker-compose.dev-mac.yml up -d --build ui`.
- **Ojo al recrear contenedores**: Docker reasigna las IP. Después de cualquier `up -d --build`,
  comprueba que `curl -s localhost:8888/api/health` devuelve el **contenido** del engine.
- **Los YAML de `beelzebub/configurations/services/` NO están en git** (llevan la clave del proveedor
  y el repo es público). Lo que pruebes ahí se pierde si no hay script que lo regenere: para las
  rutas del honeypot web existe `scripts/seed_web_routes.py`. Si necesitas leerlos, **enmascara la
  clave** en la salida.

## Dónde lo dejamos

**La fase B9 está cerrada entera y subida.** Cuatro bloques:

- **B9 0-1** — desatascada la consola (el 502 y el `proxy_pass` con variable que dejaba de recortar
  el prefijo) y lo que despliega el asistente ya nace con dueño.
- **B9-2 — la fuga entre clientes, cerrada.** El diagnóstico cambió al medirlo: el motor ya filtraba
  bien en casi todo y **la consola no decía de qué cliente pedía** (de 127 llamadas, solo 27 lo
  mandaban). El informe que se ENTREGA al cliente traía 910 eventos de otro. De 185 rutas, las que
  declaran cliente pasaron de 56 a 91. Aparecieron por el camino: un gestor podía **borrar el cliente
  de otro**, dos clientes no podían tener el mismo cebo (el segundo recibía el ID del primero), y
  probar un canal de avisos **escribía** en la configuración global.
- **B9-3 — el ping ya llega.** El sensor llevaba desde su creación con cero eventos porque nadie
  contestaba el ARP. Respondedor ARP nuevo + `ip_forward=0`. Medido: 0 paquetes en reposo, 94 en 12 s
  con el reenvío activado, 0 con él desactivado. Resultado: 0 % de pérdida, ttl 63 (linux) y 127
  (windows), sin DUP!, y 13 eventos donde había 0.
- **B9-4 — el honeypot web ya no canta.** Antes `/`, `/admin`, `/.env` y `/wp-admin` devolvían los
  mismos bytes. Ahora once rutas con los errores reales de nginx, el laberinto anti-escáner activo por
  primera vez, cebos web que disparan de verdad, HTTPS que deja de contarse como puerto 80, el señuelo
  de Prometheus sirviendo métricas falsas, y `make up` que ya no es una trampa.

**Y se hizo el análisis comparativo contra Beelzebub**, que ya no es solo el honeypot que usamos:
levantaron 3 M€ en julio y venden una plataforma con **Caronte** (análisis de malware con IA) y
**Arcangelo** (equipo rojo autónomo). De sus **28 laboratorios** cubrimos 2 del todo, 4 a medias y 16
no; 6 no aplican. Está entero en `wiki/analisis-beelzebub-labs.md`.

## Por dónde seguir: la FASE C

Está en `.agents/ROADMAP.md` (busca «FASE C») y volcada a `wiki/roadmap-operativo.md` (30-ago).

**La regla de orden, que me importa: no se abre nada del bloque B hasta cerrar el A.** Todo lo del
bloque A ya está construido o medio construido — no es trabajo nuevo, es terminar. Es la respuesta a
que estamos dispersos.

### Bloque A — cerrar lo que ya existe

1. **El hash falso en el STIX.** Es una CORRECCIÓN, no una mejora. `events.sha256` es el hash del
   mensaje del evento —lo dice su propio comentario, «Chain of custody: SHA256 of the raw event
   payload»— y el exportador lo emite como `[file:hashes.'SHA-256']` con el nombre «Malicious File
   SHA-256». Cualquier SIEM que consuma nuestro bundle recibe huellas de ficheros que no existen.
   (`consumer.py:264`, `stix_exporter.py:32,86-88`)
2. **Encender la sesión de verdad** (`TARTARUS_SESSION_AUTH`, hoy sin poner en ningún sitio). Todo el
   aislamiento por cliente está construido y **el recorte por rol nunca ha llegado a actuar**.
3. **El honeypot MCP no habla MCP**: es HTTP con JSON fijo, un cliente real se cae al primer mensaje.
   Y el puerto no concuerda (YAML en 3000, scripts en 3001).
4. **Ejercitar la detección de inyección de prompt**: la regla YARA existe y está conectada, pero la
   batería de ataque no envía ni un intento. Una regla que nunca ha saltado no es cobertura.
5. **Telnet se salta el motor** y llama al proveedor por su cuenta con la clave en el YAML.
6. **Retirar `maze_tagger.py`** (119 líneas, redundante desde que Beelzebub rellena `Handler`).
7. El modelo del honeypot no tiene protección anti-jailbreak.
8. `CLAUDE.md` dice «76 Sigma, 20 YARA»; son **398 Sigma** (391 activas) y **436 YARA** en 74 ficheros.

### Bloque A-bis — dónde vive cada decisión en la consola (esto lo quiero mirar)

Lo detecté yo: **la contraseña del servidor la pusimos en la pestaña de Infraestructura y no en la de
Trampas, que es la importante.** Al comprobarlo resultó ser más amplio: el modal donde se configura un
honeypot (`ui/src/index.html:866`) solo se abre desde Infraestructura, y dentro conviven **seis
controles de engaño** (personalidad, contraseña de entrada, prompt, clonador de sitios, credencial
señuelo, generador con IA) con **uno solo** que de verdad es de infraestructura (el proveedor de IA).

La contraseña es el caso más claro porque es la decisión más táctica que hay —«cualquier contraseña»
es lo más tentador para un atacante— y está enterrada donde nadie la busca.

Y quiero **evaluar qué otros parámetros faltan por cubrir** en la configuración de personalidades:
`deadlineTimeoutSeconds` (cuánto aguanta la sesión antes de cortar, hoy 600 s en el YAML y sin control
en la consola), los **usuarios** aceptados en el login (hoy solo se filtra la contraseña), el banner
del servidor, y el laberinto y los cebos web que funcionan pero no tienen ningún control.

El detalle está en el ROADMAP, sección «Bloque A-bis».

### Bloque B — capacidades nuevas (después del A)

1. **Capturar los ficheros que trae el atacante** — el escenario que me interesa, del lab
   [ssh-llm-honeypot-caught-a-real-threat-actor](https://beelzebub.ai/blog/ssh-llm-honeypot-caught-a-real-threat-actor/).
   **Decidido: descargar y guardar, SIN ejecutar nunca.** Es el nudo del que cuelgan dos de las cinco
   capacidades de Caronte: sin los bytes no hay ni ingeniería inversa ni análisis de comportamiento.
   Hoy un atacante que descarga un bot nos deja dos filas de texto y nada más.
2. **Señuelo de la API de Docker (2375)** — lo que más captura da por menos trabajo: aparece en dos
   labs suyos, es HTTP plano, y con la fusión de personas arreglada en B9-4 es escribir un YAML.
3. **El cebo corrupto para agentes de IA** — una credencial rota a propósito: un escáner no la ve, una
   persona tarda 7-10 min, **un agente de IA la repara en 4 segundos**. Encaja con los cebos que ya
   tenemos.
4. Inteligencia externa que sirva (URLhaus por URL, no por IP; y reputación de hashes de verdad —
   CIRCL es un catálogo de ficheros BUENOS).
5. El sistema de ficheros del shell es inmutable: tras un `wget` el fichero no aparece en el `ls`.

### Lo que se decidió NO hacer, y por qué

- **Perseguir a Arcangelo**: es un producto ofensivo, otra disciplina y otro riesgo legal.
- **Detonar malware en sandbox**: se guarda, no se ejecuta.
- **Competir en velocidad de captura de días cero**: su ventaja ahí es de EXPOSICIÓN (tienen sensores
  en internet, nosotros un laboratorio local). No se arregla programando, se arregla desplegando.

## Registrado y sin hacer (no lo pierdas de vista)

- **Catálogo de servicios TCP de Beelzebub sin usar** (Redis, MySQL, SMB).
- **El plugin LLM sin límite de peticiones ni guardarraíles**, pudiendo activarlos por configuración.
- **No hay tabla de despliegues**: no queda rastro de lo desplegado.
- **Colisión de prefijos `/sensors`**: dos routers con el mismo prefijo y tablas distintas.
- **El prompt del shell salta al reconectar** (es de upstream).
- **`PUT /personalities/{id}` reescribe el YAML curado** y no borra los canarios si omites el campo.
- **Aplicar una persona por API no reinicia Beelzebub** (solo lo hace la UI).
- **Reglas `decoy_reuse` huérfanas** se acumulan y se evalúan para siempre.
- **Dos catálogos de industria que no concuerdan**.
- **`rpi3/setup-rpi3.sh` no instala el sensor ICMP** ni toca las IP señuelo.
- **26 directorios `.bak-*`** en la configuración de Beelzebub, sin poda (pero salvaron un YAML).
- **La IP de origen de los eventos ICMP** sale como la de red (`192.168.97.0`) por la virtualización
  de macOS; en campo debería salir la real, sin comprobar.
- **La tabla maestra §10 del ROADMAP no es fuente de verdad**: ~14 de sus 20 filas marcadas PENDIENTE
  están hechas.

## Por dónde empezar

Comprueba primero que sigue todo en pie:

```bash
curl -s localhost:8888/api/health          # el JSON del engine, no un banner
cd engine && python3 -m pytest tests/ -q   # 1810 verde
python3 scripts/audit_flock_isolation.py --loops 1   # 0 fugas
```

Y luego el **bloque A**, empezando por el hash falso del STIX, que es lo único que hoy está
directamente mal y sale hacia fuera.
