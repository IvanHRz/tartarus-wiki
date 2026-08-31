
## [2026-08-29] bitacora | Parte B · Fase B7b HECHA: el motor de comandos de Windows
Cierra B7. La persona `windows-server` ya no la contesta el modelo: la resuelve el motor determinista,
igual que Linux desde B1. La puerta de entrada del motor elige por familia (Linux / Windows / aparatos de
red), las listas de comandos se separaron por familia en el mismo cambio (`dir` apuntaba al listado de
Linux y era una mina esperando), y Windows dejó de distinguir mayúsculas — con una sola forma de escribir
la ruta en la siembra y en la lectura del cebo, que era donde estaba el riesgo real: se plantaba y no se
servía nunca, sin dar error. Nuevo `engine/engine/windows_shell.py` con las carpetas base, los metadatos y
los manejadores; errores literales de PowerShell; `pushd`/`popd` sin tocar el contrato del motor; y el
indicador `PS C:\Users\Administrator>` vía el parche del honeypot, regenerado desde un clon y validado
con las pruebas del proyecto original. Verificado por SSH real, incluido el ciclo completo del cebo
(marcar → leer → reutilizar → alerta con riesgo 85). Suite 1686 verde. Detalle en [[roadmap-operativo]]
(29-ago, Fase B7b). Registrados dos hallazgos sin corregir: el indicador salta al reconectar (viene del
proyecto original, afecta también a Linux) y guardar una persona por la API reescribe su fichero.
— claude

## [2026-08-29] plan | Parte B · Fase B5b: fusionar el árbol por industria con el bundle de cebos
Plan aceptado archivado en [[planes/2026-08-29]]. Objetivo: que el generador de árboles por industria
deje de ser medio decorado — hoy sus archivos de relleno son texto estático sin secreto único ni regla
de reúso, así que robarlos no dispara nada — acuñando cada entrada por la vía madura del bundle, con
su ZIP anidado, sus jobs en Redis y un botón en la consola que hoy no existe.
— claude

## [2026-08-29] bitacora | Parte B · Fase B5b HECHA: el árbol por industria ya es un sensor
Cierra la Parte B. Los archivos de relleno del árbol por industria eran texto fijo sin secreto propio ni
alerta: robarlos y usarlos no disparaba nada, aunque la máquina para generarlos ya existía y funcionaba
para el paquete de cebos suelto. Ahora cada hoja del árbol se acuña por esa misma vía, con su ruta real
registrada. Corregidos los tres fallos anotados (relleno genérico por instrucciones incompletas a la IA,
documentos sin ruta ni cliente, árbol guardado en memoria sin caducidad) y dos más encontrados al
verificar, que afectaban también al despliegue asistido: extensiones repetidas y rutas que guardaban solo
la carpeta sin el nombre del archivo. El paquete gana carpetas anidadas y un script de plantado que por
primera vez se ejecuta en una prueba. Botón nuevo en la consola, que hasta hoy no llamaba a esta función
en absoluto. Verificado en vivo con el ciclo completo del cebo (riesgo 85 al reusar la credencial del
árbol). Suite 1702 verde. Detalle en [[roadmap-operativo]] (29-ago, Fase B5b).
— claude

## [2026-08-30] plan | Fase B8: alertas que sí saltan, estrictez simétrica y el honeypot web
Plan aceptado archivado en [[planes/2026-08-30]]. Sale de una auditoría de 31 agentes con refutación
adversarial (24 hallazgos confirmados). El objetivo: que la alerta salte cuando alguien entra —hoy no lo
hace porque el marcador de apertura del honeypot se cuenta como comando tecleado y de paso pisa la táctica
MITRE que era su única puerta de salida—, que un comando de Windows en un Linux se niegue en código igual
que al revés, y que el honeypot web deje de descartarse en dos peticiones.
— claude

## [2026-08-30] plan | Fase B9: desatascar la consola, fuga entre clientes y honeypot web
Plan aceptado archivado en [[planes/2026-08-30]]. Sale de una investigación de 18 agentes en cuatro
frentes. Lo que impedía trabajar no era lo que parecía: al recrear un contenedor, Docker reasignó las
direcciones y nginx tenía cacheada la vieja, así que toda la consola devolvía 502. La fuga entre
clientes resultó ser mucho mayor de lo visible —incluido el informe que se entrega al cliente— y se
ataca con un test que la impida volver. La decisión del ICMP quedó resuelta con una cuarta opción que
no estaba sobre la mesa.
— claude

## [2026-08-30] bitacora | Fases B8 (1-2) y B9 (0-1): la alerta ya salta al entrar, y la consola desatascada
Dos tandas seguidas. La primera resolvió la queja de Iván («no avisa cuando entro»): no era el umbral,
era que el aviso de apertura del honeypot se contaba como comando tecleado y de paso le cambiaba la
etiqueta de la técnica de ataque por una que no dispara aviso — puntuaba más y avisaba menos. De 538
conexiones, 459 estaban mudas y ninguna llevaba la etiqueta correcta. Se añadió el modelo de dos
niveles (aviso inmediato + resumen al cerrar sesión), se arregló un filtro anti-ruido que llevaba
meses sin filtrar nada, se desactivó una inundación que el Telnet tenía preparada, y el limitador dejó
de comerse alertas legítimas. Cada supresión queda ahora registrada: antes era muda, y eso es lo que
mantuvo el problema invisible.

La segunda desatascó la consola, que llevaba un rato sin dejar hacer nada. La causa fue mía: al
reconstruir un contenedor, Docker repartió las direcciones de otra manera y el servidor web se quedó
hablando con una dirección muerta. Y el primer arreglo trajo otro peor —todas las rutas contestaban
«bien» con el contenido equivocado—, que se dio por bueno porque la verificación miró códigos de
respuesta en vez de contenidos. Ya hay una prueba automática que caza esa trampa. También se corrigió
que lo desplegado desde el asistente nacía sin dueño, invisible en la vista de todos los clientes: eso
era la otra mitad del «se borró todo». Nada se había borrado.

Queda por hacer la fuga entre clientes (de 186 rutas, 130 no declaran a qué cliente pertenecen, y el
informe que se entrega al cliente puede llevar datos de otro), el ping —con la decisión ya investigada
y tomada— y el honeypot web. Detalle en [[roadmap-operativo]] (30-ago) y el arranque de la siguiente
sesión en [[prompt-siguiente-sesion]].
— claude

## [2026-08-30] bitacora | Fase B9 bloque 2 — la fuga entre clientes, cerrada
Lo más grave que quedaba: que un cliente pudiera ver los datos de otro. Lo primero que cambió fue el
diagnóstico. Cuatro de los cinco puntos que se daban por rotos **ya estaban arreglados en el motor**
—el informe, las notificaciones, el canal en vivo y el repintado de la pantalla—: el agujero se había
mudado a la interfaz, que de sus 127 llamadas solo decía de qué cliente pedía en 27. El motor
filtraba bien y nadie le decía por quién filtrar. El informe que se ENTREGA al cliente traía 910
eventos de otro; pidiéndolo con el cliente puesto, 0.

Medido con dos clientes en la base, uno con 910 eventos y otro con cero, así que cualquier número
distinto de cero era una fuga demostrada. Lo peor suelto: la ruta de indicadores de compromiso, con
100 comandos y 50 credenciales del vecino. También 434 detecciones, 587 acciones de auditoría, el
relato cronológico del ataque ajeno y el correo real del proveedor dentro de la configuración de
avisos de un cliente. De 185 rutas, las que declaran cliente pasan de 56 a 91.

Antes de arreglar nada se puso la red, porque este trabajo se deshace solo: un criterio único para
acotar consultas (había tres conviviendo), dos guardarraíles que recorren las rutas y las llamadas de
verdad y fallan si alguna lee datos sin decir de quién, y la auditoría viva ampliada de 19 a 39
superficies. Y se comprobó que la red sirve quitando un filtro a mano: lo cazó en las dos
direcciones. Las dos listas de pendientes quedan vacías.

Por el camino aparecieron cosas que no estaban en el plan y eran peores que varias fugas de lectura:
un gestor podía **borrar el cliente de otro** (el control miraba el rol pero nunca sobre qué cliente
se actúa, y la función que faltaba llamar llevaba meses escrita sin usar); dos clientes no podían
tener el mismo cebo, y el segundo recibía **el identificador del cebo del primero**, creyendo tener
uno que no era suyo; probar un canal de avisos **escribía** en la configuración global; y las notas
del analista eran una libreta compartida donde uno pisaba las del otro.

Lo honesto que queda: el recorte por rol sigue sin estrenar en uso real, porque la variable que
enciende las sesiones no está puesta en ninguna parte. Hoy el aislamiento descansa entero en que el
navegador diga de qué cliente pide. Todo está construido para que encenderla sea configuración y no
programación, pero hasta entonces esa mitad es teoría.

Pruebas 1762 en verde (1734 al empezar). Auditoría viva: 0 fugas. Detalle en [[roadmap-operativo]]
(30-ago, bloque 2), la medición completa en [[registro-pruebas]] y el plan verbatim en
[[planes/2026-08-30]]. Repo: `6a6c82b`.
— claude

## [2026-08-30] bitacora | Fase B9 bloques 3 y 4 — el ping y el honeypot web
Los dos últimos bloques de la fase, y otra vez lo primero que cambió fue el diagnóstico: **dos
premisas del plan no se sostenían**. Ni el respondedor ARP «que ya funcionaba» ni el laberinto
anti-escáner «que desapareció el 29-ago» existían en ninguna parte — ni en el árbol, ni en el
historial completo, ni en las veintiuna ramas, ni dentro de los contenedores. Las dos se habían
probado en vivo sin guardarse. Y en el caso del laberinto había un mecanismo que lo explicaba y seguía
activo: aplicar una personalidad borraba de un plumazo toda la configuración de rutas del honeypot.
Por eso ese arreglo fue lo primero, y no las rutas: sin él, lo demás se habría vuelto a perder.

El honeypot web se identificaba como tal en la primera petición: `/`, `/admin`, `/.env` y `/wp-admin`
devolvían los cuatro exactamente los mismos bytes. Ahora hay once rutas con las páginas de error
reales de un servidor, una pantalla de acceso donde interesa que el atacante insista, y el laberinto
recogiendo lo que no casa con nada. Y por fin hay cebos: el mecanismo llevaba tiempo construido y no
lo llamaba nadie, así que la fachada se servía sin uno solo. Se siembran dos, con propósitos
distintos — una baliza que se dispara sola y un comentario en el fuente que promete un volcado de base
de datos, que solo salta si alguien lee el código y decide ir a mirar.

En el ping, el sensor llevaba cero avisos desde que se creó. No era que no alertase: nadie contestaba
la pregunta ARP por las direcciones señuelo, así que el ping no salía del Mac. Sobre la tormenta de
paquetes que había aparecido en pruebas anteriores, el repositorio se contradecía a sí mismo, así que
en vez de elegir se midió: 0 paquetes en reposo, **94 en 12 segundos** con el reenvío del sistema
activado, **0** con él desactivado. La hoja de ruta tenía razón y ahora hay números. Resultado: 0 % de
pérdida, TTL 63 en el perfil Linux y 127 en el Windows, sin respuestas duplicadas, y 13 avisos en la
base donde llevaba 0 desde el principio.

Tres cosas se descubrieron solo al probarlas, no leyendo el código: el laberinto sobrevivía en el
fichero pero no actuaba, porque la personalidad traía una regla comodín que se lo comía; el cebo caía
en una página que la personalidad tapaba; y el volcador de YAML destroza el HTML al reescribirlo,
metiendo una línea en blanco por cada salto.

Pruebas 1810 en verde (1762 al empezar). El aislamiento entre clientes del bloque 2 sigue en 0 fugas.
Detalle en [[roadmap-operativo]] (30-ago, bloques 3 y 4), las mediciones en [[registro-pruebas]] y el
plan verbatim en [[planes/2026-08-30]]. Repo: `a67f55e`.
— claude

## [2026-08-30] analisis | Los 28 labs de Beelzebub, Caronte y Arcangelo — qué cubrimos y qué no
Subida la fase B9 a GitHub (siete commits de código, dos de wiki) y hecho el análisis comparativo
contra Beelzebub, que ya no es solo el honeypot que usamos: levantaron tres millones en julio y hoy
venden una plataforma con **Caronte** (análisis de malware con IA) y **Arcangelo** (equipo rojo
autónomo). Su blog acumula 28 investigaciones con capturas reales.

La cuenta honesta: de los 28 laboratorios cubrimos **2 del todo, 4 a medias y 16 no**, y 6 no aplican.
Vamos por delante en el entregable —el informe de diecisiete secciones con cadena de custodia y
cumplimiento normativo no lo enseña ninguno de sus labs, y la separación entre clientes ni la
mencionan— pero por detrás en la captura: **no guardamos ni un byte de lo que el atacante trae**.

Tres hallazgos que salieron de mirar nuestro propio código con esa lupa. **Exportamos indicadores
falsos**: el campo que llamamos hash es el del mensaje del evento —lo dice su propio comentario— y
sale al paquete STIX etiquetado como hash de fichero malicioso, así que cualquier SIEM que lo consuma
recibe huellas de ficheros inexistentes. **El honeypot se delata** tras una descarga, porque el
fichero no aparece en el listado siguiente. Y **la detección de inyección de prompt nunca se ha
disparado**: la regla existe, está conectada, y la batería de pruebas no envía ni un intento — una
regla que jamás ha saltado no es cobertura, es una intención.

El roadmap sale en dos bloques con una regla de orden explícita: **no se abre nada nuevo hasta cerrar
lo que está a medias**, que es la respuesta a la sensación de dispersión. Primero diez puntos de
cierre (el hash falso, encender la separación entre clientes que está construida y apagada, el MCP que
no habla su protocolo, ejercitar la inyección de prompt); después seis capacidades nuevas, empezando
por capturar los ficheros —descargando y guardando, nunca ejecutando— y el señuelo de la API de
Docker, que es el que más da por menos trabajo.

Y tres cosas que se deciden NO hacer, con su motivo: perseguir a Arcangelo (es un producto ofensivo,
otra disciplina), detonar malware en sandbox, y competir en velocidad de captura de vulnerabilidades
nuevas — porque ahí su ventaja no es tecnológica sino de exposición, y eso no se arregla programando
sino desplegando sensores en internet.

Detalle completo en [[analisis-beelzebub-labs]], roadmap en [[roadmap-operativo]] (30-ago, Fase C) y
el plan verbatim en [[planes/2026-08-30]]. Repo: `a67f55e`, ya subido.
— claude

## [2026-08-30] cierre | Fase B9 completa y subida; fase C planificada
Cierre de una tanda larga. La **fase B9 queda cerrada entera** (bloques 0-1, 2, 3 y 4) y **subida a
GitHub**, tanto el código como la wiki. Pruebas en 1810 verde y el aislamiento entre clientes en cero
fugas sobre 39 superficies.

Se añade la **fase C** al roadmap, con una regla de orden que responde a la sensación de dispersión:
no se abre nada nuevo hasta cerrar lo que está a medias. Y dentro de ella un bloque que salió de una
observación de Iván: **la contraseña del servidor está en la pestaña de Infraestructura y no en la de
Trampas**. Al comprobarlo resultó más amplio — el modal de configuración de un honeypot solo se abre
desde Infraestructura y contiene seis controles de engaño frente a uno solo de infraestructura. Queda
también por evaluar qué parámetros faltan: cuánto aguanta la sesión, qué usuarios se aceptan en el
login, y el laberinto y los cebos web que funcionan sin control en la consola.

Reescrito [[prompt-siguiente-sesion]] con todo el estado y el orden de trabajo.
— claude

## [2026-08-30] bitacora | Fase C · Bloque A cerrado — los 8 puntos, tres estaban mal descritos
Se cerró el bloque A entero de la fase C: terminar lo que ya existía antes de abrir capacidades nuevas.
La regla se respetó — no se abrió nada del bloque B. Lo importante de la sesión no fue tachar ocho
casillas, sino que **tres de los ocho estaban mal descritos** y se corrigieron al medirlos, no al leerlos.

El **hash falso del STIX** era lo único que salía mal hacia fuera: el exportador emitía el hash del
cuerpo del evento (cadena de custodia) como si fuera la huella de un fichero de malware. Medido en vivo,
el bundle de una semana traía 114 objetos y **100 eran huellas de ficheros que no existen**; ahora trae
14, todos indicadores que un SIEM puede usar. El dato no se perdió: sigue en la tabla de integridad del
informe, que es su sitio.

Los **números que decíamos de nosotros mismos** estaban desfasados en CLAUDE.md («76 Sigma, 20 YARA») y
—sorpresa— también en el propio ROADMAP, que decía «436 YARA en 74 ficheros». Son **398 Sigma (391
activas) y 439 reglas YARA en 95 ficheros**. El 74 salía de contar mal. Y el detector de deriva que
existía para cazar justo esto llevaba meses en rojo **porque no lo ejecutaba nadie**: ahora corre en CI.

Se **retiró `maze_tagger.py`** después de comprobar, no de suponer: seis golpes al laberinto en vivo
llegan con el `Handler` que el módulo intentaba adivinar; el módulo hasta se perdía golpes que Beelzebub
sí marcaba. **Telnet** dejó de llamar al proveedor por su cuenta —ahora va por el motor, sin clave en el
fichero— y por el camino se vio que su prompt no llevaba ninguna de las reglas de router porque la
persona nunca se le había aplicado. El **honeypot MCP** ahora habla MCP de verdad (JSON-RPC): antes dos
mensajes distintos devolvían la misma respuesta y un cliente real se caía.

La **inyección de prompt** pasó de no probarse nunca a saltar 8 detecciones, y midiéndola se cerró de
paso el punto del **anti-jailbreak**, que el ROADMAP daba por ausente: existe, y el honeypot aguantó los
doce intentos sin revelar nada. El punto más gordo fue el **recorte por rol**: al encender la sesión
—en un engine aparte, sin tocar el de desarrollo— se vio que solo estaba cableado en 4 de una veintena
de routers, y que un usuario de solo lectura podía crear cebos y borrar credenciales trampa. Se cableó el
guardarraíl en las ~45 escrituras de consola que faltaban, dejando fuera a propósito las de los sensores
y honeypots. La auditoría nueva da 37 de 37 sin una sola fuga.

Verificado en vivo al cierre: engine sano, STIX 14 objetos, MCP con sus cuatro herramientas, telnet por
el motor sin markdown, laberinto por `Handler`, suite **1844 verde**, aislamiento por cliente 0 fugas,
recorte por rol 37/37. Aparecieron hallazgos nuevos que quedan anotados (el honeypot web se delata
sirviendo IIS en la portada y nginx en los errores; una clave de SSH que ya no hace falta; el prompt del
shell sale como bash en un router Cisco). Todo commiteado, sin subir a GitHub. Detalle en
[[roadmap-operativo]] y en `.agents/ROADMAP.md`, sección «ESTADO — Bloque A cerrado».
— claude

## [2026-08-30] bitacora | Fase C · Bloque A-bis — dónde vive cada decisión en la consola
Segundo tramo del día, sobre una observación de Iván: la contraseña del honeypot la habíamos puesto en
la pestaña de Infraestructura y no en la de Trampas, que es la que importa. Al mirarlo de cerca el
problema era más amplio: el único sitio donde se configura un honeypot mezclaba seis controles de
engaño (el disfraz, la contraseña, el prompt) con uno solo de infraestructura (el proveedor de IA), y
solo se llegaba a él desde Infraestructura. Además había decisiones tácticas sin ningún control: cuánto
aguanta la sesión, qué usuarios entran, el banner, la latencia y el laberinto anti-escáner.

Se **partió el modal en dos**. Ahora lo táctico —qué finge ser, a quién deja entrar, cuánto aguanta—
vive en un modal que se abre desde **Trampas**, con su propia sección de tarjetas; y el motor (el
proveedor de IA) se queda en **Infraestructura**. Se verificó con un navegador de verdad, no a ojo: la
página carga sin un solo error, el modal de Trampas no enseña el motor y el de Infraestructura no enseña
la contraseña, y guardar desde la interfaz llama al sitio correcto.

Los parámetros que faltaban se cubrieron. **Deadline y banner** salieron gratis porque Beelzebub ya los
soporta; el deadline sobrevive a cambiar de disfraz, el banner no —es parte del disfraz— y la consola lo
dice claro. **Los usuarios del login y la latencia no existían en Beelzebub**, así que hubo que
parchearlo en Go, por el mismo camino que ya usamos para la clave de host: se generó el parche sobre la
fuente, se comprobó que compila y que aplica en cadena con los otros dos, y se reconstruyó la imagen.
Lo delicado era el login —si el filtro de usuario está mal, nadie entra al honeypot y se pierden
capturas—, así que se probó con calma sobre la imagen ya parcheada: primero que el SSH siguiera
entrando como siempre, y solo entonces que «solo root y admin» dejara fuera a los demás sin tocar el
filtro de la contraseña. La latencia de segundo y medio se midió de verdad. Y el **laberinto**
anti-escáner ganó un interruptor por honeypot web: apagado da un 404 normal, encendido atrapa al
escáner.

Los cinco controles nuevos llevan el recorte por rol que cableamos por la mañana, así que un usuario de
solo lectura no puede tocarlos. Al cierre: suite en **1867 verde**, aislamiento entre clientes en cero
fugas, recorte por rol 37 de 37. Todo commiteado, sin subir. Detalle en [[roadmap-operativo]] y en
`.agents/ROADMAP.md`, sección «ESTADO — Bloque A-bis cerrado».
— claude
