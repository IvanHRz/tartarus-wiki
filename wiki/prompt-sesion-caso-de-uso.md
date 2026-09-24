---
tipo: guia
creado: 2026-09-24
actualizado: 2026-09-24
tags: [sesion, prompt, demo, caso-de-uso, http, mcp, ssh, trazabilidad]
---

# Prompt — sesión «el caso de uso: un incidente que recorre HTTP, MCP y SSH»

> **⚠️ Esta wiki es PÚBLICA** (`IvanHRz/tartarus-wiki`) y el repo de código no. Antes de archivar
> aquí un plan o una bitácora, léelo y quita credenciales, clientes reales y la receta de un fallo
> abierto — regla 0 del schema.
>
> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> **Esta sesión NECESITA el turno del stack** (los tres actos atacan los honeypots compartidos):
> pídelo por el mecanismo de siempre y no la arranques a la vez que otra que también ataque.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `~/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**). **El stack corre
  desde aquí**, no desde ningún worktree.
- Rama única: **`feature/tier0-deployment-readiness`**. Motor Python/FastAPI en `engine/`, consola
  JS sin frameworks en `ui/src/`, Postgres, Beelzebub. Motor en `:9001`, consola en `:8888`.
- Honeypots vivos: **SSH `:2222`**, **HTTP `:8880`**, **MCP `:3001`** (y HTTPS 8443, Telnet 2323,
  TCP 8080, Prometheus 2112, Docker 2375).
- Wiki aparte: `~/Documents/Wikis/wiki-tartarus`.

## Qué vamos a construir

Una **demostración de caso de uso**: un solo atacante (una sola IP) recorre los tres protocolos en
un mismo incidente, y la plataforma lo cuenta como **una historia**, no como eventos sueltos. Es lo
que enseña de golpe el poder del desarrollo **y la trazabilidad**.

El arco, en tres actos, en orden de fases MITRE ascendentes:

| Acto | Protocolo | Qué hace el atacante | Qué queda registrado (el plato fuerte) |
|---|---|---|---|
| **1 · Reconoce** | HTTP `:8880` | pide `/robots.txt`, `/.env`, `/.git`, `/wp-admin` con user-agent de escáner (gobuster/nikto), y carga la portada — que es un **clon completo de un sitio real** | 404 **canónico del stack** (no el «muro de 401» que delata a un honeypot normal); barrido web detectado (`T1595.003`); baliza canary; artefactos retenidos |
| **2 · Roba credenciales** | MCP `:3001` | handshake MCP real `initialize` → `tools/list` → `tools/call get-credentials {service:"database", environment:"prod"}` → recibe una clave `AKIA…` con formato perfecto | JSON-RPC 2.0 **de verdad**; esa `AKIA…` **queda sembrada como honey-cred rastreada**; detección **crítica** `mcp_credential_theft` (T1552) |
| **3 · Entra y saquea** | SSH `:2222` | login con la credencial de la persona → `sudo -i` (escala) → **reusa la `AKIA…` robada del acto 2** → lee el cebo → borra un log | coherencia del shell (los PID de `netstat` = los de `ps aux`), continuidad de sesión, y **el reúso del honeytoken del MCP dispara detección CRÍTICA de reúso de cebo** |
| **Cierre** | — | se va a la consola | **UNA kill chain** con los tres protocolos, riesgo alto, cadena MITRE completa; informe de compromiso en PDF |

**El eje que hace que esto funcione, y hay que respetarlo:**

- **La kill chain sólo se dispara con ≥2 protocolos distintos de la misma IP en 60 min**
  (`engine/engine/kill_chain_tracer.py:217`). Los tres actos se lanzan desde el Mac, así que
  comparten la IP de origen que ve Beelzebub → se correlacionan solos. **Pero primero hay que hacer
  puesta a cero**, o la historia se mezcla con el ruido histórico de esa misma IP.
- **El disparo de reúso va por el honeytoken del MCP, no por el árbol SSH.** `get-credentials` del
  MCP (`engine/engine/mcp_honeypot_router.py:234`) genera la credencial **en código** y la registra
  como honey-cred con su regla Sigma de reúso. El acto 3 **captura** la `AKIA…` que devolvió el acto
  2 y la teclea dentro de la sesión SSH; cuando ese literal aparece en un evento, salta
  `decoy_reuse_<hash>`. Los cebos del árbol SSH (p.ej. el `.env` del prompt) son texto que redacta
  el LLM y **no** son canarios rastreados (`canaries: []` en la persona viva) — sirven para
  enseñar, no disparan reúso.

## Antes de nada

Lee en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` → `.agents/COORDINACION.md` → la cabecera de
`.agents/ROADMAP.md` (§«POR DÓNDE SE RETOMA»; busca la entrada `{#caso-de-uso-encadenado}`).

**Crea tu propia copia de trabajo y decláratela:**

```bash
cd ~/Documents/Tartarus
scripts/sesion_paralela.sh nueva caso-de-uso     # crea ../Tartarus-caso-de-uso
# declara tu sección en .agents/COORDINACION.md con la plantilla del principio (se INSERTA, no se reescribe)
python3 scripts/revisar_sesiones.py              # tiene que salir verde
```

**No hagas `npm install` dentro de tu copia**: `node_modules` es un enlace simbólico y lo rompe.

## Cinco trampas medidas — cada una te tumba la demo en vivo si no la sabes

1. **La persona viva del SSH `:2222` es la de finanzas** (`gum-srv-finanzas-01`, «Merx»), **no la
   clínica**. Su usuario y contraseña, el árbol y el cebo son los de esa persona. El
   `scripts/demo/lab_ssh.sh` actual trae las credenciales de OTRA persona y lee un cebo que en ésta
   no existe → **falla el login y las fases finales**. Míralo en vivo antes de escribir nada:
   ```bash
   grep -n 'passwordRegex' ~/Documents/Tartarus/beelzebub/configurations/services/ssh-22.yaml
   grep -n 'START:\|Bait\|/opt/' ~/Documents/Tartarus/beelzebub/configurations/personalities/gum-srv-finanzas-01.yml
   ```
   (Esa persona y esos YAML **sólo existen en la copia principal**: `services/` está gitignoreado y
   no aparece en los worktrees. Los guiones atacan por red, así que no necesitan el YAML en disco —
   pero para leer credenciales, mira la copia principal.)
2. **El MCP habla JSON-RPC 2.0 por POST a `/`**, no REST por ruta. El `scripts/attack_mcp.sh` viejo
   usa `GET /tools/list` y hoy contra el honeypot real devuelve error. **No lo copies.** Toma el
   patrón bueno de `scripts/attack_all.py:_mcp_rpc` (~línea 265): un `{"jsonrpc":"2.0","id":N,
   "method":...}` por POST a `/`. Handshake correcto: `initialize` → `notifications/initialized` →
   `tools/list` → `tools/call`.
3. **`scripts/attack_http.sh` reinicia Beelzebub solo** si cree que la tubería está rota (~5 s de
   corte). En mitad de una demo eso es un desastre. Tu `lab_http.sh` **no** debe hacer eso.
4. **No abras estas docs delante de nadie**: `docs/AUDITORIA_BEELZEBUB.md` y
   `docs/ALCANCE_IA_TARTARUS.md` dicen que MCP y el laberinto «no existen» — están obsoletas desde
   el 31-ago. Lo real es que el MCP habla el protocolo y el maze es un toggle.
5. **Tres tablas están muertas** — no las enseñes como si se escribieran: `correlation_sessions`,
   `activity_clusters`, `mitre_evidence`. Las sesiones y los clusters se calculan **al vuelo** desde
   `events`; el mapa de evidencia MITRE también. Si las abres en el visor de BD saldrán vacías.

## Lo que vas a entregar

1. **`scripts/demo/lab_incidente.sh`** — el orquestador del arco entero: puesta a cero → acto 1
   (HTTP) → acto 2 (MCP, **captura la `AKIA…`**) → acto 3 (SSH, **reusa la `AKIA…`**) → apunta a la
   consola. Con pausas (Enter) entre actos para explicar; `AUTO=1` para ensayar sin pausas. Reutiliza
   el patrón de FIFO de `scripts/demo/lab_ssh.sh` (una sola sesión SSH, para que la escalada se
   recuerde) y el `_mcp_rpc` de `attack_all.py`.
2. **`scripts/demo/lab_http.sh`** y **`scripts/demo/lab_mcp.sh`** — cada acto por separado, para
   poder enseñarlo aislado. Sin auto-reinicio de Beelzebub.
3. **Arreglar `scripts/demo/lab_ssh.sh`** — al árbol y las credenciales de la persona viva, y añadir
   el paso de reúso del honeytoken robado en el acto 2.
4. **`docs/DEMO_CASO_DE_USO.md`** — el guion narrado, al estilo de `docs/DEMO_SSH.md` (que es «todo
   medido en vivo»): qué decir en cada acto y **qué señalar en cada vista de la consola**:
   - **Monitoreo** → mapa de ataques (la IP encendida) y el feed en vivo;
   - **Análisis** → línea de tiempo, **Atacantes** (la ficha del atacante con inteligencia externa),
     **Fases del ataque** (la kill chain con los tres protocolos), **Reglas de detección** (Sigma/
     YARA que dispararon, incluida la de reúso);
   - **Trampas** → **Cebos** y **Credenciales cebo** (verás la `AKIA…` sembrada por el MCP);
   - y el cierre: generar el **informe de compromiso** en PDF y enseñar la cadena de custodia
     (SHA-256) y la sección MITRE.
5. Todo **medido en vivo** antes de escribirlo en la doc. Si un número no sale, se arregla el guion
   y se vuelve a medir — nunca se escribe supuesto.

Opcional, si Iván lo pide: sembrar canarios **rastreados** en el árbol SSH (`engine/engine/
canary_tree.py`) para que también el cebo del `.env` dispare reúso, no sólo el del MCP.

## Cómo se trabaja aquí

- **No hay CI hasta el 1 de octubre** (cuota de GitHub Actions agotada): **verificación 100 % local,
  y el commit lo dice**. Nada se empuja al repo de código; la rama se adelanta en local con
  `git merge --ff-only`. La **wiki sí se empuja** y es pública: si archivas algo, recórtalo.
- **Hay otras sesiones de Claude en el repo.** Trabaja en tu copia, declárate en `COORDINACION.md`
  **insertando** (nunca reescribas el fichero entero), y pide el stack por turno.
- Skills que aplican: **`verificar-protocolo`** y **`verificar-en-vivo`** (tocas honeypots: qué se
  reinicia, qué tarda), **`medir-no-suponer`** (antes de escribir un número en la doc),
  **`guardarrail-en-rojo`** si añades una prueba (verla en ROJO contra su defecto). Y al cerrar:
  `registrar-plan` al aceptar el plan, **`destilar-leccion`** (con su `### Cosecha`) **antes** de
  `pendientes-roadmap`.

## Cómo sabes que has terminado

```bash
# 0. línea de tiempo limpia, o la historia se mezcla con el ruido
bash scripts/puesta_a_cero.sh --yes          # respalda, borra datos, conserva flocks y sensores

# 1. el arco entero, en ensayo (sin pausas)
AUTO=1 bash scripts/demo/lab_incidente.sh

# 2. que la historia se contó como UNA (sustituye la IP por la del host que ves en los eventos)
docker exec tartarus-postgres psql -U tartarus -d tartarus -c \
  "SELECT protocol, count(*) FROM events WHERE created_at > NOW()-INTERVAL '1 hour' GROUP BY protocol;"   # HTTP, MCP y SSH
docker exec tartarus-postgres psql -U tartarus -d tartarus -c \
  "SELECT array_length(sources,1) AS protos, kill_chain_stage, severity FROM kill_chain_traces ORDER BY last_seen DESC LIMIT 3;"  # 1 traza, ≥2 protos
docker exec tartarus-postgres psql -U tartarus -d tartarus -c \
  "SELECT rule_id, level FROM detections WHERE rule_id LIKE 'decoy_reuse%' OR rule_id LIKE '%credential%';"  # reúso + robo MCP

# 3. el informe de compromiso sale
curl -s -X POST 'http://localhost:9001/report/engagement?format=pdf&hours=1' -o /tmp/demo.pdf && ls -l /tmp/demo.pdf
```

Has terminado cuando: el arco corre de principio a fin sin tropezar; la consola enseña **una sola
kill chain** con los tres protocolos (no tres trazas sueltas); **salta la detección de reúso** del
honeytoken del MCP en la sesión SSH; y el informe sale en PDF con la cadena MITRE y la de custodia.
Y cuando `docs/DEMO_CASO_DE_USO.md` cuenta todo eso con los números que acabas de medir.

**Y en el navegador, no sólo en la BD**: abre la consola y recorre las tres vistas como lo haría el
público. Un fallo de interfaz no lo ve ninguna consulta de SQL, y esta demo es, sobre todo, lo que
se ve en pantalla.
