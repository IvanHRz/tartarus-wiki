---
tipo: roadmap
creado: 2026-08-07
actualizado: 2026-08-07
commit_ref: 0085c31
tags: [despliegue, readiness, gate, campo]
---

# Deploy Checklist — Definición de "desplegable"

> El **por qué**: antes de esto, "desplegable" era una sensación, no un criterio. Con gente nueva
> entrando a producción (RPi de campo) hace falta una línea dura. Esta página **es** esa línea.
> El *cómo* operativo (flashear, `scp`, `docker compose`) vive en los runbooks del repo
> (`rpi3/RPI3_DEPLOYMENT.md`, `scripts/push-to-rpi.sh`); aquí está el **criterio de aceptación**.

## Puerta automatizada

`bash scripts/audit_gate.sh` debe salir **exit 0** (Tier 0 sano). No se despliega en rojo.

## Gates bloqueantes (🔴 — sin esto NO se despliega)

- [ ] **Ingesta no ciega (#10 / T0-1):** `/health` reporta `checks.ingestion` y pasa a
  `degraded/stale` cuando la ingesta se detiene. El consumer se re-conecta solo por inactividad.
  Ver [[2026-08-07-ingesta-amqp-ciega]].
- [ ] **Telemetría de campo real (T0-2):** un evento simulado desde un sensor de campo (con HMAC)
  aterriza en `events` y aparece en el feed vía **un** transporte autenticado. Hoy el path RPi
  apunta a `/events/webhook` (inexistente, 404) y la config copiada traza AMQP a un `broker`
  inexistente — **arreglar antes de cualquier despliegue de campo real**.
- [ ] **Aislamiento entre flocks probado (T0-3):** `pytest engine/tests/integration/
  test_flock_isolation.py` verde contra Postgres real — el Cliente A jamás ve datos del B.

## Gates de calidad (🟠🟡 — deben estar verdes)

- [ ] Skills `tartarus-*` al día, sin duplicar ubicación (T0-4).
- [ ] Cerebro canónico único: auto-memory apunta a la wiki (T0-5).
- [ ] Postmortem del #10 + release de la versión desplegada (T0-7).
- [ ] Conteo de detección honesto: reglas *aplicables* vs *cargadas* (T0-8).
- [ ] Clean-slate reproducible antes de una demo (T0-11): `POST /admin/reset` o TRUNCATE documentado.

## Runbook de campo mínimo (RPi)

1. Flashear e iniciar el sensor (`rpi3/RPI3_DEPLOYMENT.md`).
2. Configurar el transporte **único** al engine (ver T0-2 / [[roadmap]] Tier E) — no mezclar
   webhook + AMQP.
3. Verificar en la consola que el sensor aparece **online** y con su `flock` correcto.
4. Lanzar 1 sonda de prueba → confirmar que aterriza en el feed del flock correcto.
5. Correr `scripts/audit_gate.sh` desde el engine antes de dar por bueno el despliegue.

## Enlaces
- [[roadmap]] (Tier 0 = esta puerta; Tier E = despliegue self-service) · [[2026-08-07-ingesta-amqp-ciega]] · [[sensores]]
