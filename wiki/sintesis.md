---
tipo: sintesis
creado: 2026-07-09
actualizado: 2026-07-30
commit_ref: 0085c31
---

# Tartarus — estado actual

> [!info] Fuentes ingeridas
> ADR-001 (sensores) + bitácora `6f584b7`..`0085c31` (24 commits, v0.5.0→v0.6.2) +
> memoria del agente. Pendiente: destilar `.raw/vault-legacy/` (23 notas de marzo).

## Dónde está el proyecto

Tartarus acaba de dar su **salto a MSSP**: en una sola integración (#8, mergeada a
`main` el 2026-07-30) entró la multi-tenancy completa. La plataforma pasó de mono-tenant
a servir varios clientes aislados desde una consola de dos niveles. Es el trabajo más
grande del periodo y está **hecho y verificado E2E**, no en curso.

Lo entregado, cada uno con su ADR:

- **Flocks** — aislamiento por `flock_id` (`NULL=Default`). [[0002-multi-tenancy-flocks]]
- **RBAC** — 3 roles, fail-closed. [[0003-rbac-tres-roles]]
- **Acknowledge** — limpieza de ruido, ocultar-no-borrar. [[0004-acknowledge-limpieza-de-ruido]]
- **Attack Map** — interno/externo, MITRE, host:puerto. [[0005-attack-map-contexto-de-despliegue]]
- **Consola de dos niveles** — madre vs workspace. [[0006-consola-dos-niveles]]

En paralelo se preparó el despliegue: se fijó Beelzebub a `v3.8.0` (`965c65c`, antes
era `:latest` no reproducible) y se sumó un colaborador (`loaaan`) para el despliegue.

## La tensión central

**El chasis es sólido; falta demostrar que el motor enciende de forma fiable.**

La arquitectura multi-tenant es coherente, limpia y bien probada *estructuralmente*.
Pero los 835 tests son unit con pool mockeado: el aislamiento entre flocks —lo recién
construido— **nunca se prueba contra una DB real**. Y la eficacia de detección descansa
sobre un catálogo inflado: de 424 reglas Sigma, solo 89 son honeypot-nativas; un ataque
real dispara ~38 (43% de las aplicables). El número "424 cargadas" no resiste una
pregunta técnica.

## Riesgo abierto — crítico

> [!danger] La ingesta se cae en silencio (issue `#10`)
> El canal AMQP de Beelzebub muere por inactividad: los honeypots **capturan** ataques
> pero dejan de reportar, y el dashboard muestra 0 —indistinguible de "no me atacan".
> Confirmado en dos sesiones. `docker restart tartarus-beelzebub` lo revive.
> **Es la condición de "desplegable": sin healthcheck de ingesta, un cliente podría
> quedar ciego sin saberlo.** Actualizar Beelzebub NO lo arregla (sin cambios AMQP upstream).

Segundo hilo, congelado: el cluster de sensores ([[0001-arquitectura-de-sensores]])
sigue `PROPOSED` sin validar en RPi 5. Ver [[roadmap]].

## Preguntas sin responder

1. ¿Cuándo se hace el healthcheck de ingesta (#10)? Es lo primero antes de desplegar.
2. `events.honeypot_id` siempre NULL (`#11`): ¿se estampa una clave estable de sensor,
   cerrando el mapeo real, o se vive con el fallback por protocolo?
3. El aislamiento entre flocks: ¿un test de integración con Postgres real, o se confía?
