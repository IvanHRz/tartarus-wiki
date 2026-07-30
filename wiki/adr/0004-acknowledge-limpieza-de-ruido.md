---
tipo: adr
estado: aceptada
creado: 2026-07-30
actualizado: 2026-07-30
commit_ref: 0085c31
tags: [acknowledge, ux, alertas, thinkst, consistencia]
---

# ADR-0004 — Acknowledge: limpieza de ruido

## Contexto

Filosofía Thinkst, adoptada como principio de producto: **nada legítimo toca un
honeypot → todo lo que lo toca es una alerta**. La consecuencia operativa es que la
pantalla se llena y nunca se limpia. Thinkst deja **revisar y reconocer** una alerta
para sacarla de la vista (a segundo plano), dejando la consola limpia.

El problema secundario, descubierto al mirar la plataforma real: mezclaba dos
regímenes de ventana. Las cards de 24h leían 0 mientras las tiras all-time seguían
mostrando el histórico (741 CRIT). "Atascado en info".

Implementado en `457cd0e` (acknowledge) y `665cd09` (consistencia de ventana).

## Decisión

**Ocultar, no borrar. Un flag booleano en `events`, filtrado por defecto en las
vistas de pantalla; los reportes ven el 100%.**

- `events.acknowledged` (+ `acknowledged_at`, `acknowledged_by`) + índice parcial
  `WHERE acknowledged = FALSE`. Copia el patrón de `kill_chain_traces.resolved`.
- Predicado puro `ack_condition()` (`session_correlator.py`) — constante, sin bind
  param, se compone en cualquier WHERE sin desplazar índices.
- Granularidad **por IP / por flock / global** (los eventos son de alto volumen y las
  vistas agrupan por `source_ip`; reconocer fila-a-fila no encaja).
- Reportes/export (`export_router`, `report_router`, …) **nunca** pasan el filtro: el
  registro forense siempre ve todo.
- Consistencia: `_windowed_where()` unifica `tiempo 24h + flock + acknowledge` en un
  helper. El lever fue `attack_summary()` — sin `hours`/`flock`, alimentaba 4
  superficies a la vez (strip, Kill Chain, Threat Intel, badges Infra); arreglarlo las
  limpió de golpe.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| **Borrar los eventos reconocidos** | Destruye el registro forense — la razón de ser de una plataforma de IR. Acknowledge debe ser reversible y auditable. |
| **Watermark por IP en Redis** (`ack:{ip}=ts`) | Frágil en los muchos `GROUP BY` de las vistas; obliga a excluir en cada query con lógica temporal. La columna en DB es consistente con `resolved` y se indexa. |
| **Acknowledge por fila** | Los eventos son de altísimo volumen y las superficies agrupan por `source_ip`. La unidad natural es la IP (o el flock). |

## Consecuencias

- **"Ignorar IP" quedó como no-op server-side.** Existe la lista en Redis y el botón,
  pero `is_ignored` no se consulta en ninguna query ni en el notifier — es solo visual.
  Ignore=futuro, Acknowledge=pasado; son complementarios pero el primero está a medias.
- **"Recent Alerts" es una capa Redis aparte** (`notifications:history`), no deriva de
  `events`. El barrido global (`acknowledge/all`) también la vacía; si no, quedaría
  "atascada" respecto a todo lo demás.
- Tras unificar el ventaneo, arrancar sesión = todo en 0 en 24h; lanzar 5 ataques →
  aparecen consistentes en todas las superficies; "✓ Limpiar" las oculta todas.

## Estado real — verificado contra `0085c31` (2026-07-30)

Implementado, mergeado (#8), 835 tests (incl. `test_acknowledge.py`,
`test_consistency_window.py`). `ack_condition`/`_windowed_where` inyectados en feed,
stats, attack-summary, kill-chain, threat-intel, attack-map, geo, sesiones, VRA,
credenciales, histograma. Endpoints en `alert_ux_router`: `/acknowledge/{ip}`,
`/acknowledge/all` (scope por flock), `DELETE` (deshacer), `/acknowledge/count`.

Verificado con datos reales: reconocer una IP la saca del feed (789 de 929) pero el
export forense la sigue viendo (88 filas).

## Enlaces

- [[0006-consola-dos-niveles]] — la consistencia de ventana es su prerrequisito
- [[backlog]] — hacer efectivo "Ignorar IP"
