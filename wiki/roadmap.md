---
tipo: roadmap
creado: 2026-07-09
actualizado: 2026-08-07
commit_ref: PR#12 (rama feature/tier0-deployment-readiness)
---

# Roadmap — TARTARUS

Estados: `idea` → `decidido` (ADR) → `en curso` (issue) → `hecho` (release) → `descartado` (con razón).
**Nada se borra.** Estimados: **S ≈ 1 día · M ≈ 2–3 días · L ≈ 1 semana**. El plan operativo detallado
vive en `.agents/ROADMAP.md` (repo de código).

## Hecho — MSSP / multi-tenancy (v0.5.0 → v0.6.2, PR #8)

Flocks + RBAC + Acknowledge + Attack Map + consola de dos niveles, cada uno con su ADR
([[0002-multi-tenancy-flocks]]…[[0006-consola-dos-niveles]]) + pin de Beelzebub v3.8.0.

## Hecho — Tier 0: readiness (PR #12) ✅

La **puerta de calidad** antes de features. Gate 11/11 (`scripts/audit_gate.sh`). Aquí se cerró el
riesgo que nos frenaba:

| Ítem | Estado |
|---|---|
| **Ingesta ciega (#10)** — detección de frescura + reconexión AMQP | ✅ ([[2026-08-07-ingesta-amqp-ciega|postmortem]]) |
| Telemetría de campo (`POST /ingest/sensor`, HMAC) | ✅ |
| Test de integración de aislamiento entre flocks (Postgres real) | ✅ |
| Conteo de detección honesto (cargadas vs aplicables) | ✅ |

## En curso — Tier E: sensores, despliegue, consola, API (PR #12)

| Ítem | Estado | Nota |
|---|---|---|
| Enrolamiento de sensores por token + auto-bind a flock | ✅ | re-home al borrar flock |
| Honeypot **OT (Modbus)** + scoring ICS | ✅ | write = crítico |
| Detección de port-scan de primera clase | ✅ | |
| Cebos que "beaconan" + creds únicas + breadcrumbs reconciliados | ✅ | falta file-share SMB (E-C.4) |
| **API SOC** read-only con token de menor privilegio | ✅ base | ver [[0012-api-soc-menor-privilegio]] |
| Notificaciones (persistencia + credenciales + Ignorar-IP real) | ✅ | falta canal **SMS** |
| Dashboard alerts-centric (Principal/Análisis/Gestión) | ✅ | ver [[0011-dashboard-alerts-centric]] |
| **Pendiente**: feed real al SIEM (pull vs push), file-share SMB, LDAP/VNC + realismo (AD-DC), modos VM/OVA·Tailscale (nube al final) | idea/decidido | tras Tier F |

## Tier F — brechas de producto y validación (nuevo, en cola)

Salieron de probar la consola en vivo. Detalle con causa raíz en `.agents/ROADMAP.md` §Tier F.

| Grupo | Ítems | Est. |
|---|---|---|
| **Aislamiento fino** (seguridad) | Fuga cosmética de totales por flock (#1a) · kill-chain/correlación sin filtrar (#1b) · **clamp datos por usuario→flock** (#1c) · Usuarios&Roles claro (#12) | S · S–M · **M** · S–M |
| **Claridad de consola** | Memo con Enter (#4/#6, un solo fix) · Attack Map con logs al click (#2) · búsqueda estratégica (#3) · sensores color+etiqueta (#5) · estados vacíos (#8/#11) · detección concisa (#10) · copy de deception (#7) | S–M cada uno |
| **Motor de IA del honeypot** | Rotar/asegurar la llave (#13a) · **panel de prompts de persona** — que actúe como Windows/PowerShell (#13b) | S–M · **L** |
| **Validación E2E** | Desplegar 1 token de cada tipo + alertas email/Telegram/**SMS** en bucle (#9) | M (requiere credenciales) |

## Bloqueante: validación en hardware RPi 5 16GB

[[0001-arquitectura-de-sensores]] sigue `PROPOSED` y **prohíbe** implementar hasta pasar 6 criterios de
campo (scanner nativo, icmp-canary por host networking, bootstrap idempotente, DROP de `remote_sensors`
tras actualizar `docs/generate_report.py:553`). Todo el cluster de sensores distribuidos depende de esto.

## Descartado (se conserva la razón)

| Ítem | Por qué |
|---|---|
| Host networking universal | Rompe DNS del bridge; Docker Desktop lo emula mal en Mac; expone Redis sin auth |
| Scanner ↔ engine vía HTTP | No resuelve el fondo; dos canales para el mismo concepto |

## Enlaces
[[sintesis]] · [[estado-y-rumbo]] · [[deploy-checklist]] · [[brief-cowork]]
