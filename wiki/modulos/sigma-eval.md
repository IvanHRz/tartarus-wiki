---
tipo: modulo
creado: 2026-08-06
actualizado: 2026-08-06
commit_ref: 0085c31
tags: [sigma, detection, seguridad, eval]
---

# Módulo: Sigma-eval

> Verificado contra `0085c31` el 2026-08-06. Si el HEAD actual difiere mucho, esta página miente.
> Comprobar: `bash tools/stale_modules.sh`

## Responsabilidad

Evaluar cada evento contra las reglas Sigma en tiempo real, inline, sin latencia de
subproceso. `engine/engine/sigma_lite.py`. God-node `_safe_eval_condition()` (28 edges).

## Entradas / salidas

- **In:** el `event` + las reglas cargadas de `engine/rules/sigma/`.
- **Out:** lista de hits `{rule_id, rule_title, level, mitre_*}` → el [[consumer]] los inserta
  en `detections`.

## Invariantes

> [!danger] NUNCA se usa `eval`/`exec` sobre la condición Sigma (BUG-015)
> El campo `condition` de una regla Sigma es texto controlado por quien escribe reglas.
> Pasarlo a `eval()` sería RCE. En su lugar se parsea a **AST de Python** y se camina por
> un **whitelist** (`BoolOp` and/or/not + nombres de selección). Cualquier nodo fuera del
> whitelist (llamadas, atributos, literales no-bool) lanza `ValueError`. Esta invariante es
> de seguridad — no relajarla nunca.

## Trampas conocidas

> [!warning] Solo las reglas `product: tartarus` disparan en un honeypot
> De 424 reglas Sigma cargadas, **89 son honeypot-nativas** (`product: tartarus`, evalúan
> por `command`/`http_path`). Las **254 `product: windows`** son forenses y **nunca**
> disparan aquí. Un ataque real dispara ~38 reglas (43% de las aplicables). El número
> "424 cargadas" del dashboard engaña: hay que mostrar "89 aplicables / N disparadas".
> Ver [[sintesis]].

- Las reglas se cargan al arranque (cache); añadir reglas requiere rescan
  (`detection_router.rescan_recent_events`) para detectar retroactivamente.

## Grafo

God-nodes: `_safe_eval_condition()` (28), `TestSigmaSafeEval` (26 — el test que vigila la
invariante de seguridad). `bash tools/graph_query.sh "_safe_eval_condition"`.
