
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
