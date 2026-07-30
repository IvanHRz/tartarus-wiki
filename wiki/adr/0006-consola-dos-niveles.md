---
tipo: adr
estado: aceptada
creado: 2026-07-30
actualizado: 2026-07-30
commit_ref: 0085c31
tags: [ui, dos-niveles, flocks, ux]
---

# ADR-0006 — Consola de dos niveles: madre vs workspace de flock

## Contexto

Con multi-tenancy ([[0002-multi-tenancy-flocks]]) y las vistas ya consistentes
([[0004-acknowledge-limpieza-de-ruido]]), quedaba la pregunta de arquitectura de
información: **¿qué muestra la interfaz "madre" (global) vs la vista de cada flock?**
El dashboard era un scroll único que mezclaba lo global con lo per-flock — el usuario
lo describió como "muy atascado en info".

La decisión la tomó el usuario explícitamente (AskUserQuestion) entre dos modelos.

Implementado en `4b707ed` (Fase 3 + 4c UI).

## Decisión

**Consola de dos niveles gobernada por el selector de cabecera.**

- `🌐 Todos los flocks` (value `''`) = **madre**: agrega todos los flocks + tarjetas de
  flock + attack map global.
- Elegir un flock (selector o clic en su tarjeta) = **workspace**: `_flockParam()` /
  `_flockQ()` scopea *todas* las cargas a ese flock, y las secciones cross-flock/admin
  (Flocks, Usuarios, Audit, Notificaciones, catálogos) se ocultan con `.flock-hidden`
  tras un banner de contexto ("← Todos los flocks · Workspace · <nombre>").
- `refreshFlockViews()` + `applyViewLevel()` + `_selectFlock()` centralizan el cambio.
- **Default Flock = el bucket global.** Como sus eventos son `flock_id NULL` (herencia
  de [[0002-multi-tenancy-flocks]]), no tiene workspace propio: su tarjeta/opción abren
  la vista global en vez de un workspace vacío.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| **Un dashboard, filtro consistente** (la otra opción ofrecida) | El usuario quería **separación estructural** madre/flock, no el mismo scroll filtrado. Rechazada por decisión de producto, no técnica. |
| **Reestructura a páginas/rutas separadas** | Mayor riesgo y coste; el enfoque show/hide reutiliza el dashboard existente (Canvas puro, sin router) y llega antes. Diferido si la separación show/hide se queda corta. |

## Consecuencias

- **Prerrequisito duro: consistencia de ventana.** Sin que todas las superficies fueran
  `hours+flock+ack` primero (`665cd09`), el workspace de un flock habría mostrado datos
  globales en las secciones no-scopeadas. La ADR 0004 tuvo que ir antes.
- El Default no tiene workspace aislado (límite heredado de `NULL=Default`). Aceptado:
  el Default *es* el catch-all global en el modelo MSSP.
- El reparto de secciones madre-only vs flock es un juicio (`_MADRE_ONLY_SECTIONS` en
  `main.js`); puede necesitar iteración según cómo se use.
- Ganancia verificada E2E: la madre agrega N flocks; entrar a uno filtra stats, strip,
  timeline, kill-chain, detecciones, sesiones, tokens y sensores a ese flock; "← Todos"
  vuelve. Sin errores de consola.

## Estado real — verificado contra `0085c31` (2026-07-30)

Implementado, mergeado (#8). Verificado con dos flocks poblados: madre agrega (5
eventos), workspace de "Iván" filtra a 3. `main.js` v28.

## Enlaces

- [[0002-multi-tenancy-flocks]] — de dónde sale `NULL=Default`
- [[0004-acknowledge-limpieza-de-ruido]] — la consistencia que lo habilita
- [[sintesis]]
