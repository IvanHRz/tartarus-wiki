---
tipo: adr
estado: aceptada
creado: 2026-07-30
actualizado: 2026-07-30
commit_ref: 0085c31
tags: [attack-map, mapeo, sensores, mitre, ui]
---

# ADR-0005 — Attack Map: contexto de despliegue

## Contexto

El Attack Map original era ambiguo: mostraba `atacante → categoría → sensor` pero no
decía **dónde** estaba desplegado cada honeypot, si el atacante era interno o externo,
ni qué técnica disparó. El usuario pidió claridad estilo Thinkst:
`atacante(int/ext) → técnica MITRE → honeypot(host:puerto) → flock`.

Implementado en `edd812a` (contexto) y `5891465` (host:port real desde el registro).

## Decisión

Enriquecer `build_attack_map` (`engine/engine/events_router.py`) con cuatro señales:

- **Interno/externo** por atacante vía `_is_private` (`threat_intel.py`, RFC1918).
- **Técnica MITRE dominante** por categoría (Counter sobre `mitre_technique`).
- **host:puerto** por sensor: se resuelve desde `sensor_registry` (despliegue real,
  incl. hosts remotos) vía un `sensor_lookup {PROTOCOL:(host,port)}`, con fallback a un
  mapa canónico estático `_SENSOR_ENDPOINT` por protocolo.
- **Nombre real del flock** (arregla el bug de "siempre Default Flock": el endpoint no
  pasaba el nombre).

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| **Solo el dict estático `_SENSOR_ENDPOINT`** | No refleja hosts remotos/custom; un despliegue distribuido mostraría host:port falsos. Se conserva **solo como fallback** cuando el sensor no está en el registro. |
| **Join `events.honeypot_id` → `sensor_registry.sensor_id`** | Imposible hoy: `honeypot_id` es el `HandlerName` de Beelzebub, texto libre y **de hecho vacío** (issue `#11`). No hay llave. Por eso se mapea por `protocol`, no por sensor real. |

## Consecuencias

- **El nodo-sensor es sintético, derivado del protocolo, no de un join real.** Un
  sensor registrado con 0 eventos no aparece; un protocolo en `events` sin fila en el
  registro genera un sensor "fantasma". El eslabón roto `events.honeypot_id` (issue
  `#11`) es la causa raíz; cerrarlo (clave estable de sensor en `events`) desbloquearía
  el mapeo completo.
- Prometheus aparece como `-:2113` — no está en `sensor_registry` ni en el mapa
  canónico. Cosmético, pero visible.
- `dest_port` es heurístico (derivado en `consumer.py`), no el socket real; se prioriza
  sobre el puerto canónico, así que un `dest_port` mal derivado propaga un puerto de
  sensor incorrecto.

## Estado real — verificado contra `0085c31` (2026-07-30)

Implementado, mergeado (#8). Verificado con ataque real: atacantes con badge INTERNO
(RFC1918 correcto), técnicas por categoría (T1046, T1059.004, T1595…), sensores con
`beelzebub:22/:80/:3000/:8080`, contenedor con nombre real del flock ("Global" en
vista global). El fallback estático cubre el dev; el registro real cubriría remoto.

## Enlaces

- [[0002-multi-tenancy-flocks]] — el flock del atacante
- [[sensores]] — el registro del que se leen host:port
