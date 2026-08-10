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

### 10 de agosto de 2026 (sesión de trabajo continuo) — Arreglo del cruce de cebos, avisos por cliente y más

- **Qué se logró.** Una tanda de mejoras trabajadas de corrido, cada una con sus pruebas:
  se corrigió que los cebos parecieran "cruzarse" entre clientes, cada cliente puede tener sus
  propios avisos, se reforzó la detección de intrusos y se endureció el guardado de contraseñas.
- **El problema del cruce de cebos (lo que se reportó).** Al cambiar de un cliente a otro, la
  pantalla seguía mostrando los cebos del cliente anterior si el nuevo no tenía ninguno. Parecía
  que un cebo "se filtraba", pero era un efecto de la pantalla: los datos por debajo estaban bien
  separados; lo que fallaba es que la vista no se limpiaba al quedar vacía. **Cómo se resolvió:**
  la pantalla ahora se limpia siempre al cambiar de cliente y muestra un aviso claro ("sin cebos
  en este cliente"); además, borrar o limpiar cebos quedó atado al cliente activo (antes "limpiar
  todo" podía borrar los de todos). **Impacto:** desaparece la confusión y ya no hay riesgo de
  borrar de más.
- **Un riesgo de datos corregido de paso.** La herramienta interna que audita la separación entre
  clientes borraba datos reales al ejecutarse. Se corrigió para que solo toque sus propios datos de
  prueba, y se dejó un pequeño generador de datos de demostración para poder probar sin partir de
  cero.
- **Avisos por cliente.** Hasta ahora la configuración de alertas era única para todos. Ahora cada
  cliente puede tener sus propios canales y umbral; el aviso de un cliente va solo a sus canales, y
  si no tiene configuración propia, usa la general. (Falta el selector en la pantalla de ajustes;
  por debajo ya funciona.)
- **Más detección.** Al revisar el catálogo de reglas se confirmó que la cobertura de técnicas de
  ataque ya estaba prácticamente completa. Se cerró un hueco concreto: ahora se detecta la creación
  de cuentas también en equipos Windows (antes solo en Linux).
- **Contraseñas más fuertes.** El guardado de contraseñas pasó a un método más robusto (bcrypt),
  migrando las existentes de forma transparente la próxima vez que cada usuario entre, sin que nadie
  note el cambio.

### 10 de agosto de 2026 (borrón y cuenta nueva + prueba real) — Limpieza total, ataque a todo y verificación de que nada se filtra

- **Qué se logró.** Se dejó la plataforma en cero y se hizo una prueba de fuego: atacar todos los
  servicios trampa por el camino real y comprobar, con datos medidos, que la información de un ataque
  cae donde debe y **no se cuela a otros clientes**.
- **Cómo se probó.** Se creó una herramienta que limpia todo, lanza el ataque y audita el resultado.
  Resultado: **136 registros de ataque en el cliente por defecto** (repartidos entre SSH, HTTP, MCP,
  TCP y Prometheus) y **cero en el cliente de prueba usado como testigo**. Es decir, la separación
  entre clientes también aguanta por el camino real, no solo en las pruebas de laboratorio.
- **Un problema real detectado y resuelto.** En el primer intento el ataque no dejó ningún registro:
  el puente entre el sensor de trampas y la base de datos se había "colgado". Se reinició el
  componente y se dejó la herramienta preparada para detectarlo y recuperarse sola. Queda anotado para
  reforzarlo de forma permanente.
- **Qué faltó cubrir (y ya está en la lista de pendientes).** Al medir, se vio que **el servicio de
  Telnet no registró nada** pese a atacarlo (hay que revisar por qué), que **la prueba de HTTPS no
  corresponde a un servicio real** (cobertura aparente), y que **Modbus (industrial) e ICMP** están
  puestos pero no se prueban. Todo esto quedó registrado para atender.
- **Mejoras de uso.** Al recargar la página estando dentro de un cliente, ya no te saca al panel
  general: te mantiene donde estabas. Y al entrar a un cliente ahora abre primero su pantalla
  principal (antes abría la de análisis). El panel general se limpió para que muestre solo lo que
  aporta (indicadores, tarjetas de clientes y el registro de alertas).
- **Orden y memoria.** A partir de ahora, cada plan de trabajo aprobado se guarda íntegro en esta wiki
  (en la bitácora del día) para poder revisarlo y mejorarlo con el tiempo.

## Estado actual (en lenguaje llano)

- Los cebos se crean, reparten y **avisan de verdad** cuando alguien los abre o los usa; y la
  pantalla ya no "arrastra" los de un cliente al siguiente.
- Cada cliente está **separado** de los demás: ni ve ni modifica lo ajeno, sus informes van
  etiquetados con su nombre, y puede tener **sus propios avisos**.
- El guardado de contraseñas es más robusto.
- Todo lo anterior está respaldado por pruebas automáticas (más de mil) que se ejecutan en cada
  cambio, más una auditoría específica de separación entre clientes que se corre en bucle y da
  cero fugas.

## Próximos pasos (con fecha estimada)

| Pendiente | Por qué importa | Prioridad | Fecha objetivo |
|-----------|-----------------|-----------|----------------|
| Activar el inicio de sesión y los roles en el primer despliegue con clientes reales | Hoy la separación funciona porque el operador elige el cliente; con clientes reales debe ser una barrera obligatoria, no una elección | Alta | septiembre 2026 |
| Pantalla de administración de clientes (crear, renombrar, entrar, salud de cada uno) y selector de cliente en los ajustes de avisos | Cerrar la parte visual de lo que ya funciona por debajo | Media | siguiente iteración |
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
