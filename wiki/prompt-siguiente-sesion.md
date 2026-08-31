# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: 31-ago-2026, tras cerrar el **bloque A de la fase C** (los 8 puntos) más tres rondas
> de afinado de la consola (A-bis/ter/quater). 16 commits sin subir. El siguiente objetivo es dejar
> Beelzebub al 100% atacando cada honeypot uno por uno.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo aparte, privado)
- Rama: `feature/tier0-deployment-readiness` · último commit: `e36206a` · **NO subido** (bloque A + A-bis
  + A-ter + A-quater, 16 commits, esperando tu OK para el push)

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
- Suite: `cd engine && python3 -m pytest tests/ -q`. **Va por 1861 verde**, 9 saltados.
- Auditoría de aislamiento entre clientes: `python3 scripts/audit_flock_isolation.py --loops 1` →
  **0 fugas** en 39 superficies.
- Auditoría del recorte por ROL (nueva): `python3 scripts/audit_rbac_enforcement.py` → **37/37, 0
  fugas**. Levanta un engine efímero con auth ON, verifica y lo apaga; NO toca el de dev.
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

**El bloque A de la FASE C está cerrado entero, más tres rondas de afinado de la consola.** 16
commits sin subir (`cab22c5`..`e36206a`), rama `feature/tier0-deployment-readiness`. Suite en
**1861 verde**, aislamiento entre clientes 0 fugas, recorte por rol 37/37.

- **Bloque A (8 puntos):** el hash falso del STIX (114→14 objetos), los conteos de
  CLAUDE.md medidos y vigilados en CI, fuera `maze_tagger`, telnet por el motor, el MCP
  hablando MCP de verdad, la inyección de prompt ejercitada (8 detecciones), el anti-jailbreak
  medido (aguanta), y el recorte por rol cableado en las ~45 escrituras de consola.
- **A-bis:** control de deadline y banner; **parche de Beelzebub** (filtro de usuario en el
  login + latencia); control del laberinto por servicio.
- **A-ter:** puerto real (2222), un solo menú por protocolo, 3 pestañas (Monitoreo/Análisis/
  Trampas), personalidades por protocolo.
- **A-quater:** limpieza de Trampas (fuera Deception/DRAS/embudo), Monitoreo = solo lo activo,
  los 9 sensores en Trampas, menú del protocolo más claro.

**El análisis contra Beelzebub sigue vigente** (`wiki/analisis-beelzebub-labs.md`): de sus **28
laboratorios** cubrimos 2 del todo, 4 a medias y 16 no; 6 no aplican. Eso marca el trabajo que
viene.

## Por dónde seguir: la FASE C

### 🎯 OBJETIVO DE ESTA SESIÓN — dejar Beelzebub al 100%, atacando sensor por sensor

Lo que quiero: **atacar cada honeypot uno por uno y comprobar que todo funciona bien**,
empezando por los que menos hemos mirado — **MCP, HTTP y Telnet**. La meta es dejar **todas las
funciones de Beelzebub al 100%** y **cumplir los alcances de sus laboratorios lo antes posible**
(`wiki/analisis-beelzebub-labs.md`).

Cómo lo quiero:

1. **Uno por uno, de verdad.** Por cada protocolo: lanzarle su ataque (la batería está en
   `scripts/attack_all.py`, con `--only <protocolo>`), y **verificar el CONTENIDO de la
   respuesta y del evento en la base, no el código HTTP**. Un 200 con el cuerpo equivocado ya
   costó una sesión.
2. **Empezar por MCP, HTTP y Telnet.** El MCP ya habla JSON-RPC (A5) y telnet ya va por el
   motor (A4) — hay que estirarlos: probar un cliente/ataque realista de cada uno y ver que el
   engaño aguanta, que el evento se ingiere con su cuerpo, que salta la detección que deba
   saltar, y que no se delata (fingerprint, banner, latencia).
3. **Cruzar con los labs.** Para cada protocolo, mirar en `wiki/analisis-beelzebub-labs.md` qué
   labs de Beelzebub lo tocan y cuáles están «a medias» o «no» — y cerrarlos si son de este
   bloque. El objetivo es subir la cobertura de 2/4/16.
4. **Medir y enseñar números** (eventos ingeridos, detecciones que saltan, latencia real), y
   **comprobar en git antes de dar algo por hecho** — la lección de los dos sustos sigue.

Cuando un protocolo quede «al 100%» (ataque realista + evento con cuerpo correcto + detección
+ sin delatarse), pasar al siguiente. Registrar lo que quede a medias en el ROADMAP.


Está en `.agents/ROADMAP.md` (busca «FASE C») y volcada a `wiki/roadmap-operativo.md` (30-ago).

**La regla de orden que me importaba se respetó: no se abrió nada del bloque B hasta cerrar el A.**

### Bloque A — CERRADO el 30-ago-2026 (7 commits, sin subir)

Los ocho puntos hechos. **Tres estaban mal descritos** y se corrigieron al medirlos:

1. ✅ **Hash falso del STIX** — el bundle pasó de 114 objetos (100 huellas de fichero falsas) a 14.
   El digest sigue en la cadena de custodia del informe. (`C/A1`)
2. ✅ **Recorte por rol** — no bastaba «encender la sesión»: al medirlo, solo estaba cableado en 4 de
   ~20 routers y un watcher podía crear cebos y borrar credenciales trampa. Cableado en las ~45
   escrituras de consola que faltaban. Auditoría nueva `audit_rbac_enforcement.py` → 37/37, sin tocar
   dev. (`C/A7`)
3. ✅ **MCP habla MCP** (JSON-RPC de verdad). El desajuste de puerto era en prod/campo, no en dev;
   parametrizado. (`C/A5`)
4. ✅ **Inyección de prompt** — la batería la envía por SSH/telnet/MCP: 8 detecciones donde había 0.
   (`C/A6`)
5. ✅ **Telnet por el motor** — ya no llama al proveedor; clave fuera del YAML. (`C/A4`)
6. ✅ **`maze_tagger.py` retirado** tras medir que Beelzebub ya lo dice en `Handler`. (`C/A3`)
7. ✅ **Anti-jailbreak** — ERA FALSO que faltara: existe en las 7 personas y aguantó los 12 ataques.
   Cerrado por medición. (`C/A6`)
8. ✅ **Cifras de CLAUDE.md** — son 398 Sigma (391 activas) y **439 YARA en 95 ficheros** (el «436 en
   74» también estaba mal). El detector `validate_docs.py` no lo corría nadie; ahora va en CI. (`C/A2`)

**Hallazgos nuevos anotados en el ROADMAP** (sección «ESTADO — Bloque A cerrado»): el honeypot web se
delata (IIS en `/`, nginx en `/.env`); handlers de la fusión de personas sin `name:`; una clave de SSH
que ya no hace falta; el prompt del shell sale como bash en un router Cisco; falta bootstrap
`services.example/`→`services/`. **Lo primero de la próxima sesión: decidir si subir los 7 commits.**

### Bloque A-bis — CERRADO el 30-ago-2026 (4 fases, sin subir)

Lo que señalaste: la contraseña estaba enterrada en Infraestructura y es lo más táctico. Se
**partió el modal en dos** — «Trampa» (desde Trampas: disfraz, contraseña, usuarios, deadline,
latencia, banner) y «Motor» (desde Infraestructura: solo el proveedor de IA). Nueva sección
«Disfraz y trampa de cada honeypot» en Trampas. Verificado con Playwright (0 errores JS).

- ✅ **deadline + banner** — control nativo. El deadline sobrevive a aplicar persona; el banner
  no (es del disfraz) y se avisa. (`C/A-bis 1`)
- ✅ **usuarios de login + latencia** — NO existían en Beelzebub: parche Go
  `beelzebub-login-latency.patch`. Filtro de usuario y latencia probados en vivo; el login no se
  rompió. (`C/A-bis 2`)
- ✅ **partir el modal** — Trampa vs Motor, cada uno en su pestaña. (`C/A-bis 3`)
- ✅ **laberinto web** — toggle por servicio (apagado = 404 nginx). (`C/A-bis 4`)

Los 5 endpoints nuevos llevan el recorte por rol; RBAC 37/37. **Lo primero de la próxima
sesión sigue siendo: decidir si subir los 12 commits (bloque A + A-bis).**

### Bloque A-ter — CERRADO el 30-ago-2026 (rediseño de consola, sin subir)

Tras probar el A-bis me dijiste que la consola se sentía dispersa (un honeypot se configuraba
en tres sitios). Cuatro fases:

- ✅ **Correcciones** — puerto real (2222, no 22), pestañas **Monitoreo/Análisis**, «disfraz»→
  «personalidad», banner auto-sugerido, Credential Analysis→Análisis, Breadcrumbs al fondo.
  (`C/A-ter 1`)
- ✅ **Un solo menú por protocolo** — refundido lo que el A-bis había partido (Motor+Trampa).
  Eliges el protocolo y en una ventana está TODO. (`C/A-ter 2`)
- ✅ **Tres pestañas** — Infra fusionada en Trampas; grid de honeypots deduplicado; cebos en
  Trampas; hosts→Monitoreo, escaneo→Análisis. (`C/A-ter 3`)
- ✅ **Personalidades por protocolo claras** — «compatibles con SSH (6)»; TCP/MCP explican que
  son estáticos. Aclarada la latencia+IA. (`C/A-ter 4`)

Verificado con Playwright en cada fase (0 errores JS). **Lo primero de la próxima sesión sigue
siendo: decidir si subir los 16 commits (bloque A + A-bis + A-ter + A-quater).**

### Bloque A-quater — CERRADO el 31-ago-2026 (afinar Trampas, sin subir)

Repasaste Trampas sección por sección. Modelo: **Monitoreo = solo lo activo**, **Trampas = los
9 sensores** (7 honeypots + canary de ping + Modbus).

- ✅ Quitado el ruido: familia Deception (redundante), sección DRAS (botón duplicado), embudo
  de ingesta (técnico).
- ✅ Monitoreo estrena «Protocolos activos» (solo lo encendido).
- ✅ Trampas reúne los 9 (honeypots + 2 canary como tarjetas de estado).
- ✅ Menú: «Editar/crear personalidad» arriba, sin «Generar IA» suelto; «Avanzado» del
  proveedor reescrito en llano.
- ✅ Orden: honeypots → personalidades → migajas → cebos. (`C/A-quater`)

**Lo primero de la próxima sesión sigue siendo: decidir si subir los 16 commits.**

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
cd engine && python3 -m pytest tests/ -q   # 1861 verde
python3 scripts/audit_flock_isolation.py --loops 1   # 0 fugas
```

Y comprueba que los honeypots responden con su CONTENIDO (no solo que el puerto abre):

```bash
# MCP habla JSON-RPC:
curl -s -X POST localhost:3001/ -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | head -c 200
# HTTP: la portada y un 404 real:
curl -s -D- -o /dev/null localhost:8880/ | grep -i '^server'
# Telnet vivo (2323), SSH vivo (2222)
```

Y luego el **objetivo de esta sesión**: atacar cada honeypot uno por uno (empezando por MCP,
HTTP y Telnet), verificando el cuerpo del evento en la base y la detección, hasta dejar
Beelzebub al 100% y subir la cobertura de los labs. Usa `scripts/attack_all.py --only <proto>`
y `wiki/analisis-beelzebub-labs.md`.
