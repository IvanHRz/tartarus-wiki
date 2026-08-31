# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: 30-ago-2026, tras cerrar la **fase B9 completa** (bloques 0-1, 2, 3 y 4), subirla a
> GitHub y hacer el análisis comparativo contra los labs de Beelzebub.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo aparte, privado)
- Rama: `feature/tier0-deployment-readiness` · último commit: `0014360` · **NO subido** (bloque A
  + A-bis + A-ter, 15 commits, esperando tu OK para el push)

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
- Suite: `cd engine && python3 -m pytest tests/ -q`. **Va por 1867 verde**, 9 saltados.
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
siendo: decidir si subir los 15 commits (bloque A + A-bis + A-ter).**

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
cd engine && python3 -m pytest tests/ -q   # 1867 verde
python3 scripts/audit_flock_isolation.py --loops 1   # 0 fugas
```

Y luego el **bloque A**, empezando por el hash falso del STIX, que es lo único que hoy está
directamente mal y sale hacia fuera.
