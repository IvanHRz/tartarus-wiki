---
tipo: backlog
creado: 2026-07-09
actualizado: 2026-07-10
commit_ref: 6f584b7
---

# Backlog — Tartarus

Ideas de diseño con su razonamiento. Memoria de producto, no tablero de tareas.
Cada ítem responde: **qué**, **por qué ahora no**, **qué lo desbloquearía**.

## Tabla `sensor_bootstrap_log`

**Qué.** Tabla que registre cada inserción de bootstrap: sensor, política aplicada, timestamp, si el operador lo había borrado antes.

**Por qué ahora no.** [[0001-arquitectura-de-sensores]] la difiere explícitamente. La unificación en `SEED_SENSORS` con campo `bootstrap_policy` resuelve `BUG-043` sin schema extra. Añadirla ahora sería resolver un problema que aún no se manifiesta.

**Qué lo desbloquearía.** Que tras la migración aparezcan inconsistencias entre lo que el operador borró y lo que el bootstrap reinsertó. Síntoma: un sensor reaparece y nadie sabe por qué.

---

## Ghost IPs por variable de entorno

**Qué.** `sensors/icmp_canary/config.yml` tiene `192.168.10.247` / `.248` hardcoded. Deberían venir de env var.

**Por qué ahora no.** No es un bug hasta que el sensor corra en host networking. En bridge nunca recibe esos paquetes de todos modos.

**Qué lo desbloquearía.** El criterio 2 de validación RPi. En el momento en que icmp-canary escuche en la LAN real, la IP correcta depende del rango del cliente, no de un default.

---

## Versión de schema / flag `is_canonical`

**Qué.** `sensor_registry` no tiene versión de schema ni forma de distinguir un sensor canónico de uno registrado en runtime. La distinción vive en comentarios de código.

**Por qué ahora no.** `bootstrap_policy` cubre el caso actual.

**Qué lo desbloquearía.** Un tercer origen de sensores — p.ej. registro dinámico desde `sensor-only.yml` en campo. Con dos orígenes basta un campo; con tres hace falta un modelo.
