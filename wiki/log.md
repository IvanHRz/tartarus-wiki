
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
