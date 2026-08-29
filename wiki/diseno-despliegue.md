# Diseño del despliegue en TARTARUS

> Cómo se despliega y por qué. Documento vivo. Escrito el 28-ago-2026 para aterrizar el modelo antes
> de construir el flujo guiado tipo Thinkst.

## 1. La realidad que da forma a todo

Beelzebub es **una sola instancia compartida**: unos contenedores que corren en puertos fijos (SSH
2222, HTTP 8880, Telnet 2323, TCP 8080, MCP 3001, Prometheus falso 2113), levantados por
docker-compose y **siempre encendidos**. El engine **no puede crear ni arrancar contenedores por
cliente** (regla C4: no se monta el docker socket). Por eso TARTARUS **no** es como Thinkst Canary,
donde cada canario es una instancia real que despliegas.

**Consecuencia:** «desplegar en un flock» no significa arrancar un honeypot nuevo. Significa una de
estas tres cosas, y conviene no mezclarlas:

| Qué | ¿Por cliente? | Cómo |
|---|---|---|
| **Honeypots de Beelzebub** (SSH, HTTP, …) | **No** — compartidos (lab de plataforma) | Se **asigna** qué puerto es de qué cliente (`sensor_registry`/`flock_assignments`) |
| **Canary tokens y honey-creds** | **Sí** | Se **plantan** de verdad (ficheros/registros) por flock |
| **Sensores remotos / hardware** (RPi, etc.) | **Sí** | Se **enrolan** por flock con un token de un solo uso |

## 2. Principio: opt-in, nada por defecto

Un flock nuevo **no despliega nada**. Los honeypots de Beelzebub se ven como **«laboratorio
compartido»** (plataforma), no como despliegue del cliente. Lo del cliente —sus sensores remotos y
sus cebos— empieza en **cero** y se añade a demanda. Filosofía Thinkst: *menos es más; despliegas lo
que necesitas, guardas y cierras*.

(28-ago: primer paso dado — la sección de Despliegue ya rotula «Laboratorio compartido» vs «Sensores
de este cliente», y el flock arranca mostrando 0 propios.)

## 3. Dos caminos de despliegue, y cuándo usa cada uno el operador

- **Recomendado (botón «Desplegar»).** Un asistente que, según el tipo de engagement (IR, evaluación,
  red team) y el sistema objetivo, propone un **paquete recomendado** de sensores/cebos y lo despliega
  de una. Es el **arranque rápido**: «monta lo típico para este caso y ya afino».
- **Manual (à la carte, flujo «+ Añadir»).** Añadir **una** pieza concreta cuando surge la necesidad:
  un protocolo puntual, unos canary tokens, un sensor de hardware. Es el **día a día**: «ya tengo el
  cliente montado y quiero sumar X».

Regla práctica: **recomendado para empezar, manual para ajustar**. El recomendado nunca es
obligatorio ni definitivo; el manual siempre está disponible para sumar o quitar.

## 4. Spec del flujo «+ Añadir» (estilo Thinkst) — pendiente de construir

Modelo mental (imagen de referencia: el «Add» de Thinkst Canary):

1. **Botón «+ Añadir»** simple y visible (cabecera del panel central / del flock).
2. Pregunta breve: **¿Flock nuevo** o **algo dentro de este flock?**
3. Si es «algo dentro», abre un **menú de opciones** (rejilla de tarjetas), con **lo que TARTARUS sí
   ofrece**:
   - **Beelzebub** — elegir **qué protocolos** activar para este cliente (SSH/HTTP/Telnet/TCP/MCP) y
     en qué puerto; se indica el puerto donde ya escuchan.
   - **Canary tokens** — documentos/credenciales trampa (por tipo).
   - **Honey credentials** — credenciales señuelo.
   - **Otros protocolos** que Beelzebub no cubre: **Modbus/OT (502)**, **ICMP canary**,
     **Prometheus falso (2113)**.
   - **Hardware / sensor remoto** — enrolamiento de un RPi u otro sensor de campo.
4. Al elegir, **te guía paso a paso** (qué puerto, qué personalidad, dónde plantar el cebo, etc.),
   **guardas** y **cierras**. Nada se despliega hasta confirmar.

**Punto clave del paso 3 (Beelzebub):** como los honeypots son compartidos, «activar SSH para este
cliente» = **registrar el puerto→flock** (atribución), + opcionalmente **elegir la personalidad** de
ese honeypot (Ubuntu, PowerShell, router, …). No se arranca un contenedor nuevo.

## 5. Personalidad del sensor (paso del onboarding)

Al añadir/activar un honeypot, el usuario elige su **disfraz (persona)**: p.ej. en el SSH (2222), si
lo quiere como **Ubuntu**, **PowerShell/Windows**, **router**, etc. Ya existe el mecanismo (personas +
`POST /services/{file}/llm` y el prompt del YAML); el flujo «Añadir» debe exponerlo como un paso claro.

## 6. Pestañas — reducir ruido (mantener 4)

Se conservan **Qué está pasando · Analizar · Infraestructura · Trampas**, pero se recorta densidad.
Inventario a afinar (pendiente de una tanda dedicada):

- **Qué está pasando:** demasiadas tarjetas/botones a la vez; dejar lo esencial arriba (línea de
  tiempo/timeline, eventos vivos, resumen) y colapsar lo secundario.
- **Analizar:** timeline con muchos toggles (Stacked/Split/Log/Severity/PNG/Excel); agrupar en un
  menú «⋯» y dejar visibles solo 1–2.
- **Infraestructura:** el hub mezcla salud de honeypots + embudo + servicios + sensores + cebos +
  hosts + escáner; separar «laboratorio compartido» de «lo del cliente» (ya iniciado) y colapsar
  paneles de diagnóstico (embudo/salud) bajo un desplegable.
- **Trampas:** revisar solapes con la sección de cebos del hub.

Criterio: **una acción principal por vista**; lo avanzado, detrás de un click. *Menos es más.*

## 7. Estado y próximos pasos

- **Hecho (28-ago):** honeypot SSH robusto (variantes de `ls`, estado de sesión con `cd`/`pwd`);
  separación visual opt-in (lab compartido vs cliente); este documento.
- **Siguiente:** construir el flujo «+ Añadir» guiado (§4) y la activación opt-in de protocolos;
  aplicar los recortes de pestañas (§6); persistir la clave de host SSH.

---

## 8. Shell del honeypot SSH — cómo se logró el estado (28-ago, actualización)

**Objetivo:** que el SSH actúe como Ubuntu real (`cd`, `ls`, `pwd` coherentes entre sí).

**Lo que funcionó (verificado en vivo):**
- `cd` / `pwd` / `ls` van al **LLM** (se quitaron los handlers estáticos de `ls`). El LLM mantiene el
  directorio actual por la sesión.
- **Prompt con árbol de ficheros explícito** (qué contiene cada directorio) + regla de `cd`
  **permisiva y desacoplada del árbol** (acepta casi cualquier ruta, solo rechaza typos evidentes) +
  regla de **arranque** («la sesión empieza en /home/admin»).
- **Modelo `gpt-4o`** — clave. `gpt-4o-mini` **no era capaz**: rechazaba `cd` válidos y fallaba `ls`.
  Coste: gpt-4o es ~15× más caro por llamada que mini; para un honeypot (poco volumen) es asumible,
  pero es una decisión de coste consciente.
- El prompt vive en **`personalities/ubuntu-server.yml`** (versionado). Al «Aplicar persona» se copia
  al servicio **conservando modelo y clave** (`personality_engine.apply` protege esos campos).

**Resultado:** sesión fresca → `pwd` = /home/admin; `cd projects` → `ls` = webapp/api-gateway/...;
`cd /var/log` → `ls` = auth.log/syslog/...; `cd proyects` → error. Consistente entre sesiones frescas.

**Límites honestos (el techo del enfoque LLM):**
- **~95%, no 100%.** Puede haber un glitch puntual (un `ls` raro), sobre todo en el primerísimo
  comando; se mitigó mucho con la regla de arranque, pero no se elimina del todo.
- **El estado se arrastra entre reconexiones de la MISMA IP** dentro del mismo proceso de Beelzebub
  (mantiene el historial por IP): si te reconectas, retomas el directorio donde quedaste. Un reinicio
  de Beelzebub lo resetea; IPs de atacantes distintos están aisladas.
- Para **100% determinista** (un filesystem falso real que nunca se contradice) haría falta otro motor
  tipo **Cowrie** — **agendado** como opción si el ~95% no basta.

Se conservan **estáticos** los comandos que no dependen del directorio y que son cebo exacto
(`cat /etc/passwd`, `cat /opt/app/.env` con honeytoken, `uname`, `ps`, `netstat`, …).

---

## 9. Entornos a medida generados por IA (28-ago) + per-cliente

**Nuestra ventaja sobre Thinkst:** Thinkst deja crear un árbol de ficheros a medida pero **estático**
(y un botón «Generate industry-specific file tree»). Nosotros lo **generamos por IA** y el contenido
(config, logs, código) sale al vuelo, consistente con el negocio.

**Generador (hecho):** `POST /personalities/generate-scenario` — el operador describe al cliente
(empresa, industria, datos sensibles) y el LLM (**gpt-4o**) devuelve un prompt de shell SSH a medida:
hostname realista, árbol de ficheros propio del negocio (p.ej. electrónica → `sensor_firmware/`,
`plc_configs/`, `scada_dashboards/`, `bom_october.pdf`, `supplier_contracts/`), usuarios, y las reglas
de shell con estado + anti-detección + contenido. En la UI: botón **«✨ Generar entorno con IA»** en
el editor de personas; se **prueba** con el banco (`probe`), se ajusta y se **guarda como persona**.
No aplica nada solo. Verificado en vivo con el caso de electrónica.

**Entorno base enriquecido (hecho):** el Ubuntu por defecto ahora genera `cat` creíble (config/logs/
código) y consistente por sesión, además del árbol con estado.

**Per-cliente (agendado — necesita la tanda de despliegue):** como el SSH es compartido, para que cada
flock tenga su propio entorno *a la vez* hace falta **un servicio SSH por cliente en su puerto**.
Beelzebub corre varios servicios (`ssh-2222`, `ssh-2223`, …), cada uno con su persona. Plan:
1. Pre-publicar un **rango de puertos** (p.ej. 2222-2231) en docker-compose (cambio único, recreate de
   Beelzebub — sin tocar la BD).
2. El flujo «+ Añadir» asigna a un flock: puerto libre del rango + su persona (la generada por IA) +
   reinicia Beelzebub.
3. La atribución por puerto (`sensor_registry`) ya existe: cada puerto → su flock.

Mientras tanto, el generador crea las **personas por cliente** (reutilizables); el SSH compartido se
tematiza con una a la vez para el engagement actual.

---

## 10. Árbol «estáticos + a medida» — la dirección de fondo (propuesta de Iván, 28-ago)

Idea de Iván (mezcla lo mejor de Thinkst + nuestra IA): **una estructura de árbol de ficheros
ESTÁTICA y editable** (determinista, ahorra tokens, siempre consistente) con el **LLM trabajando
ENCIMA** (contenido de ficheros e interacción). «Estáticos + a medida».

- **Modelo de árbol por persona**: carpetas/ficheros como datos (no solo texto en el prompt). Fuente
  de verdad de `ls`/`cd` → consistencia garantizada y menos tokens (no se regenera el listado).
- **Plantillas precargadas por industria/departamento** (IT, Seguridad, RH, Finanzas, OT/industrial…),
  como el «file tree» de Thinkst, listas para elegir y editar.
- **Editor de árbol en la UI**: desplegable de carpetas/ficheros, añadir/editar/quitar (como Thinkst
  «Files to Share»).
- **LLM encima**: genera el CONTENIDO de los ficheros (`cat`) y entretiene al atacante sobre la
  estructura fija; también puede **generar/afinar** una plantilla para una industria concreta.
- **Integración Beelzebub**: el árbol se vuelca al prompt como filesystem explícito (lo que ya hacemos,
  pero desde una estructura de datos editable) y/o como handlers; el LLM solo rellena contenido.

**Fases sugeridas:**
1. Modelo de árbol (datos) + 2-3 plantillas (IT/RH/OT) + volcado al prompt de la persona.
2. Editor de árbol en la UI (desplegable editable).
3. Generar/afinar plantilla por IA (el generador actual produce el árbol; el editor lo ajusta).
4. Determinismo real de `ls`/`cd` desde el árbol (evaluar Cowrie si se necesita 100%).

**Estado actual (puente, 28-ago):** SSH va **LLM-first** (el prompt de la persona controla todo el
entorno, incluidos hostname/usuarios/ficheros), con las **reglas afinadas fijas** en el generador. Es
~90-95% y funciona a medida ya; el árbol estático lo hará determinista. Pendiente menor: el banner SSH
usa `serverName` del YAML (no cambia con la persona) — al construir el árbol/persona conviene que
`serverName` también se tematice.
