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

## Runbook — API SOC (para que XSIAM/SOC consuma) · E-D1

> La API read-only ya existe (`/v1/soc/incidents|devices|detections`, token `X-API-Key`, rate-limited,
> scopeada al flock del token). El **código** está; lo de abajo es lo que la **infra** debe aplicar en
> el host real para exponerla con seguridad. Sin esto, no se entrega a un SOC.

1. **Engine internal-only** (ya en código): el compose base bindea el engine a `127.0.0.1` (no en la
   interfaz externa). No revertir a `0.0.0.0` en prod.
2. **TLS + hostname estable:** poner un certificado real en `./certs/server.{crt,key}` (o frontear con
   un reverse-proxy ACME/Let's Encrypt) y un DNS estable. `ui/nginx-prod.conf` ya termina TLS 1.2/1.3
   + HSTS + rate-limit y proxya `/api/` → engine. **Hoy `certs/` está vacío** — es el bloqueante.
3. **Activar la auth de consola en prod:** `TARTARUS_SESSION_AUTH=true` + `TARTARUS_JWT_SECRET` fuerte
   (el default es de dev). Las rutas `/v1/soc/` saltan la sesión de consola a propósito (usan su token).
4. **Emitir el token del SOC (menor privilegio):** `POST /api/soc/tokens {name:"xsiam", flock_id?}` →
   devuelve el token **una sola vez**. Dárselo a XSIAM/al colector. Revocar con `DELETE /api/soc/tokens/{id}`.
   No usar el token admin de consola para la SOC (regla de la doc de alcances).
5. **XSIAM consume:** `GET https://<host>/api/v1/soc/incidents?hours=1&limit=500` con
   `X-API-Key: <token>` en un poll programado (o el feed que se decida en E-D2). Una consola = un
   solo origen para las N unidades.
6. Verificar: sin token → 401; token válido → JSON; token de flock A no ve datos de B.

## Enlaces
- [[roadmap]] (Tier 0 = esta puerta; Tier E = despliegue self-service) · [[2026-08-07-ingesta-amqp-ciega]] · [[sensores]]
