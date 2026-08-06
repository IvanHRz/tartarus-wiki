---
tipo: modulo
creado: 2026-08-06
actualizado: 2026-08-06
commit_ref: 0085c31
tags: [riesgo, scoring, mitre, detection]
---

# Módulo: Risk Engine

> Verificado contra `0085c31` el 2026-08-06. Si el HEAD actual difiere mucho, esta página miente.
> Comprobar: `bash tools/stale_modules.sh`

## Responsabilidad

Asignar a cada evento una severidad 0–100 + su `mitre_tactic`/`mitre_technique`, de forma
determinista y explicable. `engine/engine/risk_engine.py`. God-node `calculate_risk()`
(67 edges — el más conectado del sistema después de `get()`).

## Entradas / salidas

- **In:** el `event` dict parseado (protocolo, comando, payload, headers, dest_port).
- **Out:** `(risk_score, mitre_tactic, mitre_technique, risk_factors)` — `risk_factors` es la
  lista de qué sumó cuánto (la explicabilidad). `calculate_risk()` en `risk_engine.py:79`.

## Invariantes

- **Score acotado a [0, 100]:** `min(max(score, 0), 100)` (`risk_engine.py:413`). Nunca
  desborda por más modificadores que apliquen.
- Aditivo puro: base por protocolo + modificadores por patrón. Sin ML, sin estado. Ver
  [[0009-risk-scoring-aditivo]].

## Trampas conocidas

> [!warning] El umbral 70 es la línea "alerta" de TODO el sistema
> `should_alert` (notifier), `high_risk` (flocks), el badge del dashboard — todos usan
> `>= 70`. Cambiar el scoring mueve esas cuatro superficies a la vez. Acoplamiento implícito.

> [!info] Las constantes viven en el código, no en la wiki
> Base por protocolo y modificadores están en `risk_engine.py`. **No** se copian aquí: se
> desincronizarían. La ADR 0009 da el modelo; el código da los números.

## Grafo

God-node: `calculate_risk()` (67 edges). Lo llama el [[consumer]] en cada evento.
`bash tools/graph_query.sh "calculate_risk"` para ver quién más depende de él.
