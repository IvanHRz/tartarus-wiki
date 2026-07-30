---
tipo: sintesis
creado: 2026-07-09
actualizado: 2026-07-10
commit_ref: 6f584b7
---

# Tartarus — estado actual

> [!warning] 1 fuente ingerida
> Solo se procesó `Docs/adr/ADR-001`. El historial de git, el CHANGELOG y el resto de `Docs/` siguen sin ingerir. Lo que sigue es parcial.

## Dónde está el proyecto

Un cluster de cuatro bugs arquitectónicos sobre el ciclo de vida del sensor está **decidido pero congelado**. [[0001-arquitectura-de-sensores]] eligió la Opción A y acto seguido se prohibió a sí misma ejecutarla hasta pasar 6 criterios de validación en hardware RPi 5 16GB.

Dos meses después (`6f584b7`, 2026-07-10) no hay evidencia de esa validación, y ninguno de los ocho cambios prescritos existe en el código. El desarrollo siguió por otro lado: visualización, deception, tokens por perfil.

## La tensión central

El stack vive en un bridge de Docker. El bridge da DNS interno gratis (`postgres`, `redis`, `broker` resuelven solos) y a cambio ciega a los dos sensores que necesitan ver la red real: el scanner ve la subred de docker en vez de la LAN, y el icmp-canary nunca recibe un paquete dirigido a sus ghost IPs.

Salir del bridge arregla los sensores y rompe el DNS. La ADR resuelve el nudo sacando **solo** el scanner del compose y dejando el resto adentro. Es la decisión correcta y también la más cara de implementar.

## Riesgo abierto

`docs/generate_report.py:553` lee `remote_sensors`, la tabla que la ADR manda borrar. El audit de §2 no lo detectó. El ticket de Sprint 6+ está subestimado hasta que se corrija esa lista.

## Preguntas sin responder

1. ¿Por qué se paró la validación en RPi? ¿Falta de hardware, o se despriorizó?
2. Si el cluster lleva dos meses congelado, ¿sigue siendo la Opción A la correcta, o el trabajo de visualización/deception cambió los supuestos?
3. ¿Cuántas ADRs más hay implícitas en `Fixes/` y `Docs/audits/` que nunca se escribieron?
