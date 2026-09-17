---
tipo: guia
creado: 2026-09-11
actualizado: 2026-09-17
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **17-sep-2026 (madrugada)**, al cerrar el arranque de la consola y las dos
> intermitencias. PR **#25**, CI **verde en los seis trabajos** sobre `a6dd46b`.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PRIVADO**).
- Rama `feature/tier0-deployment-readiness`, PR **#25**. Motor Python/FastAPI en `engine/`,
  consola JS vanilla en `ui/src` (`main.js` + `index.html` + `css/tartarus.css`), Postgres en
  `db/init.sql`, honeypots Beelzebub. Motor en `localhost:9001`, consola en `:8888`.
- Wiki aparte: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo propio, privado).
- **HAY OTRA SESIÓN DE CLAUDE** en el mismo repo (la Raspberry / Ollama). Antes de tocar nada lee
  `.agents/COORDINACION.md` y anota ahí qué vas a editar. Reparto vigente: la otra lleva la Pi;
  ésta, el motor y la consola. **Nunca `git add -A`**: rutas explícitas siempre.

## Antes de nada, lee esto

`.agents/TRASPASO.md` — el mapa: los números que no hay que volver a medir, «Lo siguiente, por
orden» y **las trampas que ya costaron una sesión cada una** (son muchas y son reales; léelas).
Después `.agents/COORDINACION.md`, la cabecera de `.agents/ROADMAP.md` y las últimas entradas de
`.agents/BITACORA.md`.

**Y desconfía de las listas de pendientes, incluidas las mías.** El 16-sep se reconciliaron las
169 abiertas contra el código y **cuatro de cada cinco entradas comprobadas a mano estaban
desfasadas o eran falsas**. Hoy el plan va por **303 entradas, 103 cerradas y 200 abiertas**, con
ocho bloques nuevos con ancla. **Comprueba en el código antes de ponerte con algo**: lo vigila
`engine/tests/test_roadmap_coherente.py`, que exige que cada punto de «Lo siguiente» señale su
entrada con `{#ancla}` y que esa entrada no esté cerrada.

## Cómo quiero que trabajes

Documentación en **español llano y cronológico**. Todo plan aceptado se archiva verbatim en
`wiki/planes/YYYY-MM-DD.md` (skill `registrar-plan`) **antes** de ejecutarlo; al cerrar, skill
`pendientes-roadmap`. Commits en español, **sin `Co-Authored-By`**, excluyendo `presentacion/`.
El trabajo va al PR **#25** y **el CI se comprueba atado al SHA del commit**, no al último run de
la rama.

**Verifica en vivo y enséñame números — y verifica CONTENIDOS, no códigos de respuesta.** Y con
eso me refiero al RESULTADO, no al mecanismo: se han cerrado pendientes porque «el guion existe»
con el defecto intacto en disco.

**Cualquier borrado masivo en la base, pregúntame antes.** Avanza sin preguntar de más cuando la
dirección esté clara.

**Las skills del proyecto no son opcionales** (`.claude/skills/`, y están listadas en `CLAUDE.md`
§10). Las que más se disparan:

- `sin-ambiguedad` — al añadir, renombrar o quitar cualquier control (`python3
  scripts/revisar_controles.py`).
- **`consola-usable`** — al tocar `index.html`, cualquier JS de `ui/src/js/` o el CSS.
- **`perseguir-intermitente`** — **nueva, 17-sep**: cuando la batería falle una pasada y pase la
  siguiente, o un fallo no se reproduzca en solitario. Nada de «ya no lo vi».
- `verificar-protocolo` — tras tocar un protocolo, una persona, un prompt o un árbol. Pega su
  salida o no se dice que funciona.
- `medir-no-suponer` — antes de afirmar una causa o que algo está arreglado.

**Para cualquier cosa de interfaz, abre un navegador.** `npx playwright test` desde la raíz — 142
pruebas, 27 ficheros, y bloquea en el CI. **No reintenta, y es deliberado.** Tres reglas no
opcionales: exige el elemento visible, con caja y en el viewport (`e2e/apoyo.ts`); **no des por
bueno un spec que no hayas visto en ROJO**; y si una prueba comprueba que algo está vacío, siembra
en `flockQuieto()` — pero si tu prueba **siembra**, va a `flockDePruebas()`, y sus aserciones son
de **subconjunto**, nunca de igualdad.

**🔴 Antes de correr la batería, mira cuánto pesa su cliente.** No se limpia solo. Medido el
17-sep: con **9.592 sucesos y 107 IPs** en «Pruebas automáticas» daba **1-2 fallos por pasada** en
sitios distintos; vaciado, **142/142 tres veces seguidas**. Es también por lo que el CI está
verde y el portátil no. Está como P1 en el ROADMAP (`{#cliente-bateria-engorda}`) y es el punto 2
de «lo siguiente».

```bash
docker exec tartarus-postgres psql -U tartarus -d tartarus -tA -F' | ' -c "
SELECT f.name, COUNT(e.id), COUNT(DISTINCT e.source_ip)
FROM flocks f LEFT JOIN events e ON e.flock_id=f.id GROUP BY f.name ORDER BY 2 DESC;"
```

## Estado al abrir

- Python **3.249 pasando**, 12 saltadas. Navegador **142**, sin reintentos. CI verde sobre
  `a6dd46b`.
- Consola con sesión: `admin`, contraseña en `.env` (`TARTARUS_ADMIN_PASS`). **Segundo factor
  disponible y apagado**; la batería y los guiones entran con `servicio-local`
  (`TARTARUS_SERVICE_PASS`), que **nunca** puede tener 2FA.
- **6 flocks.** «Default Flock» es el mío, **630 sucesos** — los dos de «Pruebas automáticas» son
  de la batería: no los mires como datos.
- Sensores **9 de 10**; el caído es la Raspberry. Sigma **94 cargadas** (88 base + 6 de cebo, **0
  huérfanas**), 86 pueden disparar. YARA 439. Honeypots 10, **los diez con cerebro**.
- Motor en DeepSeek; la Pi en Ollama.

## Por dónde seguir

**Elige tú y dime por qué; es mi orden, no una orden.** El detalle, con su medición y el comando
que la produce, está en `.agents/ROADMAP.md`. Los P1 de arriba:

1. **El guion que monta la Raspberry nunca la enrola** (P1, **S**) `{#hardware-nunca-enrola}`.
   Lo más grave, y barato. `grep -i "enroll\|token\|flock"` sobre `setup-rpi.sh` y
   `push-to-rpi.sh` devuelve **cero** — comprobado el 17-sep. El aparato queda montado y sin
   dueño, y eso —no la red— explica que la Pi figure en `192.168.0.12` y responda en `10.99.0.1`.
   **Desbloquea `{#rpi-agente}` y `{#ip-real-atacante}`, que son otros dos P1.** Ojo: la Pi es
   área de la otra sesión; el guion es de aquí. Coordínalo.
2. **El cliente de la batería no se vacía nunca** (P1, **S**) `{#cliente-bateria-engorda}`. Va
   segundo por barato y porque **hace fiable todo lo demás**. Que `sesion.setup.ts` lo vacíe al
   empezar, o un `make e2e-limpio`. Vacía también «sin ruido»; **nunca** el Default Flock.
3. **Las credenciales cebo se comparan sin mirar de qué cliente son** (P1, **S**)
   `{#fuga-honey-creds}`. Fuga entre clientes: riesgo 98 y correo atribuidos al equivocado.
4. **El cebo corrupto está construido y no lo llama nadie** (P1, M) `{#cebo-corrupto-sin-cablear}`.
   Comprobado el 17-sep: `gen_cred_corrupta` y `es_corrupto` sólo los llama su propio test. Es la
   pieza de decepción contra agentes de IA más avanzada que hay y está desconectada.
5. **Un cliente no puede conseguir la imagen de Docker** (P1, M) `{#docker-sin-imagen}` y
   **el despliegue en la RPi5 en un paso** (P1, M) `{#rpi5-un-paso}`.
6. **La barra de notificaciones** (P1, M) `{#campos-sin-etiqueta}` — 13 campos, cero `<label>`, y
   guardar tras recargar **borra la contraseña SMTP**. Cuelga de `{#tokens-de-diseno}` (P1, L),
   que es el paraguas de todo lo de interfaz.
7. **La carga inicial ahoga lo que el operador pide a mano** (P1, M) `{#rafaga-carga-inicial}`.
   Medido: 18 cargadores de golpe, **33 peticiones en vuelo**, 6 conexiones por host, y un clic
   durante la carga tarda **15,2 s** para un endpoint de **7 ms**. Ya se probó y **descartó**
   estrangularlo en tandas; el arreglo bueno es **no pedir datos de paneles ocultos**.

**Bloqueado por la Raspberry** (offline desde el 11-sep): `{#rpi-agente}`, `{#ip-real-atacante}`.
Y **`{#hmac-exigir}` NO se puede decidir hoy** aunque parezca que sí: el contador de quién manda
sin firmar (`hmac_verifier._sin_firma`) es un **diccionario en memoria** que se borra en cada
reinicio, así que «cero» significa «nadie desde el último reinicio». Cierra antes
`{#contador-sin-firmar-en-memoria}`.
