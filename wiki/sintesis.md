---
tipo: sintesis
creado: 2026-07-09
actualizado: 2026-08-07
commit_ref: PR#12 (rama feature/tier0-deployment-readiness)
---

# TARTARUS — el proyecto en una página

> Para lectura rápida de dirección/asesoría. El detalle técnico vive en las [[modulos|páginas de
> módulo]], los ADRs y el `.agents/ROADMAP.md`. La bitácora de cambios está en `log.md`.

## Qué es TARTARUS

Una **plataforma de engaño para respuesta a incidentes (deception / IR)**: despliega *honeypots*
(trampas que imitan servidores reales) y *cebos* (tokens y migajas que se siembran en activos
reales), captura cómo actúa un atacante, le pone **riesgo** (0–100) y **contexto MITRE ATT&CK**, y lo
pinta en tiempo real en una consola propia (Canvas, sin frameworks). El diferenciador frente a
productos como Thinkst Canary: honeypots con **LLM** (respuestas creíbles), analítica inline
(Sigma/YARA), kill-chain automático y reportería forense — todo self-hosted.

Modelo de operación: **MSSP multi-cliente**. Cada cliente es un *flock* aislado; una sola consola de
dos niveles (madre = visión global; workspace = un cliente) los gobierna.

## Dónde estamos hoy

El periodo pasado cerró el **salto a MSSP** (multi-tenancy: flocks, RBAC, dos niveles, acknowledge,
attack-map — todo con su ADR). Sobre esa base, la sesión más reciente entregó dos programas grandes,
hoy en **PR #12** (rama `feature/tier0-deployment-readiness`, suite 882 verde):

- **Tier 0 — "listo para desplegar".** Un *health-gate* re-ejecutable (`scripts/audit_gate.sh`) que
  sana 11 puntos flojos del proceso y del despliegue antes de meter features nuevas. **Aquí se cerró
  el riesgo crítico que nos frenaba** (la ingesta ciega, #10) y se puso un test real de aislamiento
  entre clientes. Ver [[2026-08-07-ingesta-amqp-ciega|postmortem #10]].
- **Tier E — sensores, despliegue y consola.** El arranque del modelo de campo: **enrolamiento** de
  sensores por token (auto-vinculados a su cliente), un **honeypot OT (Modbus)** para redes
  industriales, **detección de escaneo de puertos**, **consolidación de los cebos** (que antes no
  "llamaban a casa"), una **API de solo-lectura con token de menor privilegio** para que un SOC/SIEM
  consuma alertas, y un **dashboard reordenado** (centrado en alertas, como la referencia del mercado).

Detalle vivo: [[estado-y-rumbo]] · [[roadmap]] · [[0012-api-soc-menor-privilegio]] · [[0011-dashboard-alerts-centric]].

## Lo que cambió respecto a la foto anterior

La "tensión central" de julio era: *chasis sólido, falta demostrar que el motor enciende fiable.*
Eso ya se movió:

- **La ingesta ciega (#10) está detectada y con auto-reconexión** — `/health` avisa si deja de
  entrar tráfico. Ya no es un riesgo silencioso de "cliente ciego".
- **El aislamiento entre flocks ya tiene test de integración** contra Postgres real (antes solo
  había pruebas con base mockeada).
- **El conteo de detección es honesto**: la plataforma ya distingue reglas *cargadas* de las
  *aplicables al honeypot* (antes anunciaba un número inflado).

## A dónde vamos — la tensión de ahora

El chasis y el motor están; **falta pulir la cabina y cerrar el aislamiento fino**. Tras probar la
consola en vivo salieron **13 brechas de producto** (ver [[estado-y-rumbo]] y `ROADMAP` Tier F). Los
tres hilos que importan:

1. **Aislamiento multi-cliente fino.** El backend **sí aísla** los datos por flock, pero (a) un guard
   cosmético de la UI hacía *parecer* que se mezclaban los totales, (b) dos vistas (kill-chain,
   correlación) salían sin filtrar, y (c) —lo de fondo— la asignación *usuario→cliente* todavía **no
   restringe** qué datos puede pedir un usuario. Para un MSSP real, cerrar (c) es la pieza de seguridad.
2. **Claridad de la consola.** Varias secciones son potentes pero no se explican solas (Session
   Correlation, Threat Intelligence, Breadcrumbs/Personalities, el memo del analista que no guardaba
   con Enter). Regla de oro adoptada: **intuición y facilidad** — una alerta se resuelve en 5–8 campos.
3. **El motor de IA del honeypot.** La llave de OpenAI está bien fuera de git, pero expuesta en el
   artefacto de despliegue; y falta un **panel para editar los "prompts de persona"** desde la app
   (que el señuelo actúe como Windows/PowerShell, no solo Ubuntu) — la base ya existe.

## En una frase

**TARTARUS ya es una plataforma MSSP desplegable y verificable; el trabajo ahora es de producto:
cerrar el aislamiento fino, hacer la consola auto-explicable, y validar de punta a punta que los
cebos y las alertas realmente jalan.**

## Enlaces
- [[estado-y-rumbo]] — qué tenemos, qué se evalúa/mejora, próximas acciones con estimados.
- [[roadmap]] — el plan por fases. · [[deploy-checklist]] — qué es "desplegable".
- [[brief-cowork]] — onboarding para quien llega a ayudar a dirigir.
