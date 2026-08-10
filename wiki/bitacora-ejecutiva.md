---
tipo: estado
creado: 2026-08-10
actualizado: 2026-08-10
commit_ref: 17d167c (+ correcciones de seguridad 10-ago sin commitear al escribir)
tags: [ejecutivo, seguridad, flocks, cebos]
---

# Bitácora ejecutiva — TARTARUS

> Para dirección y asesoría. Cuenta el avance **por fechas**, en lenguaje llano: qué se
> logró, qué problema apareció, cómo se resolvió y qué sigue. Complementa
> [[estado-y-rumbo]] (foto del estado actual) y [[roadmap]] (el plan por fases).

## Qué es TARTARUS, en dos frases

TARTARUS es una plataforma de engaño para detección temprana de intrusos: coloca
"cebos" y servicios trampa que un atacante no puede distinguir de los reales, y avisa en
el momento en que alguien los toca. Está pensada para dar servicio a varios clientes a la
vez, manteniendo los datos de cada uno separados de los demás.

## Avance por fechas

### 7 y 8 de agosto de 2026 — Que los cebos funcionen de verdad y sean fáciles de usar

- **Qué se logró.** Se rehízo la "Consola de Canarios", el panel desde el que se crean y
  reparten los cebos (documentos, credenciales y enlaces trampa). Ahora crear un cebo y
  desplegarlo son pasos distintos y claros, cada cebo genera un archivo real listo para
  entregar al cliente, y la consola explica con honestidad qué dispara la alarma y cuándo.
- **Qué problema apareció.** En las pruebas, algunas alertas "no llegaban". Al revisarlo no
  era una falla del cebo: (a) el sistema agrupaba avisos de una misma dirección para no
  saturar, y en pruebas locales eso tapaba avisos legítimos; y (b) el correo con el cebo
  caía en la carpeta de no deseados del cliente.
- **Cómo se resolvió.** El freno de avisos repetidos pasó a contarse por cebo (no por
  dirección), de modo que cada trampa abierta genera su propio aviso. Se documentó, además,
  con claridad qué tipos de cebo disparan siempre y cuáles dependen del programa con que se
  abran.
- **Impacto para el cliente.** Repartir cebos y confiar en que las alertas llegan dejó de
  ser un problema técnico y pasó a ser una tarea de pocos minutos.

### 9 de agosto de 2026 — Separación por cliente (estilo panel central) y primera auditoría

- **Qué se logró.** Se ordenó la plataforma en dos niveles: un **panel central** de
  administración (la lista de clientes y el resumen general) y, dentro de cada cliente, su
  propio espacio de trabajo con sus cebos, sensores y alertas. Cada cliente vive en su
  compartimento, llamado internamente "flock".
- **Qué problema apareció.** Al cambiar de un cliente a otro, la pantalla llegaba a mostrar
  por un instante datos del cliente anterior. Y, más de fondo, algunos informes y descargas
  no estaban filtrando por cliente.
- **Cómo se resolvió.** Se corrigió la pantalla para que limpie lo anterior al cambiar de
  cliente, y se revisó **todo** con una prueba automática que siembra dos clientes con datos
  distintos y comprueba, una y otra vez, que ninguno vea nada del otro. Se cerraron las fugas
  en informes y descargas (incluidos los formatos para intercambio con otros sistemas).
- **Impacto para el cliente.** La información de un cliente no se mezcla ni se muestra a otro:
  requisito básico para ofrecer el servicio a varias empresas a la vez.

### 10 de agosto de 2026 — Segunda pasada de seguridad: que nadie modifique lo ajeno

- **Qué se logró.** Se cerró la segunda parte de la seguridad entre clientes. Antes se había
  garantizado que un cliente no *viera* lo de otro; ahora se garantiza que tampoco pueda
  *modificarlo*.
- **Qué problema apareció.** Las acciones de borrar o editar un cebo, o silenciar una
  dirección, se hacían por identificador sin comprobar a qué cliente pertenecían. En
  particular, la acción de "limpiar todos los cebos" borraba los de todos los clientes, no
  solo los del cliente activo.
- **Cómo se resolvió.** Todas esas acciones quedaron acotadas al cliente que las pide: si algo
  no es suyo, el sistema responde que no existe (para él) y no lo toca. "Limpiar todo" ahora
  solo afecta al cliente activo. Además, cada informe estampa en su encabezado el nombre del
  cliente al que pertenece, para que no se confunda ni se comparta el de uno como si fuera de
  otro. Se volvió a pasar la auditoría completa: **cero fugas**, tanto al leer como al
  modificar.
- **Impacto para el cliente.** El compartimento de cada cliente es hermético en los dos
  sentidos: nadie ve ni cambia lo que no es suyo.

## Estado actual (en lenguaje llano)

- Los cebos se crean, reparten y **avisan de verdad** cuando alguien los abre o los usa.
- Cada cliente está **separado** de los demás: ni ve ni modifica lo ajeno, y sus informes van
  etiquetados con su nombre.
- Todo lo anterior está respaldado por pruebas automáticas (cerca de mil) que se ejecutan en
  cada cambio, más una auditoría específica de separación entre clientes que se corre en bucle.

## Próximos pasos (con fecha estimada)

| Pendiente | Por qué importa | Prioridad | Fecha objetivo |
|-----------|-----------------|-----------|----------------|
| Activar el inicio de sesión y los roles en el primer despliegue con clientes reales | Hoy la separación funciona porque el operador elige el cliente; con clientes reales debe ser una barrera obligatoria, no una elección | Alta | septiembre 2026 |
| Notificaciones por cliente | Que cada cliente reciba solo sus avisos, por su propio canal | Media | septiembre 2026 |
| Reforzar el guardado de contraseñas | Endurecimiento de seguridad (hoy no es una fuga) | Media | septiembre 2026 |
| Panel de proveedor para gestionar varias instalaciones | Para cuando se venda el servicio: ver todos los despliegues de cada cliente y darles soporte | Media | por planificar (tras la venta) |

## Riesgos y pendientes de seguridad conocidos (sin alarmismo)

- **El inicio de sesión viene apagado por defecto.** Es lo correcto para un laboratorio de una
  sola persona, pero **antes de dar servicio a un cliente real hay que encenderlo** (junto con
  un secreto propio y el cambio de la contraseña de fábrica). El procedimiento está escrito en
  la guía interna de seguridad multi-cliente.
- **Las notificaciones todavía se configuran de forma única y global.** Funciona, pero conviene
  separarlas por cliente antes de operar con varios a la vez (ya está agendado).
- **Reparto de carga entre clientes.** El freno de avisos y el silenciado ya son por cliente;
  falta poner límites de recursos para que un cliente muy ruidoso no afecte a otro.
