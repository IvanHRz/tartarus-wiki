---
tipo: adr
estado: aceptada
creado: 2026-03-10
actualizado: 2026-07-30
commit_ref: 0085c31
adr_original: .raw/vault-legacy/Knowledge Base/Decisions/ADR-003 Risk Scoring Algorithm.md
tags: [riesgo, scoring, detection, mitre]
---

# ADR-0009 — Risk scoring aditivo

> Destilada del vault legacy (marzo 2026, v0.5.0). La decisión sigue vigente.

## Contexto

Cada evento de honeypot necesita una severidad (0–100) para priorizar en el dashboard y
disparar alertas.

## Decisión

**Modelo aditivo y determinista** en `engine/engine/risk_engine.py`: puntaje base por
protocolo + modificadores por patrón (comandos peligrosos, escalada de privilegios,
rutas de exploit, SQLi/XSS, brute-force, movimiento lateral, IP externa), tope en 100.
Cada evento recibe además `mitre_tactic` + `mitre_technique`.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| ML / modelo entrenado | Cero explicabilidad, necesita dataset etiquetado y mantenimiento; para un honeypot (donde todo es hostil) el patrón-matching determinista basta y es auditable. |
| Scoring por reglas Sigma únicamente | El score numérico y las reglas Sigma son ejes distintos: el score prioriza, Sigma clasifica. Se usan juntos, no en lugar del otro. |

## Consecuencias

- Simple, determinista, explicable; se tunea ajustando constantes. Sin ML.
- **El umbral 70 es la línea "alerta"** de todo el sistema (`should_alert`, `high_risk`
  en flocks, notifier). Cambiarlo mueve muchas superficies a la vez — es acoplamiento
  implícito a tener en cuenta.
- Las constantes concretas (base por protocolo, modificadores) **viven en el código**,
  no aquí: la tabla de la ADR original (SSH=30, HTTP=20, TCP=25…) puede haber derivado.
  Fuente de verdad: `engine/engine/risk_engine.py`.

## Estado real — verificado contra `0085c31` (2026-07-30)

`risk_engine.py` existe y es aditivo. En un ataque real la distribución sale coherente
(61 critical / 63 high / 4 medium sobre 128 eventos). El enfoque de la ADR se sostiene;
no se re-copian las constantes para no mentir cuando deriven.

## Enlaces

- [[0008-rabbitmq-event-bus]] — de dónde vienen los eventos que se puntúan
