---
tipo: estado
creado: 2026-08-10
actualizado: 2026-08-10
tags: [competencia, thinkst, posicionamiento, mercado]
---

# Posicionamiento competitivo — Thinkst Canary como benchmark

> Por decisión de producto (10-ago-2026), **Thinkst Canary es el competidor principal de referencia**
> de TARTARUS. Toda comparativa de capacidades se mide contra él. Esta página es el marco para esas
> comparativas; se irá llenando conforme evaluemos cada área.

## Por qué Thinkst

Thinkst Canary es el referente del mercado de *deception* de alta fidelidad y bajo ruido: cada alerta se
resuelve leyendo pocos campos, y sus *Canaries* emulan servicios completos (*personalities*) que se ven
idénticos al real. Es el estándar contra el que nos queremos medir en fidelidad, cobertura y experiencia
de operación.

## Comparativa de capacidades (viva)

| Área | Thinkst Canary | TARTARUS (hoy) | Brecha / nota |
|------|----------------|----------------|---------------|
| Servicios/*personalities* | Amplio catálogo, configurable por dispositivo | SSH, HTTP, TCP, Telnet(SSH+LLM), MCP, Prometheus, Modbus/OT, ICMP | Comparable en núcleo; falta HTTPS (ver abajo) |
| **HTTPS/TLS** | Servicio de primera clase, certificado propio (CA interna/pública) o autofirmado | **No desplegado** (`:8443` mapeado sin servicio) | **Brecha**. Estudio y plan en `docs/ESTUDIO_HTTPS_TLS.md`. P2. |
| Telnet | Real | SSH+LLM en :23 (Beelzebub no tiene telnet nativo); Cowrie sí hace telnet real | Funciona para el CLI Cisco; telnet crudo no |
| Tokens/canarios | ~kits de tokens | Familias web/DNS, documentos, credenciales (decoy_reuse) | Comparable; seguir ampliando |
| Multi-tenancy | Consola central multi-cliente | Flocks (tenant por cliente) con aislamiento probado | Fortaleza propia |
| Ruido/triage | Cero ruido, alerta autoexplicativa | Alertas enriquecidas + acknowledge | Comparable |
| LLM en honeypots | — | SSH/Telnet con LLM (gpt-4o-mini) | Diferenciador propio |

## Primeras conclusiones

- **HTTPS** es capacidad esperada en el mercado (Thinkst y OpenCanary la ofrecen). Recomendado
  desplegarla en TARTARUS con certificado configurable, replicando el modelo de Thinkst (subir cert de
  confianza). Detalle: `docs/ESTUDIO_HTTPS_TLS.md`.
- **Telnet real** es una carencia de Beelzebub (no de TARTARUS): nuestro honeypot de :23 usa SSH+LLM para
  el CLI Cisco. Cowrie (open-source) sí hace telnet real — a considerar si el telnet crudo importa.

## Fuentes
- Thinkst — servicios/personalities y HTTPS con certificado (ver `docs/ESTUDIO_HTTPS_TLS.md` §Fuentes).
