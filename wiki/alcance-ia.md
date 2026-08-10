---
tipo: estado
creado: 2026-08-10
actualizado: 2026-08-10
tags: [ia, llm, alcance, privacidad]
---

# Alcance de la IA en TARTARUS

> Apartado explícito, para dirección/asesoría: **hasta dónde llega la IA en la plataforma**, qué usa IA
> hoy, qué se planea, y qué NO usa IA a propósito. Detalle técnico en el repo: `docs/ALCANCE_IA_TARTARUS.md`.

## Principio rector

La IA **asiste**, no sustituye. Engaña al atacante (honeypots), resume y narra (reportes), ayuda a
investigar (análisis de eventos) y genera señuelos. Pero **no decide el riesgo** ni ve datos sensibles: la
detección es determinista y auditable, y **lo que va a un proveedor de IA siempre va anonimizado**
(sin direcciones IP, sin usuarios, sin contraseñas).

## Dónde SÍ usamos IA hoy

1. **Honeypots (Beelzebub).** Los señuelos SSH y "Telnet" (router Cisco) responden como el sistema real
   usando un modelo de lenguaje. Es la IA de cara al atacante; consume saldo por interacción. Con protección
   anti-jailbreak y, en el Telnet, respuestas de reserva sin IA para los comandos comunes (no queda mudo si
   la IA falla).
2. **Reportes de engagement.** La IA puede enriquecer el informe con la narrativa del ataque, patrones y
   recomendaciones. Es opcional y, sobre todo, **anonimizado**: nunca recibe datos del cliente.
3. **Análisis de eventos/sesiones (bajo demanda).** Un analista puede pedir a la IA un resumen de amenaza,
   la intención del atacante y las técnicas usadas. No corre solo; se dispara cuando se necesita.
4. **Generación de señuelos.** La IA puede crear árboles de archivos falsos realistas (con una alternativa
   sin IA si no está disponible).

## Dónde NO usamos IA (a propósito)

- **Puntaje de riesgo y detección** (reglas Sigma/YARA): deterministas, reproducibles y defendibles como
  evidencia. La IA no toca esto.
- **Inteligencia de amenazas**: usa fuentes públicas (Shodan, abuse.ch, etc.), no IA.

## Qué se planea (rumbo)

- Automatizar la correlación de sesión con IA (hoy es manual).
- Modelo de IA **local (Ollama)** para los honeypots y la generación de señuelos: costo cero y sin depender
  de una API de pago; ideal para el despliegue de campo (Raspberry Pi).
- Elegir el **proveedor de IA por señuelo desde la interfaz** (OpenAI, DeepSeek, OpenRouter, Ollama).
- A futuro: apoyo de IA para el análisis de registros (logs) y más automatización de la investigación.

## Proveedores

Hoy los honeypots usan OpenAI; el resto puede usar DeepSeek/Anthropic. Está listo el cambio a **DeepSeek**
(más barato) para cuando se agote el saldo actual, y evaluado el uso de **Ollama** local. Ver
[[actualizaciones-herramientas]].
