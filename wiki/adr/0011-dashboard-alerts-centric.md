---
tipo: adr
estado: aceptada
creado: 2026-08-07
actualizado: 2026-08-07
commit_ref: ae28dd7
tags: [ui, dashboard, ux, alerts-centric, thinkst, E-F]
---

# ADR-0011 — Dashboard alerts-centric (reducir ruido visual)

> Referencia: la consola Thinkst Canary muestra ~7 elementos centrados en alertas y esconde el resto
> tras el engrane. Nuestro dashboard tenía **27 secciones, ~24 visibles al cargar, 3 mapas
> simultáneos** y una ráfaga de ~18-21 fetch por ciclo — demasiado ruido, poco foco para el analista.

## Contexto

El analista necesita, de un vistazo: *¿qué pasa ahora, quién ataca, qué tocó?* Todo lo demás
(configuración, inventario de cebos, análisis profundo) es secundario y estorba en la vista de triage.
El usuario pidió ser **estricto** con esto.

## Decisión

**Consola con navegación por vistas.** La vista **Principal** es el loop de triage; el resto vive en
pestañas. Se eligió la variante **Balanceada** (deja contexto útil en Principal). La variante
**Mínima** queda documentada como alternativa lista para adoptar si se quiere más pureza.

### Variante ADOPTADA — Balanceada
- **Principal:** tira de riesgo (`#attackSummary`) + `#stats` · **Live Events como lista de alertas
  héroe** (Ack + filtro All/Unack/Ack) · **Session Correlation** (atacante→qué tocó) · salud de
  sensores compacta · **UN** mapa (Attack Map).
- **Pestaña Análisis:** kill-chain, threat-intel, credenciales, VRA, cross-correlación, timeline.
- **Pestaña ⚙ Gestión:** flocks, users, audit, notify, detections, personalities, breadcrumbs,
  scanner+hosts, tokens/honey-creds/sensores (gestión completa), DRAS, mapas Infra/Geo.

### Variante ALTERNATIVA — Mínima (Thinkst puro), lista para adoptar
- **Principal:** solo tira de riesgo + lista de alertas (héroe) + salud de sensores compacta + 1 mapa.
- **Todo lo demás** (incl. Session Correlation y análisis) tras pestañas/engrane.
- Para adoptarla: mover `#sessionSection` y `#stats` fuera de Principal; el resto del andamiaje de
  vistas es el mismo. Se marcaría este ADR `reemplazada-por-00NN`.

## Alternativas descartadas

| Opción | Por qué no (por ahora) |
|---|---|
| **Conservador** (colapsar en acordeones, no mover) | Menos disruptivo pero sigue mostrando todo; no cumple "solo lo necesario". |
| **Mínima** ya | Válida y documentada arriba; el usuario prefirió empezar Balanceado y evaluar. |

## Consecuencias

- Andamiaje: cada `<section>` lleva `data-view` (principal/analisis/gestion); un `setView()` togglea
  `.view-off` (mismo patrón que el two-level `.flock-hidden`). No rompe madre/flock.
- **`graph.js` se borra** (huérfano desde el retiro del Neural Graph — ver [[0010-websocket-real-time]]).
- **3 mapas → 1 en Principal** (Infra y Geo pasan a Gestión); no se borran.
- Se puede gatear el `_masterPoll` para refrescar solo la vista activa → baja la ráfaga de fetch.
- Canvas puro (C3) intacto.

## Enlaces
- [[0006-consola-dos-niveles]] (madre/flock, ortogonal a las vistas) · [[0010-websocket-real-time]]
  (por qué `graph.js` es dead-code) · [[roadmap]] (Tier E, bloque E-F).
