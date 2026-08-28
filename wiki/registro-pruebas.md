# Registro de pruebas de aislamiento — TARTARUS

Bitácora de qué se atacó, contra qué puerto, y en qué cliente (flock) apareció.
La regla de oro: si algo asoma en un cliente que no toqué, se investiga por qué.

Reparto de sensores vigente (`sensor_registry`):

| Puerto | Sensor | Protocolo | Flock |
|---|---|---|---|
| 22 | beelzebub-ssh | ssh | Default |
| 23 | beelzebub-telnet | telnet | Default |
| 80 | beelzebub-http | http | Default |
| 502 | modbus-canary-01 | modbus | **Pruebita** |
| 2113 | beelzebub-prometheus | prometheus | Default |
| 3000 | beelzebub-mcp | mcp | Default |
| 8080 | beelzebub-tcp | tcp | Default |
| — | icmp-canary-dev-01 | icmp | Default |

Además, regla de asignación explícita: `honeypot_id = modbus-canary-01 → Pruebita`.

---

## 2026-08-28 · Prueba de humo tras la primera puesta a cero

Plataforma dejada a 0 con `scripts/puesta_a_cero.sh` (respaldo
`backups/db/tartarus_pre_reset_20260828_1509.sql.gz`). Cliente de prueba **Pruebita**
con el sensor Modbus (:502) recién registrado.

| Hora  | Ataque | Puerto | Flock esperado | Resultado (eventos/detec.) | Veredicto |
|---|---|---|---|---|---|
| ~15:10 | `attack_modbus.sh` | 502 | Pruebita | Pruebita 10/10 · resto 0 | ✅ Aislado |
| ~15:12 | `curl` al honeypot HTTP | 80 | Default | Default 5/5 · resto 0 | ✅ Aislado |

Estado final de la prueba (estable, medido con subconsultas correlacionadas):

| Flock | Eventos | Detec. | Trazas | Hosts | Cebos | Honey |
|---|---|---|---|---|---|---|
| Default Flock | 5 | 5 | 0 | 0 | 0 | 0 |
| IR | 0 | 0 | 0 | 0 | 0 | 0 |
| Iván | 0 | 0 | 0 | 0 | 0 | 0 |
| Pruebita | 10 | 10 | 0 | 0 | 0 | 0 |

**Conclusión:** aislamiento correcto. El ataque al puerto de Pruebita (502) no dejó
rastro en Default, IR ni Iván; el ataque HTTP cayó al Default sin tocar Pruebita.
Los testigos IR e Iván quedaron en 0 en todas las tablas.

**Nota metodológica:** un primer conteo dio «100/100» en Pruebita — era un artefacto
de un `LEFT JOIN` doble (producto cartesiano 10×10), no un dato real. Para contar por
flock hay que usar subconsultas correlacionadas, no dos LEFT JOIN encadenados.
