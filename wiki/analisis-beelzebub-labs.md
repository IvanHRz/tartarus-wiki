---
tipo: analisis
creado: 2026-08-30
actualizado: 2026-08-30
tags: [beelzebub, competencia, capacidades, roadmap]
---

# Qué demuestran los labs de Beelzebub y qué de eso cubrimos

> Escrito el 30 de agosto de 2026, después de cerrar la fase B9. Documento **privado**: contiene
> juicios sobre el proyecto del que dependemos y el repositorio de código es público.
>
> Todo lo que se afirma sobre TARTARUS está comprobado leyendo el código y la base de datos, y va con
> su referencia. Lo que no se pudo verificar se marca como tal en vez de darlo por bueno.

## Por qué ahora

Beelzebub dejó de ser solo el honeypot que usamos. En julio de 2026 levantaron 3 M€ y hoy venden una
plataforma de tres piezas: los honeypots, **Caronte** (análisis) y **Arcangelo** (red team
autónomo). Su blog acumula **28 artículos** de investigación con capturas reales.

Su argumento de fondo —lo llaman «la era Mythos»— es que desde que un modelo encuentra
vulnerabilidades de día cero en serie, el coste de atacar se desplomó y la defensa tiene que
responder a velocidad de máquina. Las cifras que prometen: tiempo de respuesta de horas a segundos,
falsos positivos a cero, coste del centro de operaciones −60 %, análisis de malware de días a
minutos.

La pregunta que contesta este documento es simple: **de todo eso, ¿qué cubrimos y qué no?**

## El resumen, sin adornos

**Donde vamos por delante** — y no es poco:

- El **informe de engagement** tiene 17 secciones con cadena de custodia, trazabilidad de hipótesis a
  conclusión y cumplimiento normativo, en PDF, HTML y JSON, bilingüe. Ningún lab suyo enseña un
  entregable así. Es nuestro activo más fuerte y el más difícil de copiar.
- **398 reglas Sigma** (7 marcadas como obsoletas, así que 391 activas) **y 436 reglas YARA**
  repartidas en 74 ficheros. El `CLAUDE.md` todavía dice «76 Sigma, 20 YARA»: es una cifra de
  marzo que lleva cinco meses sin actualizarse.
- **Separación real por cliente**, auditada en 39 superficies con 0 fugas. Ellos ni la mencionan.
- **Cebos con secreto único y regla de reúso**, atribución por sensor, y cebos en el árbol de
  ficheros del honeypot.

**Donde estamos dispersos** — y aquí la palabra del jefe es exacta:

- **No capturamos un solo byte de lo que el atacante trae.** El escenario que más nos interesa —el
  actor real que descarga un bot IRC— hoy produce dos filas de texto y nada más.
- **Exportamos indicadores falsos.** El campo `sha256` es el hash del mensaje del evento —su propio
  docstring lo dice: «*Chain of custody: SHA256 of the raw event payload*»— y aun así el bundle STIX
  lo emite como `[file:hashes.'SHA-256' = …]` con el nombre «*Malicious File SHA-256*». Cualquier
  SIEM que consuma ese bundle recibe indicadores de ficheros que no existen.
- **El honeypot se delata** tras un `wget`: el fichero descargado no aparece en el `ls` siguiente.
- **Lo que sí tenemos, no lo hemos estrenado**: la separación por cliente está construida y con la
  sesión apagada; la detección de inyección de prompt existe y nunca se ha disparado.

La ventaja es real, pero es una ventaja **en el entregable**, no en la captura. Ellos capturan más y
analizan mejor; nosotros contamos mejor lo capturado. Y lo nuestro está a medio encender.

---

## 1. Los 28 labs, uno a uno

Cada lab reducido a la capacidad que demuestra. El veredicto usa cuatro estados: **Sí** (lo
cubrimos), **Parcial** (con qué falta exactamente), **No**, y **No aplica** (con el motivo).

### Familia A — Captura de artefactos y análisis de malware

Es la familia más numerosa y donde está el hueco grande.

| # | Lab | Capacidad que demuestra | ¿Nosotros? |
|---|---|---|---|
| 1 | [SSH LLM Honeypot caught a real threat actor](https://beelzebub.ai/blog/ssh-llm-honeypot-caught-a-real-threat-actor/) | Actor real descarga un bot IRC en Perl; se analiza y se extrae el servidor de mando, los canales y el usuario | **Parcial.** Capturamos la sesión, las credenciales y el comando con su técnica MITRE. **No** el fichero, ni nada de su contenido |
| 2 | [Rust DDoS botnet: ingeniería inversa + honeypot C2](https://beelzebub.ai/blog/rust-ddos-botnet-honeypot-c2-decoding/) | Ghidra, sandbox, decodificar el protocolo binario y construir un bot falso que espía al servidor de mando | **No.** Es el lab más avanzado de todos |
| 3 | [Evolution RAT (HVNC)](https://beelzebub.ai/blog/evolution-rat-hvnc-browser-session-hijacking/) | Ingeniería inversa de una plataforma de secuestro de sesión de navegador | **No** |
| 4 | [Needle: C2 modular robacriptos](https://beelzebub.ai/blog/needle-c2-crypto-stealer-analysis/) | Análisis de infraestructura de mando con las claves dentro del propio malware | **No** |
| 5 | [MacSync Stealer](https://beelzebub.ai/blog/macsync-stealer-fake-claude-code-google-ads/) | Anuncio de Google que instala un Claude Code falso y compromete el Mac | **No aplica** — es investigación de campaña, no capacidad de honeypot |

### Familia B — Superficies de ataque que no cubrimos

| # | Lab | Superficie | ¿Nosotros? |
|---|---|---|---|
| 6 | [RedTail: primera evidencia contra la API de Docker](https://beelzebub.ai/blog/redtail-cryptominer-first-evidence-of-docker-api-targeting/) | **API de Docker en el 2375** | **No** |
| 7 | [RedTail evoluciona: entrega por SSH](https://beelzebub.ai/blog/redtail-docker-api-campaign-evolves/) | La misma, con entrega multi-etapa por SCP con reserva HTTPS | **No** |
| 8 | [wp2shell: RCE de WordPress sin autenticar](https://beelzebub.ai/blog/catching-wp2shell-in-the-wild/) | WordPress | **No** |
| 9 | [Operation PCPcat: robacredenciales de Next.js](https://beelzebub.ai/blog/threat-huntinga-analysis-of-a-nextjs-exploit-campaign/) | Next.js (59 000 servidores) | **No** |
| 10 | [CVE-2026-24423 en SmarterMail](https://beelzebub.ai/blog/watching-cve-2026-24423-hit-the-wire/) | Servidor de correo | **No** |
| 11 | [Kubernetes: detectar movimiento lateral](https://beelzebub.ai/blog/deploy-beelzebub-honeypot-on-kubernetes/) | Kubernetes | **No** |
| 12 | [Engaño defensivo con Kong](https://beelzebub.ai/blog/defensive-deception-with-kong-and-beelzebub-llm-honeypot/) | Pasarela de API | **No** |
| 13 | [ScreenConnect por URLs de seguridad falsificadas](https://beelzebub.ai/blog/fake-update-screenconnect-email-security-spoofing/) | Escritorio remoto | **No** |

Nuestras superficies hoy: SSH, Telnet, HTTP, HTTPS, TCP, MCP, Prometheus, Modbus e ICMP. Fuertes en
lo clásico y en industrial; ausentes en todo lo de contenedores y aplicación web moderna.

### Familia C — Velocidad de captura de días cero

| # | Lab | Qué demuestra | ¿Nosotros? |
|---|---|---|---|
| 14 | [Ni8mare (CVE-2026-21858)](https://beelzebub.ai/blog/catching-ni8mare-in-the-wild-cve-2026-21858/) | 48 horas del aviso a la explotación en vivo | **No.** Requiere estar expuesto a internet y con reglas al día |
| 15 | [CVE-2026-24061: 11 años de acceso root](https://beelzebub.ai/blog/catching-cve-2026-24061-in-the-wild/) | Captura de una vulnerabilidad muy antigua explotada hoy | **No** |
| 16 | [Malware que se autoactualiza (time-to-exploit −1)](https://beelzebub.ai/blog/how-advanced-malware-self-update-systems-enable-exploitation-before-patches-can-be-applied/) | Explotación antes de que exista el parche | **No aplica** — es investigación |

**Lo que esta familia deja claro:** su ventaja aquí no es tecnológica, es de **exposición**. Tienen
honeypots en internet recibiendo tráfico real. Nosotros corremos en un laboratorio local. Ninguna
mejora de código cierra ese hueco: se cierra desplegando en campo.

### Familia D — Agentes de IA y MCP

La familia más nueva y donde su ventaja es más frágil.

| # | Lab | Capacidad | ¿Nosotros? |
|---|---|---|---|
| 17 | [Cazando agentes de IA: el cebo corrupto](https://beelzebub.ai/blog/catching-ai-agents-in-the-wild/) | Una credencial rota a propósito con un marcador. Un escáner no la ve; un humano tarda 7-10 min; **un agente de IA la repara en 4 segundos**. La señal no es la velocidad, es que alguien arregló un secreto que ningún patrón sabe leer | **No** — pero *encaja* con los cebos que ya tenemos |
| 18 | [Cazando red teamers de IA: inyección inversa de prompt](https://beelzebub.ai/blog/catching-ai-red-teamers-in-the-wild/) | Usar la inyección de prompt **al revés**, como detector de que quien mira es una IA | **No** |
| 19 | [Azazel: trazado de agentes en ejecución](https://beelzebub.ai/blog/azazel-runtime-tracing-for-ai-agents/) | Ver qué hace de verdad un agente dentro del contenedor | **No** |
| 20 | [Asegurar agentes de IA con honeypots](https://beelzebub.ai/blog/securing-ai-agents-with-honeypots/) | Herramientas señuelo para entornos de agentes | **Sí (31-ago-2026).** El señuelo MCP habla JSON-RPC de verdad (initialize/tools/list/tools/call), el evento guarda la herramienta llamada y sus argumentos, y la batería ejercita inyección de prompt que dispara `yara:AI_Prompt_Injection` (antes existía y nunca se había disparado) |
| 21 | [It Thought It Had Won](https://beelzebub.ai/blog/it-thought-it-had-won/) | Secuestro de modelos | **No aplica** — investigación |

### Familia E — Persistencia y evasión

| # | Lab | Capacidad | ¿Nosotros? |
|---|---|---|---|
| 22 | [React2Shell: 10 capas de supervivencia](https://beelzebub.ai/blog/react2shell-cryptominer-persistence-campaign/) | Analizar mecanismos de persistencia encadenados | **Parcial** — hay reglas Sigma de persistencia, pero sin el fichero no se analiza el mecanismo |
| 23 | [RondoDox v2: 650 % más exploits](https://beelzebub.ai/blog/rondo-dox-v2/) | Seguimiento de la evolución de una botnet | **No** |
| 24 | [Cloudflare WARP filtrando IPs por Tor](https://beelzebub.ai/blog/catching-cloudflare-warp-leaking-real-ips-through-tor/) | Desanonimizar tras una VPN | **No aplica** — hallazgo puntual |
| 25 | [Campañas automatizadas contra OpenClaw](https://beelzebub.ai/blog/automated-reconnaissance-targeting-openclaw-gateways/) | Reconocimiento automatizado contra pasarelas de agentes | **No** |

### Familia F — Fundamentos

| # | Lab | Capacidad | ¿Nosotros? |
|---|---|---|---|
| 26 | [LLM Honeypot con Beelzebub](https://beelzebub.ai/blog/llm-honeypot-with-beelzebub-framework/) | Honeypot SSH con modelo de lenguaje | **Sí, y por delante.** El nuestro resuelve el shell de forma determinista (fase B1) y solo cae al modelo en lo raro: `cd`, `ls` y `pwd` en 2,5-5 ms frente a 1-2 s |
| 27 | [LLM Honeypot contra cryptojacking](https://beelzebub.ai/blog/llm-honeypot-vs-cryptojacking-understanding-the-enemy/) | Capturar mineros | **Sí** — hay reglas YARA de mineros y el comando queda registrado |
| 28 | [Cómo atacan los ciberdelincuentes](https://beelzebub.ai/blog/how-cybercriminals-attacks-your-company/) | Divulgación | **No aplica** |

**Recuento:** cubrimos del todo 3 (el lab 20 pasó de «Parcial» a «Sí» el 31-ago-2026), parcialmente 3, no cubrimos 16, y 6 no aplican.

---

## 2. Caronte y Arcangelo, capacidad por capacidad

### Caronte — el motor de análisis

| Capacidad que reclaman | Lo nuestro | Distancia real |
|---|---|---|
| **Triaje de alertas**: filtrar ruido para exponer infraestructura adversaria y campañas | **Lo tenemos, y bien.** Correlación por sesión, agrupación por entropía, cadenas de ataque contra plantillas, reconstrucción de la cadena de muerte multi-protocolo | **Ninguna.** Aquí estamos a la par o por delante |
| **Decompilación con LLM**: traducir ensamblador ofuscado a un informe en lenguaje natural | **No existe.** Nuestro análisis con modelo recibe 8 campos de texto y ni siquiera incluye la salida del comando | **Grande.** Necesita el fichero primero |
| **Sandbox seguro**: ejecutar el payload aislado y capturar comportamiento y llamadas de red | **No existe** | **Grande**, y descartada por decisión: guardamos sin ejecutar |
| **Mapeo de infraestructura**: correlacionar indicadores globales para dibujar la huella del adversario | **Parcial.** Enriquecemos IPs con cuatro fuentes; no correlacionamos entre incidentes ni construimos la huella | **Media** |
| **Correr en local, sin nube** | **Lo tenemos de serie**: todo el motor es nuestro y el modelo es configurable | **Ninguna.** Es un argumento de venta de ellos que nosotros ya cumplimos |

**Lectura:** de las cinco capacidades de Caronte, dos las tenemos, una es media y **dos dependen de
lo mismo: capturar el fichero**. Ese es el nudo. Sin bytes no hay ingeniería inversa ni sandbox, y
con bytes se abren las dos a la vez.

### Arcangelo — el red team autónomo

| Capacidad que reclaman | Lo nuestro | Distancia real |
|---|---|---|
| **Simulación adversaria continua 24/7** | Tenemos baterías de ataque **manuales** (`make attack`), y dos de los scripts ni siquiera generan tráfico: insertan eventos en la base para poblar el panel | **Grande** |
| **Reconocimiento externo de superficie** (incluida la web oscura) | El escáner corre nmap **cuando alguien le da un objetivo**. No se autodescubre | **Grande** |
| **Ataques contra modelos**: jailbreak, ataques semánticos, inyección de prompt | **Cero cobertura ofensiva.** Y la batería ni siquiera envía payloads de inyección al señuelo MCP | **Grande** |
| **Simular campañas APT** con robo de credenciales y movimiento lateral | Las plantillas de cadena existen **en detección**, no en ataque | **Media** — el modelo de fases ya está |
| **Plan de remediación** mapeado a MITRE, NIST CSF, ISO 27001, DORA, NIS2, EU AI Act | **Lo tenemos**: el informe ya trae recomendaciones, mapeo MITRE y sección de cumplimiento normativo | **Ninguna** |

**Lectura:** aquí el hueco es casi total, **y probablemente esté bien que lo sea**. Arcangelo es un
producto ofensivo: otra disciplina, otro riesgo legal y otro cliente. Lo único que merece la pena
robarle es la idea de **ejercitar nuestras propias defensas de forma continua** — no para atacar a
nadie, sino para que una regla que nunca se ha disparado no siga contando como cobertura.

---

## 3. Las superficies que no cubrimos, con su coste

Ordenadas por relación entre lo que dan y lo que cuestan:

| Señuelo | Por qué interesa | Coste | Notas |
|---|---|---|---|
| **API de Docker (2375)** | Aparece en **dos** labs suyos. Objetivo muy atacado y poco vigilado. Entrega multi-etapa real | **Bajo** | Es HTTP plano: `GET /containers/json`, `POST /exec`. Con la fusión de personas arreglada en B9, es escribir un YAML de rutas y una regla Sigma |
| **WordPress** | La superficie más atacada de internet | **Bajo** | Rutas HTTP y respuestas creíbles |
| **Kubernetes (API en 6443/10250)** | Movimiento lateral en clúster | **Medio** | Más superficie y respuestas más complejas |
| **Pasarela de API (Kong)** | Encaja con lo que ya tenemos | **Medio** | |
| **SmarterMail / correo** | Vector de entrada clásico | **Alto** | Protocolo con estado |

**Recomendación:** la API de Docker primero, y sola. Es la que más captura da por menos trabajo, y
además es el escenario exacto de dos labs, así que sirve de validación contra un caso real
documentado.

---

## 4. Agentes de IA y MCP

Es la parte donde el mercado aún no tiene estándar, y donde nuestra posición es peor de lo que
parece.

**Lo que tenemos:**

- Un señuelo MCP con cuatro herramientas trampa (`data-query`, `get-credentials`, `create-ticket`,
  `system-status`).
- Dos reglas Sigma de abuso de herramienta y cinco YARA de MCP y abuso de IA, entre ellas
  `AI_Prompt_Injection`, conectada a la ingesta.

**Lo que no funciona:**

- **No habla MCP.** Es HTTP con JSON fijo: sin JSON-RPC, sin negociación, sin despacho por método.
  Un cliente MCP real se cae en el primer mensaje. `/tools/call` siempre devuelve el mismo 401 sin
  mirar los argumentos.
- **La detección de inyección de prompt nunca se ha ejercitado.** La regla existe, pero la batería de
  ataque no envía ni un `ignore previous instructions`. Una regla que nunca se ha disparado no es
  cobertura: es una intención.
- **El modelo del propio honeypot no tiene protección anti-jailbreak.**
- **El puerto no concuerda**: el YAML escucha en el 3000, los scripts atacan el 3001.

**La idea que sí merece copiarse: el cebo corrupto.** Es elegante y barata. Se planta una credencial
rota a propósito con un marcador dentro. Un escáner no la reconoce; un humano tarda entre siete y
diez minutos en limpiarla y probarla; **un agente de IA la repara y la usa en unos cuatro segundos**,
porque entiende la intención del enmascarado. La señal defensiva no es la velocidad en sí, sino que
*alguien reparó un secreto que ninguna expresión regular sabe leer*.

Encaja de lleno con lo que ya tenemos: los cebos con secreto único, la regla de reúso y la medición
del momento del disparo. Lo que falta es la variante corrupta y medir el tiempo entre que se sirve y
se dispara. Es de lo más barato de esta lista y de lo más diferenciador.

---

## 5. Qué haría yo, y en qué orden

**Antes de añadir nada, encender lo que ya está construido.** Es lo que sostiene la frase «estamos
dispersos»: hay tres cosas hechas y sin estrenar —la separación por cliente con la sesión apagada, la
detección de inyección de prompt sin ejercitar, y el señuelo MCP que no habla su protocolo— y una que
está mal —el hash falso en el bundle STIX—. Ninguna de ellas es trabajo nuevo: es terminar.

**Después, y en este orden:**

1. **Capturar el fichero.** Es el nudo del que cuelgan dos capacidades de Caronte, y es el escenario
   que abre este documento. Descargando y guardando, sin ejecutar.
2. **El señuelo de la API de Docker.** Máxima captura por mínimo trabajo, y validable contra dos
   labs reales.
3. **El cebo corrupto para agentes.** Barato, diferenciador, y construido sobre lo que ya tenemos.

**Lo que NO haría:** perseguir a Arcangelo. Es otro producto, otra disciplina y otro riesgo. Y
tampoco perseguir la velocidad de captura de días cero, porque eso no se arregla programando: se
arregla exponiendo sensores a internet, que es una decisión de despliegue.

## Lo que este documento no prueba

- Las cifras de Beelzebub (tiempo de respuesta en segundos, cero falsos positivos, −60 % de coste)
  son **material comercial suyo**, no medidas independientes. Se citan como lo que son.
- El detalle de Caronte y Arcangelo sale de su web y su libro blanco, **no de haberlos usado**.
- Los 28 labs se recogieron de las cinco páginas de su blog el 30 de agosto de 2026. Si publican
  más, esta lista se queda corta.
