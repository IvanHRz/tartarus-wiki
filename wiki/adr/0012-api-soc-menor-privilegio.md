---
tipo: adr
estado: aceptada
creado: 2026-08-07
actualizado: 2026-08-07
commit_ref: c06f63b
tags: [api, auth, soc, siem, m2m, least-privilege, E-D1]
---

# ADR-0012 — API SOC de menor privilegio (consumo por máquinas)

> Para que un SOC/SIEM externo consuma alertas de TARTARUS ("API primero", petición del usuario).
> La consola es solo-humano (JWT/cookie); hacía falta una credencial de **máquina** de menor privilegio.

## Contexto

El objetivo es que un SOC/SIEM externo pueda **jalar** alertas e inventario de TARTARUS (modelo
validado en el POC de campo: un script con token que hace poll a una API). Estado previo:
- La auth de consola (`session_auth.py`) es **solo-humano**: JWT hecho a mano, cookie `tartarus_token`,
  24h, y da rol completo. No sirve como credencial de máquina.
- Existía `engine/engine/auth.py` con `X-API-Key`/Bearer contra `TARTARUS_API_KEYS`, pero estaba
  **muerto** (no aplicado a ninguna ruta) y era **llave-plana compartida** (sin identidad por
  consumidor, sin scope, sin flock).
- El `HmacVerifier` firma el **cuerpo** de webhooks entrantes — incómodo para un GET de lectura.

## Decisión

**Tokens SOC de menor privilegio, por-consumidor, hasheados, read-only y opcionalmente scopeados a un
flock** (`engine/engine/soc_auth.py`), sobre una **superficie de lectura versionada** (`soc_router.py`).

- Tabla `soc_tokens` (SHA-256 del token, nunca el claro; `name`, `flock_id?`, `scope='read'`, `revoked`).
- Emitir (claro **una sola vez**) / listar / revocar → acciones de **consola** (RBAC admin).
- `require_soc`: `X-API-Key` o `Authorization: Bearer` → 401 si falta/inválido. Deja el principal en
  `request.state.soc` (scope por flock + auditoría).
- Rutas de máquina `/api/v1/soc/{incidents,devices,detections}` (read-only, `rate_limit` 120/min,
  scopeadas al flock del token). **Saltan** el middleware de sesión de consola (usan su propia auth).
- El engine se bindea a `127.0.0.1` (no en la interfaz externa); en prod el único ingress es nginx TLS.

## Alternativas descartadas

| Opción | Por qué no |
|---|---|
| Extender el JWT de consola | Solo-humano, 24h, rol completo — no es una credencial de máquina de menor privilegio. Reusarlo obligaría a un SOC a "loguearse" con user/pass y replicar el JWT. |
| Llave-plana compartida (`auth.py`) | Sin identidad por-consumidor, sin scope read-only, sin flock, sin revocar/rotar por consumidor. Un leak compromete a todos. |
| HMAC sobre el cuerpo (`HmacVerifier`) | Pensado para **push** firmado entrante; firmar el cuerpo de un **GET** de pull es antinatural. Se reserva para el path de push (E-D2). |

## Consecuencias

- Menor privilegio real: un token de un cliente (flock A) **no** puede leer datos del flock B
  (verificado E2E: token scopeado a flock vacío → 0 incidents).
- Contrato **versionado y estable** (`/v1/soc/*`) desacoplado de los endpoints internos de la consola:
  el SOC no se rompe si cambia la UI.
- **Deuda de despliegue (no de código):** para producción falta cert TLS real (`certs/` vacío),
  hostname estable y `TARTARUS_SESSION_AUTH=true` — ver [[deploy-checklist]] (runbook). Sin eso, la API
  quedaría en HTTP/loopback.
- **E-D2 abierto:** el *feed* real al SIEM (pull vs push) se decide después. Pull = el SIEM hace poll a
  esta API; push = un canal syslog/CEF/webhook en `notifier.py`.

## Enlaces
- [[deploy-checklist]] (runbook de la API SOC) · [[0003-rbac-tres-roles]] (roles reusados) ·
  [[0002-multi-tenancy-flocks]] (el scope por flock) · [[roadmap]] (Tier E, E-D).
