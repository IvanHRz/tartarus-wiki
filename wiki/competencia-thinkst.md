---
tipo: estado
creado: 2026-08-10
actualizado: 2026-09-16
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
| **Modos de despliegue** | 5: hardware, VM (ESXi/Hyper-V/OpenStack/Nutanix), nube (AWS/GCP/Azure/Oracle), Docker, Tailscale — todos con **token de enrolamiento** | **2 «a medias»**: Docker y RPi5 | **Brecha, y peor de lo que parecía** (16-sep-2026): el de Docker **no tiene imagen publicada** (sin `Dockerfile`, sin registry, sólo `arm64`) y el de hardware **nunca enrola** — `setup-rpi.sh` no menciona `enroll`/`token`/`flock`. Ver `#docker-sin-imagen` y `#hardware-nunca-enrola`. Los cuatro nuevos, en el bloque D-bis |
| **Facilidad de alta** | Un modal por modo: *Versión · SHA256 · Launch*. El hardware se registra **a mano** (*«Hardware — Manual registration»*) | Seis caminos distintos y ninguno entero | **Aquí podemos ganarles**: controlamos la tarjeta, así que la RPi5 puede ser *graba, escribe el token en `/boot`, enciende* (`#rpi5-un-paso`) |
| **API para máquinas** | Claves globales y **por flock**, con nivel de permiso, último uso y revocación; *API Documentation* en el menú | `soc_tokens` + `/v1/soc/*` con hash, flock, `last_used_at` y revocación — **y cero UI** (`grep -i soc ui/src/` → 0) | Casi paridad **en el motor**, cero en la consola. Falta la pantalla y el nivel de permiso (hoy `read` fijo). Ver `#api-sin-consola` |
| **Audit trail** | Buscador, filtro, ficha desplegable (*Performed by · Action · Timestamp · IP · Description · Browser Agent*), volcado JSON, paginación | `console_audit` + middleware + `GET /audit` + tabla de 50 filas | Brecha media. **No se audita ninguna lectura** —una exportación no deja rastro—, no se exporta, no hay antes/después ni retención, y los shims del honeypot ensucian la tabla. Ver bloque **T** |
| **Ajustes** | **Una** pantalla con secciones plegables, y el mismo ajuste en dos niveles (global / por flock) con interruptor **Off / On / Global** | **Siete modales sueltos** colgando del menú de usuario | Brecha de arquitectura de la información, no de funcionalidad: tenemos `notify_config` y `notify_config_flock` y la consola **no enseña la distinción**. Ver `#ajustes-unificado` |
| **Roles** | **Dos**, explicados en una frase dentro de la pantalla (*Regular user* / *Admin user*) | **Tres** en un desplegable (`global_admin`/`manager`/`watcher`) | Decidido el 16-sep: **dos visibles, tres por dentro** (`#dos-roles-visibles`) |
| **Sistema de diseño** | Consistente, con tema claro | **12 tokens contra 133 colores, 22 tamaños de letra y 131 espaciados**; 369 `style=` en línea; sin tema claro; 0 `:focus-visible` | Brecha grande y medida. Ver `#tokens-de-diseno` |
| **Decepción contra agentes de IA** | Dos personalidades nuevas el 4-sep-2026: *Agent-to-Agent (A2A) Service* y *Agent Provocateur*, «*specifically designed to detect agent interactions*» | **Sonda inversa** (`TARTARUS-ECHO-7F3A21`) en producción, pero sólo en respuestas HTML; **cebo corrupto** construido, probado y **sin cablear** | **Diferenciador propio si lo terminamos.** El cebo corrupto —una credencial que sólo una IA repara— no tiene equivalente público en Thinkst. Ver bloque **C** |

## Primeras conclusiones

- **HTTPS** es capacidad esperada en el mercado (Thinkst y OpenCanary la ofrecen). Recomendado
  desplegarla en TARTARUS con certificado configurable, replicando el modelo de Thinkst (subir cert de
  confianza). Detalle: `docs/ESTUDIO_HTTPS_TLS.md`.
- **Telnet real** es una carencia de Beelzebub (no de TARTARUS): nuestro honeypot de :23 usa SSH+LLM para
  el CLI Cisco. Cowrie (open-source) sí hace telnet real — a considerar si el telnet crudo importa.

## Lo que se estudió el 16-sep-2026

Iván trajo **9 PDF y 18 capturas** de su consola de Thinkst (`iqsec.com.mx`) en
`Gráfica/Guia de diseño simplista e intuitivo/`, más la lista de artículos de despliegue
(`Links de Guia de implementacion de despliegue optimo.rtf`). De ahí salen las siete filas nuevas
de la tabla y los ocho bloques del ROADMAP.

Lo que más se repite al mirarlos, y es la lección de producto: **sus pantallas hacen menos cosas y
se entienden solas**. El alta de un Canary por Docker es *Versión · SHA256 · Launch*; la de
Tailscale añade **un** campo con validación en línea («debe empezar por `tskey-auth-`»). Un campo,
una acción, y el estado se ve solo. Nuestra pantalla equivalente tiene siete bloques y un botón que
promete desplegar y en realidad **sondea puertos**.

## Fuentes
- Thinkst — servicios/personalities y HTTPS con certificado (ver `docs/ESTUDIO_HTTPS_TLS.md` §Fuentes).
