---
tipo: adr
estado: aceptada
creado: 2026-03-12
actualizado: 2026-07-30
commit_ref: 0085c31
adr_original: .raw/vault-legacy/Knowledge Base/Decisions/ADR-004 WebSocket Real-Time.md
tags: [websocket, real-time, ws_manager, obsolescencia]
---

# ADR-0010 — WebSocket sobre polling para eventos en tiempo real

> Destilada del vault legacy (marzo 2026, v0.5.0). **La decisión sigue en pie a nivel de
> infraestructura, pero su justificación desapareció** — un caso claro de decisión que el
> código dejó a medias en el aire.

## Contexto

Hasta la Fase 3, la UI hacía polling REST cada 5 s (`setInterval(loadEvents, 5000)`):
hasta 5 s de latencia, queries constantes en idle, y —el motor real de la decisión— el
**Neural Graph necesitaba push** para animar en tiempo real.

## Decisión

Endpoint **FastAPI WebSocket `/ws/events`** con un registry de conexiones desacoplado
(`engine/engine/ws_manager.py`). El consumer hace `broadcast_event()` tras cada INSERT.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| Server-Sent Events | Config especial en nginx; sin ping/pong keepalive nativo. |
| WebSocket + Redis Pub/Sub | Escala horizontal que no se necesita en instancia única; dependencia extra. |
| Long polling | Latencia similar al polling; no es real-time. |

## Consecuencias

> [!warning] La razón de ser de esta decisión ya no existe
> El Neural Graph (`ui/src/js/graph.js`) —para el que se construyó el push— está
> **RETIRADO**. `ui/src/index.html:227` y `main.js:2` lo declaran dead-code: *"Attack Map
> is the single flow view"*. Y el Attack Map (`attackmap.js`) **no usa WebSocket**: se
> refresca por `_registerMasterPoll` (polling), igual que el feed y el resto del dashboard.
>
> Resultado: el endpoint `/ws/events` + `ws_manager` **siguen vivos** (`main.py:286`) pero
> **huérfanos** — infraestructura sin consumidor en la UI. La plataforma, en la práctica,
> **volvió al polling** (el "master poll" que reemplazó 9 `setInterval`), justo lo que esta
> ADR quería evitar.

- Trampa registrada que sigue siendo válida: `_clients -= dead` provoca `UnboundLocalError`
  → usar `difference_update()`. Vive en `ws_manager.py`.

## Estado real — verificado contra `0085c31` (2026-07-30)

- `/ws/events` y `ws_manager` existen y son funcionales (`main.py:286`, import en `:46`).
- **Ningún JS vivo consume el WS** (`graph.js` retirado; `attackmap.js`/feed usan master-poll).
- La decisión no fue revertida por otra ADR — se quedó sin uso al retirar el Neural Graph.
  **Candidato de `lint`:** o se le da uso (feed en vivo real) o se documenta como infra
  latente y se decide si mantenerla.

## Enlaces

- [[0005-attack-map-contexto-de-despliegue]] — el Attack Map que reemplazó al Neural Graph
- [[backlog]] — decidir el futuro del WS huérfano
