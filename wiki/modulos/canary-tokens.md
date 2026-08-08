---
tipo: modulo
creado: 2026-08-08
actualizado: 2026-08-08
commit_ref: fa60f1f
tags: [deception, canary, tokens, cebos, notificaciones]
---

# Módulo: Canary tokens (cebos) — qué dispara alerta y cuándo

> Verificado contra `fa60f1f` el 2026-08-08. Si el HEAD actual difiere mucho, esta página miente.
> Comprobar: `bash tools/stale_modules.sh`

## Responsabilidad

Generar, plantar y **rastrear** cebos que avisan cuando un atacante los toca. El *por qué* de esta
página: la pregunta recurrente *"dejé un archivo y no me llegó alerta ¿está roto?"* casi nunca es un
bug — es que **cada familia de cebo dispara con una acción distinta**, y confundirlas hace creer que
el sistema falla. Aquí queda fijada la realidad honesta por tipo. El *qué hace* está en el código
(`engine/engine/canary_router.py`, `canary_docgen.py`, `canary_planter.py`, `decoy_usage.py`).

## La regla mental — 3 familias

| Familia | Dispara al… | Fiabilidad |
|---|---|---|
| 🔗 **URL / DNS** | **accederse** la URL/imagen o resolverse el DNS | siempre (el más fiable) |
| 📄 **Documento** | **abrirse** en un visor que traiga contenido remoto | viewer-dependiente (no 100%) |
| 🔑 **Credencial** | **usarse** el secreto contra un honeypot (no al abrir el archivo) | siempre que se reuse |

## Matriz por tipo

| Cebo | Archivo | Familia | ¿Al abrir? | Mecanismo | Cuándo NO dispara |
|---|---|---|---|---|---|
| Word (doc-msword) | `.docx` | 📄 | sí, con contenido remoto | imagen externa **+ plantilla remota** (2 vectores) | Vista Protegida · Preview/Pages · sin red |
| Excel (xlsx-excel) | `.xlsx` | 📄 | sí, con contenido remoto | imagen externa (drawing OOXML) | Vista Protegida · visor sin imágenes remotas |
| PDF (pdf-acrobat) | `.pdf` | 📄 | a veces | `/OpenAction /URI` | **macOS Preview NO** · lectores que ignoran OpenAction |
| Web bug / image | URL | 🔗 | — (al cargar) | GET a la URL | si nadie carga la URL |
| Redirect | URL | 🔗 | — (al visitar) | GET + redirección | — |
| Cloned site/css | snippet | 🔗 | — (al rehospedar) | JS/CSS beacona fuera del dominio vigilado | en el dominio legítimo |
| DNS | registro | 🔗 | — (al resolver) | resolución del subdominio único | — |
| AWS / SSH-key / kubeconfig / gitconfig / .env / mysql / wireguard / cookie / sensitive-cmd | `.credentials`/`id_rsa`/`.yaml`/`.gitconfig`/`.env`/`.sql`/`.conf`/`.txt`/`.sh` | 🔑 | **no** | `decoy_reuse` (Sigma **critical**) con secreto **único por-plant** | solo abrir/leer el archivo |

> Honey credentials (sistema aparte): usuarios/contraseñas señuelo que disparan al **iniciar
> sesión** con ellas en el honeypot. También 🔑.

## Entradas / salidas

- **In:** el operador genera el cebo desde la consola (`#canarySection`) o el bundle; se planta.
- **Out (docs/web/DNS):** `GET /canary/t/{token}` → evento CANARY (risk≥40) → [[consumer]] → notifier.
- **Out (credencial):** el secreto aparece en `command`/`payload` de un evento → regla `decoy_reuse`
  (nivel critical, vía [[sigma-eval]]) → eleva riesgo → notifier.

## Invariantes (la realidad honesta que no se debe perder)

1. **Fire-on-open en Office NO es 100%** — bloqueo de contenido remoto / Vista Protegida. Ni Thinkst
   lo logra. Los que **siempre** disparan: 🔗 web/DNS y 🔑 credencial-en-uso.
2. **Las credenciales NO alertan al abrirse, por diseño.** El archivo es carnada; el disparo es al
   **usar** el secreto (`decoy_reuse`). Cada plant lleva un secreto **único** → cero falsos positivos.
3. **Alcanzabilidad manda.** El beacon llama a `TARTARUS_CANARY_BASE_URL`; si es `localhost`, un doc
   abierto en otra máquina no dispara. nginx enruta `/canary/` al engine (`329e9f1`). Ver la nota de
   alcanzabilidad y HTTPS en el repo (`docs/CANARY_ALCANZABILIDAD.md`).
4. **docx lleva doble vector** (imagen + plantilla remota) para subir la tasa de disparo.

## Trampas conocidas

- Abrir un `.env`/`id_rsa` y "no pasa nada" → esperado (familia 🔑, no dispara al abrir).
- Probar el `.pdf` en macOS Preview → no dispara; usar Adobe.
- Base en `localhost` → solo dispara en la misma máquina; la consola avisa (`GET /canary-tokens/base-url`).
- Rate-limit `alert_sent:{ip}` (1/IP/5min): reprobar por el mismo IP requiere limpiar la clave en Redis.

## Verificación

Circuito callback→evento→alerta probado E2E por HTTP (localhost y LAN+nginx) con
`scripts/verify_canary_open.py` (docx 2 vectores, pdf, xlsx = PASS). Detección `decoy_reuse` por
credencial en `engine/tests/test_canary_fire_matrix.py`. Detalle operativo completo:
`.raw/repo/docs/CEBOS_QUE_DISPARAN.md` y `.raw/repo/docs/CANARY_ALCANZABILIDAD.md`.
