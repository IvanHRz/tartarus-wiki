---
tipo: guia
creado: 2026-09-17
actualizado: 2026-09-17
tags: [sesion, prompt, raspberry, campo]
---

# Prompt para una sesión dedicada a la Raspberry Pi 5

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Es el prompt **de campo**. El genérico (motor y consola) es [[prompt-siguiente-sesion]] — no los
> mezcles: el reparto vigente es que **esta sesión lleva la Pi y la otra lleva el motor y la
> consola**.
> Escrito el 17-sep-2026 con la Pi **caída** y todo lo de abajo medido ese día.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes. Esta
sesión es **sólo del despliegue de campo: la Raspberry Pi 5**. Ollama y el modelo local quedan
fuera a propósito; son otro hilo.

- Código: `~/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PRIVADO**).
- Rama `feature/tier0-deployment-readiness`, PR **#25**. Motor Python/FastAPI en `engine/`, consola
  en `ui/src`, honeypots Beelzebub. Motor en `localhost:9001`, consola en `:8888`.
- Wiki aparte: `~/Documents/Wikis/wiki-tartarus`.

## Lo primero, antes de leer nada más

**Hay otra sesión de Claude trabajando el motor y la consola ahora mismo.** Arranca con tu propia
copia de trabajo o le pisarás cosas:

```bash
cd ~/Documents/Tartarus
scripts/sesion_paralela.sh nueva pi          # crea ../Tartarus-pi, con su índice y su stash
cd ../Tartarus-pi
```

Después **decláralo** en `.agents/COORDINACION.md` con la plantilla del principio del fichero
(`Desde:` en ISO, `Reclamo:`, `No toco:`, `Stack:`) y compruébalo:

```bash
python3 scripts/revisar_sesiones.py          # tiene que salir en verde
```

Se empuja con `git push origin HEAD:feature/tier0-deployment-readiness` y se cierra con
`scripts/sesion_paralela.sh cerrar pi`.

**La regla que git no puede vigilar:** en un documento compartido —ROADMAP, TRASPASO, BITÁCORA,
COORDINACION— **se inserta con anclas, nunca se reescribe entero**. Una reescritura desde una
lectura de hace una hora borra lo que la otra sesión escribió en medio y git la acepta sin decir
nada. Skill: `sesiones-en-paralelo`.

**El stack es UNO** aunque tu copia sea tuya: un motor, una base, un Beelzebub, una Pi. Eso se pide
por turno.

## Lo que tiene la otra sesión abierto — no lo toques

`engine/engine/{consumer,audit,flocks_router,honey_creds_manager}.py`, `engine/tests/test_honey_creds.py`,
`e2e/{ingesta_y_conteos,sesion.setup}.ts`, `beelzebub/configurations/personalities/portal-gobmx.yml`
(esto último es trabajo en vivo de Iván, nunca se commitea). Y dos pruebas suyas sin seguimiento:
`test_vaciar_flock.py` y `test_fuga_honey_creds.py`.

## El estado de la Pi, medido el 17-sep-2026

| Qué | Medido |
|---|---|
| `equipo-88a29e57855e` | **offline**, último latido **2026-09-11 17:12 UTC** — hace **5 días y 15 h** |
| ¿Responde al ping? | **No**, ni en `192.168.0.12` ni en `10.99.0.1` |
| Sensores | **9 activos de 10**; el caído es ella |
| Su cliente | **Default Flock** — nunca se enroló a un cliente de verdad |
| Identidad estable | MAC **`88:A2:9E:57:85:5E`**, hostname `tartarus-sensor`, RPi 5 Model B Rev 1.1, 16 GB |

```bash
docker exec tartarus-postgres psql -U tartarus -d tartarus -c "
SELECT sensor_id, host, status, last_heartbeat, (now()-last_heartbeat) AS hace
FROM sensor_registry WHERE sensor_type='hardware';"
```

## Lo primero de verdad: encontrarla

**Su IP ha cambiado tres veces** — `192.168.1.73` → `192.168.0.12` → `10.99.0.1` — y ahora ninguna
responde. Su propio estado del 10-sep ya lo avisaba: *«no confiar en una IP guardada»*. **Búscala
por MAC, no por dirección.** Iván la tiene delante, así que si la red no da, hay pantalla y teclado.

**Dos datos que ahorran media hora:**

1. **El SSH de administración está en el 2222. El puerto 22 es el honeypot.** Confundirlos ya costó
   una sesión el 9-sep: el login «fallaba» porque se estaba entrando al señuelo.
2. **En cuanto vuelva a latir, el registro se corrige solo.** El latido hace
   `host = EXCLUDED.host` (`sensor_registry_router.py:170-186`), así que la IP vieja se actualiza
   sola. **No toques la base.**

Y antes de dar por muerta la máquina: el 15-sep **respondió al ping estando `offline`**. Lo que se
cae es **su agente** (`tartarus-agente-equipo.service`), no el aparato. Míralo primero.

Ojo también con `sensor_health_worker`: trata `hardware` como sensor de **empuje** (`_PUSH_TYPES`),
así que **nunca la sondea** — su única señal es el latido. Degradado a 60 s, caído a 90 s.

## Tu trabajo, por orden

Es mi orden, no una orden. El detalle está en `.agents/ROADMAP.md` con su medición.

### 1 · `{#hardware-nunca-enrola}` — P1, esfuerzo **S**. Lo más grave y lo más barato.

`scripts/setup-rpi.sh` (182 líneas) instala Docker, el punto de acceso WiFi, `eth0`, systemd e
iptables… y **no menciona ni una sola vez** `enroll`, `token`, `consola` ni `flock`:

```bash
grep -i -c "enroll\|token\|consola\|flock" scripts/setup-rpi.sh \
     scripts/push-to-rpi.sh rpi3/setup-rpi3.sh      # → 0, 0, 0
```

Quien enrola es un **cuarto** guion, `scripts/sensor-enroll.sh` (34 líneas), **que ninguno de los
otros llama**. Por eso la Pi está en el **Default Flock** en vez de en un cliente: nadie se lo dijo
nunca. El aparato queda montado, encendido y **mudo**, sin que falle nada ni salte ningún error.

El token ya existe y funciona: `POST /flocks/{id}/enroll` lo emite, **un solo uso, TTL 1 hora**, y
`POST /sensors/enroll` lo consume y estampa el `flock_id`.

### 2 · `{#docker-sin-imagen}` — P1, M. Bloquea lo siguiente.

`beelzebub/` **no tiene `Dockerfile`** (sólo seis `.patch`), no hay `buildx` ni registry en todo el
repo, y la única imagen buena —`tartarus-beelzebub:v3.9.0-tartarus`— es **`linux/arm64`** y vive
sólo en el Mac. Además `docker-compose.yml:5` cae por defecto a `m4r10/beelzebub:v3.9.0`, **la de
upstream sin los seis parches**: clave de host SSH efímera, o sea `REMOTE HOST IDENTIFICATION HAS
CHANGED` en cada reinicio. **El honeypot de campo se delata solo y nada lo avisa.**

Salida barata mientras no haya registry: `docker save … | ssh … docker load`.

### 3 · `{#rpi5-un-paso}` — P1, M. Donde podemos ganarle a Thinkst.

Ellos mandan el aparato y el cliente lo da de alta **a mano** (*«Hardware — Manual registration»*).
Nosotros controlamos la tarjeta: imagen `tartarus-field.img` pregrabada + un `firstboot` que lee
**un solo dato** de `/boot/tartarus.conf` —el token— y se enrola solo. La partición `boot` es FAT y
se edita desde cualquier Windows o Mac. *Graba la tarjeta, escribe el token, enciende.*

### 4 · `{#pi-ruido-propio}` — P1, M. Una pregunta, no un diagnóstico.

En sus últimos metadatos, el reenviador estaba **activo y con 0 errores**, y decía:

```
"reenvio": {"activo": true, "ruido": 681734, "enviados": 1, "errores": 0, "intervalo": 15}
```

**681.734 sucesos descartados como «ruido propio» y 1 federado.** El filtro
(`reenviador.py:162`) descarta lo que viene de las redes de los puentes Docker de esa máquina,
leídas del sistema — el criterio es correcto y está bien razonado. **Lo que no se sabe es si ese
número es normal.** Con ~3.849 sucesos en su base local, 681.734 no sale del tráfico de ataque: es
la Pi hablándose a sí misma. Con ella delante:

```sql
SELECT source_ip, count(*) FROM events GROUP BY 1 ORDER BY 2 DESC LIMIT 20;
```

Si es tráfico interno de verdad, hay que bajarlo en origen: cada suceso propio es una escritura en
la microSD.

### Y de paso

- `{#seis-caminos-de-despliegue}` (P2, S) — son **siete** guiones y ninguno hace el trabajo entero.
  Dejar **uno**.
- `{#wifi-en-el-guion}` (P3, XS) — la contraseña del WiFi de campo está **escrita y versionada**
  en el guion de instalación, así que todo aparato sale con la misma.
  [recorte 21-sep: el valor y su fichero, en `#wifi-en-el-guion` del ROADMAP privado — esta wiki es pública]

## Un aviso que te ahorra perseguir fantasmas

**La Pi corre un motor viejo** (0.3.0 / 0.4.0 según el último estado), sin el barrido de realismo.
Por eso allí `lsof`, `mount` y `netstat` caen al modelo y aquí no. **El arreglo no es tocar el
ruleset** —eso ya se probó: `SSH_RULES_COMPACT` lo tumbó su propio gate, 13/21 contra 15/21— **es
desplegarle el motor al día**. Está en el ROADMAP y lleva aparcado desde el 11-sep.

## Una decisión que conviene mirar con ojos nuevos

El alta (`POST /sensors/enroll`) va **sin firma HMAC** a propósito: el token de un solo uso *es* la
autenticación (`sensor_registry_router.py:228`). El latido sí va firmado. Está razonado, pero es
una decisión, no un descuido — y la tienes delante justo cuando vas a tocar el enrolamiento.

Relacionado: `{#hmac-exigir}` **no se puede decidir hoy** aunque parezca que sí. El contador de
quién manda sin firmar (`hmac_verifier._sin_firma`) es un **diccionario en memoria** que se borra
en cada reinicio del motor, así que «cero» significa «nadie desde el último reinicio». Y antes de
encender `TARTARUS_HMAC_ENFORCE` hay que darle el secreto al agente de la Pi en su unidad systemd
(`Environment=TARTARUS_HMAC_SECRET=…`) **o dejará de reportar**. Pídeselo a Iván; no está en ningún
documento a propósito.

## Las trampas que son tuyas

Están todas en `.agents/TRASPASO.md`, y éstas son las de campo:

- **El reloj de la Pi va ~6 h por detrás de UTC.** No mandes fechas absolutas: manda **duraciones**.
  El latido es inmune porque lo sella el motor, pero un `journalctl --since <UTC>` filtra al futuro
  y te da un «0» falso.
- **La Pi no tiene `httpx`, y Debian 12 (PEP 668) no deja instalarlo sin entorno virtual.** Todo lo
  que corra EN el equipo se vale con la biblioteca estándar. Por eso `sensors/latido.py` cae a
  `urllib` en un hilo.
- **Un módulo compartido no entra en la imagen del sensor** si el contexto de build es la carpeta
  del sensor. `sensors/latido.py` vive un nivel arriba: por eso el contexto es `./sensors`.
  Reconstruir sin eso deja los canarios muertos al arrancar.
- **El `:9001` del motor es un puerto fantasma de OrbStack** y desaparece al recrear el contenedor.
  Lo estable para un equipo remoto es el **`:8888/api`** de la consola.
- **El arranque son DOS ficheros de compose.** En campo, `docker-compose.yml` **y**
  `docker-compose.field-rpi.yml`. Con uno solo se pierden los montajes.
- **`beelzebub.yaml` lleva `amqp://guest:guest@broker:5672/` clavado**, y `broker` no resuelve en la
  Pi. Y `push-to-rpi.sh` nunca llama a `set_llm`, así que los YAML llegan apuntando a
  `http://engine:8000` — que allí tampoco resuelve. **El honeypot queda mudo.**
- **Al probar contra un servicio de mentira, restaura la configuración al terminar.**
- **Los YAML de `beelzebub/configurations/services/` no están en git** (llevan la clave), y
  `Raspberry/` tampoco (lleva credenciales de laboratorio). No los des por versionados.

## Cómo quiero que trabajes

Documentación en **español llano y cronológico**. Todo plan aceptado se archiva verbatim en
`wiki/planes/YYYY-MM-DD.md` (skill `registrar-plan`) **antes** de ejecutarlo; al cerrar, skill
`pendientes-roadmap`. Commits en español, **sin `Co-Authored-By`**, excluyendo `presentacion/`,
**nunca `git add -A`** — rutas explícitas siempre. El trabajo va al PR **#25** y **el CI se
comprueba atado al SHA del commit**, no al último run de la rama.

**Verifica en vivo y enséñame números — y verifica CONTENIDOS, no códigos de respuesta.** Se han
cerrado pendientes porque «el guion existe» con el defecto intacto en disco.

**Las skills no son opcionales** (`.claude/skills/`, listadas en `CLAUDE.md` §10). Las tuyas:

- `sesiones-en-paralelo` — al arrancar y antes de tocar cualquier `.agents/*.md`.
- `pieza-sin-cablear` — antes de escribir «HECHO» o «cubierto».
  `python3 scripts/buscar_sin_cablear.py`. Es la que destapó que el token de enrolamiento funciona
  y el guion de montaje no lo llama.
- `guardarrail-en-rojo` — al escribir cualquier prueba. **Ningún spec vale si no lo has visto en
  ROJO contra su defecto.**
- `medir-no-suponer` — antes de afirmar una causa.
- `verificar-en-vivo` — qué se reinicia y qué tarda.
- `sustrato-que-miente` — cuando el código esté bien y el resultado sea otro. Media lista de
  trampas de arriba es de esa familia.

**Cualquier borrado masivo en la base, pregúntale a Iván antes.** Avanza sin preguntar de más
cuando la dirección esté clara.

## Al cerrar

`pendientes-roadmap`, entrada en la BITÁCORA, actualizar tu sección de `COORDINACION.md`, y
**decir qué quedó sin hacer y por qué**. Y desconfía de las listas de pendientes, incluidas las
mías: el 16-sep, de cinco entradas comprobadas a mano, **cuatro estaban desfasadas**. Comprueba en
el código antes de ponerte con algo.

---

## Añadido el 17-sep-2026 (madrugada, sesión `skills-y-campo`) — dos correcciones antes de que te pongas

> No toqué la Pi ni Ollama: esto sale de leer el código y la documentación de Thinkst. El estudio
> completo está en `docs/RPI5_DE_LA_CAJA_A_LA_CONSOLA.md` y las entradas nuevas en el ROADMAP,
> bloque **D-ter**.

### 1 · El punto 1 de tu lista no es esfuerzo S. Es M.

Arriba dice que `{#hardware-nunca-enrola}` es *«lo más grave y lo más barato»*. Lo primero sí; lo
segundo no. `scripts/sensor-enroll.sh` son 34 líneas que **sólo escriben `flock_id` en un fichero**
(`:33-34`):

- **no guardan el `sensor_id`**,
- **no arrancan el agente**,
- **no configuran `TARTARUS_HMAC_SECRET`**.

Si `setup-rpi.sh` se limita a llamarlo, el aparato queda enrolado y **reportando sin firmar para
siempre** — que es `#rpi-agente`, el punto 16 de tu propia lista, archivado aparte. **Son un solo
trabajo.** Cerrar sólo la mitad cambia el bug de cara y lo deja más difícil de ver.

### 2 · Desplegarle el motor al día NO basta. Y la cifra que lo justificaba está desfasada.

El aviso de arriba —«el arreglo no es tocar el ruleset, es desplegarle el motor al día»— es
correcto y es **insuficiente**. Los YAML de la Pi apuntan Beelzebub **directo** al modelo:

```yaml
host: "http://172.18.0.1:11434/api/chat"
```

Con eso, **Beelzebub nunca habla con el motor**. Puedes desplegarle el motor más nuevo del mundo y
no cambia ni un milisegundo, porque el cerebro determinista no está en el camino. Aquí, con los
YAML apuntando al shim (`http://engine:8000/v1/chat/completions`), las tres baterías dan
**`llamadas_llm=0`**: 57 POSIX, 35 Windows, 17 Cisco. Allí, **los 57 pagan 36 s**.

**Hay que hacer las dos cosas:** motor al día **y** reapuntar los YAML al shim, con
`TARTARUS_LLM_ACTIVE=ollama` como proveedor de respaldo.

**Y por qué se cableó directo:** se midió el paso por el motor en **48-52 s contra 36 s** del
directo. Esa medición se tomó contra el motor **viejo, sin el barrido de realismo** — medía «la
misma llamada al modelo, más un salto». Con el motor de hoy `lsof`, `mount`, `netstat`, `ps` y `df`
se resuelven en código y **no hay llamada que medir**. La cifra ya no vale, y mientras tanto ha
congelado una decisión de arquitectura en una entrada del ROADMAP marcada ✅.

Entradas nuevas: `#honeypot-salta-el-cerebro` y `#palancas-latencia-local`.

### Y tres cosas menores que te ahorran tiempo

- **`{#rpi5-un-paso}` NO está bloqueado por `{#docker-sin-imagen}`** para el camino de hardware: la
  `.img` se construye una vez sobre arm64 y la imagen parcheada se hornea dentro
  (`docker save` → `docker load` al fabricarla). Sin registry y sin `buildx`. Esa dependencia mal
  puesta es lo único que mantiene aparcada la entrada de más valor.
- **El punto de acceso WiFi que monta `setup-rpi.sh:50-88` ya es el 80 % de la pantalla de alta de
  Thinkst** (`192.168.50.1`, con el 8888 ya abierto por `wlan0` en `:141-142`) — y en esa dirección
  **no se sirve nada**. Entrada nueva: `#pantalla-en-el-aparato`.
- **Los dos secretos que parecen versionados no lo están:** `.env` lo cubre `.gitignore:2` y los
  `.bak-*` de `services/` los cubre `.gitignore:48`. `git ls-files` no devuelve ninguno. No hay
  nada que redactar.

— sesión `skills-y-campo`, que no tocó la Raspberry
