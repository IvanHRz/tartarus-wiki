---
tipo: adr
estado: aceptada
creado: 2026-09-20
actualizado: 2026-09-20
commit_ref: f854217
tags: [auth, m2m, hmac, shims, honeypot, despliegue, E-D1]
---

# ADR-0013 — Modo aviso antes de exigir, en toda puerta de máquina

> Ninguna credencial de máquina se empieza a exigir sin haber contado antes, **con evidencia que
> sobreviva a un reinicio**, a quién se dejaría fuera.

## Contexto

Tartarus tiene dos entradas de máquina a máquina, y las dos han tenido el mismo problema:

* **La ingesta de sensores** — `/ingest/sensor` y los webhooks de canario. Acepta peticiones sin
  firma HMAC mientras `TARTARUS_HMAC_ENFORCE` esté apagado.
* **Los tres shims de honeypot** — `/v1/{chat,web,mcp}/completions`, que es por donde Beelzebub le
  pide a Tartarus que resuelva un comando del atacante.

El 13-sep-2026 se encendió la sesión de la consola y se exentaron las rutas de máquina del
middleware… escribiendo la lista a mano. **Se olvidaron los tres shims.** El parche de Go recibía
un 401, lo leía como `no choices`, y el honeypot SSH contestaba `command not found` a **todo**.
Nueve de los diez honeypots estuvieron sin cerebro **tres días** — sin un error en ninguna
pantalla, sin una alerta, sin que nadie lo notara.

La lección no es «acuérdate de los shims». Es que **cerrar una puerta de máquina es un cambio
destructivo cuyo síntoma es el silencio**: el que se queda fuera no protesta, deja de funcionar.

Y la pregunta previa —«¿a quién estoy a punto de tirar?»— no se podía contestar. El contador de
peticiones sin credencial vivía en un diccionario del proceso, y el comentario que lo acompañaba
en `/metrics/tartarus` decía con todas las letras «si esto está a cero, nadie se rompe». Falso:
cero significaba **«nadie desde el último reinicio»**, y el motor se reinicia varias veces al día.

## Decisión

**Toda puerta de máquina pasa por tres escalones, y no se salta ninguno.**

1. **Abierta y ciega** — el estado del que se parte. No se toca todavía.
2. **Modo aviso** — se lee la credencial, se **acepta igual**, y se **cuenta** quién llega sin
   ella: por ruta y por remitente, con `primero` y `ultimo`. La evidencia se **persiste** en la
   tabla `ingesta_sin_firma` y la métrica publica **desde cuándo** vale el cero. Una firma
   **equivocada** sí se rechaza desde el primer día: quien se molesta en firmar, o firma bien o
   está suplantando.
3. **Exigida** — sólo cuando la ventana diga cero durante un plazo declarado **y** la
   precondición de campo esté hecha (el secreto en el equipo, el token en su configuración).

El contador es **uno solo** (`engine/engine/security/sin_credencial.py`), compartido por las dos
puertas: una tabla, un mecanismo. Dos copias de una verdad siempre divergen.

Y el paso de 2 a 3 es **una decisión de persona, no de código**: la entrada del plan queda en
estado **👁 EN MONITOREO**, obligada a declarar qué se mira, con qué comando, cada cuánto y con qué
criterio. Lo vigila una prueba.

## Alternativas descartadas (y por qué)

* **Exigir y ver qué se rompe.** Es lo que pasó el 13-sep sin querer. El coste no fue el fallo:
  fue que **nadie lo vio en tres días**, porque un honeypot sin cerebro sigue aceptando conexiones
  y contestando — mal.
* **Contar sólo en el registro.** Existía: un aviso por remitente **y hora**, que además se pierde
  al reiniciar. No sirve para decidir; si vas a apoyar una decisión en algo, que sea un contador.
* **Contar en memoria y ya.** Es lo que había. Un cero de un proceso que se reinicia varias veces
  al día no es evidencia de nada.
* **Contar en Redis.** Es estado de «ahora mismo», con TTL y sin garantía de durar. Esto es un
  **rastro de auditoría**: va a una tabla.
* **Un contador por puerta.** Dos mecanismos iguales divergen en cuanto uno se toque.

## Consecuencias

**Buenas.** La decisión de cerrar deja de ser una apuesta: hay número, remitente y ventana. El
escalón intermedio cierra ya la mitad que se puede cerrar sin romper nada —una firma falsificada
se rechaza desde el primer día— y deja por escrito a quién falta. Y el mismo mecanismo sirvió sin
cambios para la segunda puerta, que es la prueba de que la abstracción era real.

**Malas, y conviene decirlas.**
* **Se tarda más.** Entre «ya funciona» y «ya está cerrado» pasan días de ventana. Es deliberado.
* **La puerta sigue abierta mientras tanto.** El radio es corto —el motor escucha en `localhost`
  y en la red de Docker— pero el día que alguien exponga el motor, cualquiera puede gastar saldo
  del proveedor por los shims. Está asumido y anotado, no olvidado.
* **El último escalón depende de otro.** Las dos precondiciones que faltan son de la sesión de
  campo (el secreto en el systemd de la Pi, un token en los YAML de Beelzebub). Una decisión que
  depende de otro equipo se queda esperando si nadie la empuja: por eso el estado EN MONITOREO
  obliga a declarar el criterio, para que el que lo lea sepa qué falta sin preguntar.
* **Dos métricas que hay que leer juntas.** `sin_firmar_total` sin `sin_firmar_desde` vuelve a
  ser el cero que no significa nada. Están documentadas juntas, y el `HELP` lo dice.

## Cómo se comprueba

```bash
curl -s localhost:9001/metrics/tartarus | grep -E "sin_firmar_desde |sin_firmar_total\{|shim_sin_credencial_total\{"
```

Guardarraíles: `engine/tests/test_firma_durable.py` (el contador sobrevive a un reinicio y el
vuelco **suma**), `test_shims_sin_credencial.py` (los tres cuentan, ninguno rechaza todavía, y el
token no acaba en ningún registro) y `test_todos_firman.py` (todo remitente de `sensors/` que
postee a una ruta protegida firma — la lista sale de quién depende del verificador, no de una
copia a mano).
