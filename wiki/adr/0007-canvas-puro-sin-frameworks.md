---
tipo: adr
estado: aceptada
creado: 2026-03-10
actualizado: 2026-07-30
commit_ref: 0085c31
adr_original: raw/vault-legacy/Knowledge Base/Decisions/ADR-001 Canvas Only UI.md
tags: [ui, canvas, frontend, c3]
---

# ADR-0007 — Canvas puro, sin frameworks

> Destilada del vault legacy (marzo 2026, v0.5.0). La decisión sigue vigente; una
> de sus consecuencias envejeció mal.

## Contexto

El dashboard necesita visualización en tiempo real (eventos, topología, riesgo,
attack map). Se evaluaron React, D3.js, Cytoscape y Canvas puro.

## Decisión

**HTML5 Canvas + JavaScript vanilla. Sin frameworks.** Es la restricción **C3** del
`CLAUDE.md`: prohibidos D3, vis.js, Cytoscape, React, Vue. Control directo de píxeles,
bundle mínimo, sin build step, nginx sirve estáticos.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| React / Vue | Build step, dependencias, peso; innecesario para una consola de ops de una sola página. |
| D3 / Cytoscape | Librerías de grafo pesadas; el attack map se dibuja a mano con más control y cero riesgo de dependencia. |

## Consecuencias

- Todo se renderiza a mano (tablas, charts, badges, el attack map de `attackmap.js`).
  Más esfuerzo, cero riesgo de dependencia, rendimiento excelente en streaming.
- **La consecuencia que envejeció:** la ADR original decía *"main.js es el único archivo
  JS (~519 líneas)"*. Contra `0085c31`, `ui/src/js/main.js` tiene **3.307 líneas**. El
  "archivo único" se volvió un monolito. Cumple C3, pero cada feature nueva lo hace más
  frágil — es deuda real, no cosmética. Ya hay `attackmap.js`, `timeline.js`, `geomap.js`
  extraídos; `main.js` sigue siendo el god-file.

## Estado real — verificado contra `0085c31` (2026-07-30)

C3 se respeta: `grep -r "react\|d3\|cytoscape\|vue"` en `ui/` = 0 (salvo Chart.js para
los charts del timeline, dependencia acotada vía CDN). El monolito `main.js` es el
pendiente de refactor.

## Enlaces

- [[0005-attack-map-contexto-de-despliegue]] — render Canvas del mapa
- [[backlog]] — trocear `main.js`
