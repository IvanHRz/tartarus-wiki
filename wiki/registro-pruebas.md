# Registro de pruebas de aislamiento — TARTARUS

Bitácora de qué se atacó, contra qué puerto, y en qué cliente (flock) apareció.
La regla de oro: si algo asoma en un cliente que no toqué, se investiga por qué.

## Reparto de sensores vigente (`sensor_registry`)

Flota base (plataforma, en el flock por defecto) + los que cada cliente despliega.

| Puerto | Sensor | Protocolo | Flock |
|---|---|---|---|
| 22 | beelzebub-ssh | ssh | Default |
| 23 | beelzebub-telnet | telnet | Default |
| 80 | beelzebub-http | http | Default |
| 3000 | beelzebub-mcp | mcp | Default |
| 8080 | beelzebub-tcp | tcp | Default |
| — | icmp-canary-dev-01 | icmp | Default |
| 502 | modbus-canary-01 | modbus | **Cliente Demo 01** |

Regla de asignación explícita: `honeypot_id = modbus-canary-01 → Cliente Demo 01`.

---

## 2026-08-28 · Reinicio de fábrica + alta de cliente desde cero

Plataforma llevada a **estado de instalación nueva** con `scripts/reinicio_de_fabrica.sh`
(respaldo `backups/db/tartarus_pre_fabrica_20260828_1552.sql.gz`): borrados los flocks de
cliente previos (Iván, IR, Pruebita) y sus reglas, flota base reconstruida por el bootstrap
del engine (6 sensores, todos en Default).

Onboarding de un cliente nuevo **por el flujo real del producto**:
1. `POST /flocks` → «Cliente Demo 01».
2. `POST /flocks/{id}/assignments` → regla `honeypot_id=modbus-canary-01`; sensor Modbus (:502)
   registrado a su nombre.
3. `POST /deploy/execute` → cebo AWS plantado (53 B en disco) y asignado al cliente.

### Prueba de aislamiento

| Hora | Ataque | Puerto | Flock esperado | Resultado (ev./det.) | Veredicto |
|---|---|---|---|---|---|
| ~15:53 | `attack_modbus.sh` | 502 | Cliente Demo 01 | Cliente 10/10 | ✅ Aislado |
| ~15:53 | `curl` HTTP | 80 | Default | Default 5/5 | ✅ Aislado |
| ~15:55 | SSH (sondas) | 22 | Default | Default 60 | ✅ |
| ~15:55 | `attack_tcp.sh` | 8080 | Default | Default 32 | ✅ |
| ~15:55 | `attack_prometheus.sh` | 2113 | Default | Default 10 | ✅ (antes «sin sensor») |
| ~15:55 | `attack_telnet.sh` | 23 | Default | **no llegó** (`TIMEOUT_CONNECT`) | ⚠ Beelzebub |

Desglose final por protocolo/puerto:

| Protocolo | Puerto | Flock | Eventos |
|---|---|---|---|
| MODBUS | 502 | Cliente Demo 01 | 10 |
| SSH | 22 | Default | 60 |
| TCP | 8080 | Default | 31 |
| PROMETHEUS | 2113 | Default | 10 |
| HTTP | 80 | Default | 5 |
| TCP/HTTP | 8080 | Default | 1 |

**Conclusión:** aislamiento correcto. El cliente recibió **solo** sus 10 eventos Modbus
(0 eventos de otro protocolo). Todo lo atacado contra la flota base cayó en Default. Prometheus
(2113), antes «sin sensor», ya atribuye bien.

**Observación para Beelzebub:** el ataque Telnet (:23) devolvió `TIMEOUT_CONNECT` — no aterrizó
ningún evento. Candidato a revisar cuando se aborde la fiabilidad de Beelzebub.

**Nota metodológica:** contar por flock con subconsultas correlacionadas, no con `LEFT JOIN`
encadenados (producto cartesiano infla los conteos).
