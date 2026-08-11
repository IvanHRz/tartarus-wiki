---
tipo: estado
creado: 2026-08-10
actualizado: 2026-08-10
tags: [herramientas, versiones, upgrades, beelzebub]
---

# Actualizaciones de nuestras herramientas (tool-watch)

> Apartado **vivo**: el estado, la versión y las mejoras pendientes de cada herramienta que usamos.
> Sirve para no quedarnos atrás con las capacidades nuevas del upstream y decidir cuándo actualizar.
> Se actualiza conforme revisamos cada herramienta.

## Beelzebub (framework de honeypots) — **lo prioritario ahora**

- ✅ **ACTUALIZADO el 10-ago-2026: `v3.8.0` → `v3.9.0`** (multi-arch amd64+arm64; sirve también para el
  RPi). Verificado de punta a punta: los 6 servicios cargan sin errores del nuevo validador por esquema,
  todos los honeypots responden, y el pipeline sigue ingiriendo. **No rompió nada** (nuestros YAML, los
  guardrails y el respaldo del Telnet siguen igual). Rollback documentado (volver a v3.8.0).
- 🎁 **El upgrade DESBLOQUEÓ nativamente varias mejoras que teníamos pendientes** (confirmado inspeccionando
  el binario de v3.9.0):
  | Capacidad ahora NATIVA en v3.9.0 | Antes (v3.8.0) | Qué cambia |
  |----------------------------------|----------------|------------|
  | ✅ **Telnet nativo** (`TelnetStrategy`) — **APROVECHADO (11-ago)** | Hack SSH-en-:23 | El :23 ahora habla **telnet real** y captura botnets IoT/Mirai (conservando el CLI Cisco por IA). Verificado |
  | ✅ **HTTPS/TLS nativo** (`tlsCertPath`/`tlsKeyPath`) — **APROVECHADO (11-ago)** | No había | Honeypot HTTPS en :443 **sin nginx**, con certificado. Resuelto el hueco del estudio HTTPS. Verificado |
  | **Multi-proveedor LLM** (`host`/`BaseURL`) | Hardcode OpenAI | DeepSeek/OpenRouter vía `host` (provider `openai`) u **Ollama** — confirma el runbook |
  | **MazeHoneypot** (laberinto anti-scanner, solo HTTP) | Sin usar | Disponible para activar |
  | **Guardrail nativo** ("guardrail detected malicious output") | Solo nuestro prompt | Refuerzo adicional del framework |
  | **Config por JSON** (`BEELZEBUB_SERVICES_CONFIG`) | Key hardcodeada | Vía para sacar la key del YAML |
  → **Re-prioriza "lo demás":** telnet nativo y HTTPS nativo pasan de "construir desde cero" a "configurar".
- **Versión anterior:** `m4r10/beelzebub:v3.8.0` (imagen precompilada; su código Go no está en el repo).
- **Qué usamos:** protocolos SSH/HTTP/TCP nativos; "Telnet" y "MCP" **emulados** (no nativos); LLM OpenAI;
  tracing por RabbitMQ.
- **Capacidades del upstream que NO aprovechamos (huecos):**
  | Capacidad | Estado en TARTARUS | Acción |
  |-----------|--------------------|--------|
  | Métricas Prometheus propias (`beelzebub_events_*`) | **Perdidas** — el puerto :2112 lo ocupa un honeypot falso; las reales no se publican | Exponerlas en otro puerto + panel de salud (P1) |
  | Telnet nativo (`protocol: telnet`) | No — usamos SSH-en-:23 | Añadir telnet real en paralelo (captura botnets IoT) (P1) |
  | Multi-proveedor LLM (DeepSeek/OpenRouter/Ollama vía `host`) | No — hardcode OpenAI | Selector por señuelo desde la UI (P1) |
  | Ollama local | No | Costo cero + campo (P2) |
  | MazeHoneypot (laberinto anti-scanner) | No | Añadir en HTTP/TCP (P2) |
  | MCP nativo | No — MCP falso vía HTTP | Evaluar (P2) |
  | Key por variable de entorno / JSON | No — key en el YAML | Sacarla del archivo (P1) |
- **Ya cerrado (10-ago-2026):** guardrails anti-jailbreak en los prompts (probado); respaldo estático en
  Telnet (no queda mudo si la IA falla); validación de los YAML de Beelzebub en CI.
- **⚠️ Decisión pendiente — ¿actualizar la imagen?** El marketing del upstream muestra **más proveedores de
  IA** (Anthropic, Grok, Gemini, OpenRouter) y **Telnet nativo**; puede que sean de una versión **más nueva**
  que la v3.8.0. Varias de nuestras mejoras podrían venir "gratis" con un upgrade. **Acción:** revisar el
  changelog del upstream y evaluar subir de versión (probando que no rompa nuestros YAML/persona). Detalle:
  `docs/AUDITORIA_BEELZEBUB.md`.

## Modelos / proveedores de IA

- **Hoy:** OpenAI `gpt-4o-mini` en los honeypots (con la clave de saldo actual).
- **Listo para migrar:** **DeepSeek** (más barato, ya validado en los reportes) — se activa al agotar el
  saldo de OpenAI. Runbook: `docs/RUNBOOK_LLM_DEEPSEEK.md`.
- **Evaluado:** **Ollama** local (sin costo por llamada, sin depender de red/pago) — ideal en campo.
- Ver [[alcance-ia]] para dónde se usa cada uno.

## Otras herramientas (a revisar en próximas rondas)

> Plantilla para ir llenando: versión que corremos · novedades del upstream · pendientes.

- **RabbitMQ** — bus de eventos. Estado: estable. Pendiente: revisar versión y el fix de heartbeat (BUG-037).
- **PostgreSQL 15** — almacenamiento. Estado: estable. Pendiente: revisar si conviene 16.
- **Redis 7** — caché/estado. Estado: estable.
- **bcrypt** (contraseñas) — pendiente: reconstruir la imagen del engine para dejarlo permanente.
- (ir añadiendo: Nginx, YARA, Sigma, etc.)
