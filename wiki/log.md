
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
