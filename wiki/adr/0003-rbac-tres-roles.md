---
tipo: adr
estado: aceptada
creado: 2026-07-30
actualizado: 2026-07-30
commit_ref: 0085c31
tags: [rbac, auth, mssp, seguridad]
---

# ADR-0003 — RBAC de tres roles

## Contexto

Con multi-tenancy ([[0002-multi-tenancy-flocks]]) el aislamiento de datos no basta:
hace falta **control de acceso**. Quién puede crear flocks, gestionar usuarios,
reconocer alertas, borrar tokens. El modelo Thinkst tiene tres roles y los adoptamos:
`global_admin` (todo), `manager` (su flock), `watcher` (solo lectura).

Implementado en `3f83f1c` (Flocks Fase 2).

## Decisión

**Módulo `rbac.py` puro y fail-closed, más un `current_user()` que hace fail-OPEN
en dev.**

- `rbac.py`: `canonical_role`, `can_mutate`, `allowed_flocks`, `can_access_flock` —
  funciones puras, sin estado, testeables. Ante rol desconocido → deniega (fail-closed).
- Cada endpoint mutante comprueba `rbac.can_mutate(current_user(request)["role"])` y
  devuelve 403 si no (flocks_router, alert_ux_router, sensor assign).
- `current_user()` (`session_auth.py`): si `SESSION_AUTH` está **deshabilitado**,
  devuelve un `operator` implícito con rol `global_admin`. La consola de desarrollo
  queda abierta a propósito.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| **Fail-closed también en dev** | Rompería la consola de desarrollo abierta que usamos a diario (habría que loguearse para todo). Se prioriza fricción cero en dev. **Costo:** ver Consecuencias. |
| **Permisos granulares (por recurso/acción)** | Sobreingeniería para la etapa. Tres roles cubren el modelo MSSP objetivo; granularidad se puede añadir sin romper el contrato puro de `rbac.py`. |
| **RBAC en middleware global** | Se optó por chequeo explícito por endpoint: más verboso pero cada ruta declara su propia política, visible en el sitio. |

## Consecuencias

- **Fail-open es un footgun de producción.** Si un despliegue real no habilita
  `SESSION_AUTH`, RBAC es un no-op: *todos son `global_admin`*. La seguridad del
  multi-tenant depende de una variable de entorno que es fácil olvidar. Debe ser
  bloqueante en el checklist de despliegue.
- `rbac.py` puro → los tests no necesitan levantar auth; se prueba la matriz de roles
  directo. Los tests de 403 monkeypatchean `current_user` a un `watcher`.
- No hay MFA/WebAuthn ni SAML SSO (roadmap T6-7) — el "enterprise" del login es solo
  el audit trail (`e8fb50f`).

## Estado real — verificado contra `0085c31` (2026-07-30)

`rbac.py` existe y es puro; `can_mutate` se comprueba en los endpoints mutantes de
flocks, alert-ux (acknowledge) y asignación de sensores. Tests de RBAC (watcher→403)
verdes.

| Prometido | Estado |
|---|---|
| 3 roles fail-closed | ✅ `rbac.py` |
| 403 en mutación sin permiso | ✅ flocks_router, alert_ux_router, sensor assign |
| Gestión de usuarios (crear/borrar) | ✅ `session_auth.py` (global_admin) |
| `SESSION_AUTH` obligatorio en prod | ⬜ no forzado — footgun documentado |

## Enlaces

- [[0002-multi-tenancy-flocks]] — el aislamiento que este RBAC protege
- [[backlog]] — MFA/SSO diferidos
