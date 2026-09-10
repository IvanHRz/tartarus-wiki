# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
> Actualizado: **10-sep-2026**, tras una jornada de **nueve ciclos de plan/ejecución** dedicada
> entera al SSH y al realismo del señuelo. Último commit `9f1d41a`, **nada subido**. El objetivo
> que viene lo eliges tú: el prompt trae los tres candidatos medidos.

---

Trabajo en **TARTARUS**, plataforma de decepción (honeypots) para respuesta a incidentes.

- Código: `/Users/ivanhuerta/Documents/Tartarus` (github.com/IvanHRz/Tartarus — **repo PÚBLICO**)
- Wiki: `/Users/ivanhuerta/Documents/Wikis/wiki-tartarus` (repo aparte, privado)
- Rama: `feature/tier0-deployment-readiness` · último commit: **`9f1d41a`** · **NO subido**

**Empieza leyendo `.agents/TRASPASO.md`**, que se reescribió al cerrar la sesión anterior y trae
los números medidos, cómo está montado lo nuevo y las trampas que ya costaron una sesión cada
una. Después `.agents/ROADMAP.md` (sección «PENDIENTES IMPLÍCITOS (auto)») para el pendiente.

## Cómo quiero que trabajes

- **Documentación en español llano**, cronológica, sin tecnicismos ni anglicismos innecesarios.
- **Todo plan aceptado se archiva verbatim** en `wiki/planes/YYYY-MM-DD.md` **antes** de
  ejecutarlo (skill `registrar-plan`).
- Actualiza `.agents/ROADMAP.md` y `.agents/BITACORA.md` (están en .gitignore) y deja entrada
  cronológica en `wiki/log.md`. Al cerrar, skill `pendientes-roadmap`.
- **Commits en español, sin `Co-Authored-By`**, excluyendo siempre `presentacion/`.
- **No subas a GitHub hasta que lo pida.**
- **Verifica en vivo y enséñame números.** Verifica **contenidos, no códigos de respuesta**: un
  200 con el cuerpo equivocado ya me costó una sesión entera.
- Cualquier borrado masivo en la base: **pregúntame antes**.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta solo si es ambiguo o
  destructivo.
- **Antes de decir que algo funciona, corre la skill `verificar-protocolo` y pega su salida.**
  **Mide antes de afirmar una causa** (skill `medir-no-suponer`).
- Al añadir, renombrar o quitar cualquier control de la consola: skill `sin-ambiguedad`
  (`python3 scripts/revisar_controles.py`). Un botón confuso casi nunca es solo confuso.

## Tres lecciones que ya costaron caro — vienen de sesiones distintas

1. **Comprueba antes de creer.** Dos veces un plan dio por existente algo que **nunca estuvo en
   git** (el respondedor ARP del sensor de ping, el laberinto anti-escáner del honeypot web): se
   habían probado en vivo sobre ficheros no versionados y se perdieron. Cuando yo —o el ROADMAP,
   o este prompt— diga «recuperar X» o «X dejó de funcionar», **compruébalo primero**
   (`git log --all -S'<símbolo>'`, `git grep` en todas las ramas, mirar dentro del contenedor).
   Si no aparece, el trabajo es escribirlo, no restaurarlo.
2. **Una regla en el prompt no es una garantía.** Al modelo se le pedía por escrito que nunca
   dijera «command not found» de un binario que existe, y lo decía igual: primero `apt` en Linux
   y el 10-sep `Get-ComputerInfo` en Windows. **O se resuelve en código, o se verifica la
   salida.** Nunca se da por bueno lo que dice el prompt.
3. **Mide antes de culpar a lo último que tocaste.** Ese mismo fallo de Windows parecía culpa de
   la caché de respuestas añadida esa misma tarde; la entrada de Redis tenía 23 minutos y al
   borrarla el modelo lo repitió. La caché lo congelaba, no lo causaba.

## Reglas de operación del stack

- Arranque: **`make up-quick`**. `make up` avisa y pide escribir BORRAR, pero **borra la base**
  si confirmas.
- Engine en `:9001` (puerto fantasma de OrbStack en el 9000), consola en `:8888`, SSH del
  honeypot en `:2222`, HTTP `:8880`, HTTPS `:8443`, MCP `:3001`.
- **El motor no lleva `--reload`** → `docker restart tartarus-engine` tras cualquier cambio en
  `engine/`.
- La consola es **bind mount** de `ui/src` → basta **Cmd+Shift+R**. Pero **`ui/nginx.conf` NO
  está montado**: hay que reconstruir con
  `docker compose -f docker-compose.yml -f docker-compose.dev-mac.yml up -d --build ui`.
- **Aplicar una persona reinicia Beelzebub con hasta 60 s de retraso** (vigilante de launchd):
  esperar a `pending:false` en `/services/restart-status` antes de abrir SSH.
- Tocar un parche de Go → `./scripts/build_beelzebub_hostkey.sh` + `docker compose … up -d
  beelzebub`. Van **6 parches en cadena** sobre Beelzebub v3.9.0.
- **Ojo al recrear contenedores**: Docker reasigna las IP. Tras cualquier `up -d --build`,
  comprueba que `curl -s localhost:8888/api/health` devuelve el **contenido** del engine.
- **Los YAML de `beelzebub/configurations/services/` NO están en git** (llevan la clave del
  proveedor y el repo es público). Lo que pruebes ahí se pierde si no hay script que lo
  regenere. Si necesitas leerlos, **enmascara la clave** en la salida.
- `beelzebub/configurations/personalities/portal-gobmx.yml` sale como modificado: **es trabajo
  en vivo mío**, no lo toques ni lo commitees.

## Lo que hay que correr antes de decir que algo funciona

```bash
python3 scripts/comparar_superficies.py ubuntu-server-24-04-lts-estandar   # → 0 / 46
python3 scripts/comparar_superficies.py windows-server                     # → 0 / 22
curl -s -X POST localhost:9001/personalities/<id>/probe/ssh-sweep \
     -H 'Content-Type: application/json' -d '{}'                           # → fallos=0
python3 scripts/revisar_controles.py                                       # → sin ambigüedades
cd engine && python3 -m pytest tests/ -q                                   # → 2.482 pasando, 10 saltadas
```

## Dónde lo dejamos

**El 10 de septiembre fue una jornada entera de SSH y realismo: nueve commits** (`039a800`..
`9f1d41a`), ninguno subido. En orden: la familia `weblogic` y que cada familia sirva **su**
página de error; cinco verbos más resueltos en código sobre un modelo de sistema compartido;
el comparador de superficies, que daba `10/10` falsos a las personas solo-web; tuberías y
redirecciones resueltas en código; los hitos de sesión (escalada, persistencia y **borrado de
rastro**, con el *timestomping* dejado ocurrir y registrado); Windows a la par de Linux más la
inyección de prompt como señal; la auditoría de realismo; la caché del passthrough (dos
atacantes veían máquinas distintas); y el control de calidad por fin visible en la consola.

Los números: **2.482 pruebas** (eran 2.242 al empezar el día), **35 verbos POSIX** en código
(eran 31) y **19 handlers de Windows**, **10 familias** de fachada web, **18 personas** (12 con
SSH), **6 parches de Go**, **7 skills** activas.

## Por dónde seguir — los tres candidatos, ya medidos

Elige tú; si no dices nada, empieza por el 1.

1. **El saneador tapa la mentira pero deja la salida vacía** (P2, esfuerzo M). Cuando el modelo
   niega un comando que existe, el programa tira esa respuesta — y lo que queda es **cadena
   vacía**, que delata casi igual: un `Get-ComputerInfo` real vuelca una tabla larga. Es
   contención, no arreglo, y afecta a las **dos** familias. O esos verbos se resuelven en código
   (como se hizo con `ps aux`, `systemctl`, `ip a`) o se reintenta la llamada cuando el saneador
   vacía la respuesta entera.
2. **Los aparatos de red mandan el 100 % al modelo** (P3, esfuerzo M). `cisco-ios` y `fortigate`
   no tienen ni un verbo determinista: cada `show` lo improvisa la inteligencia artificial, con
   el mismo problema que tenía Linux hasta agosto. Su «filesystem» es el volcado de
   configuración, y el editor visual ya lo trata así.
3. **El frente web** (P2, esfuerzo M). Del laboratorio de red-teamers de IA se cerró la parte
   SSH y quedó fuera la HTTP. Y el barrido web interno cubre ~53 rutas curadas cuando un
   `gobuster` real usa 4.614: o se usa la wordlist real, o la consola dice cuántas cubre.

Y dos cabos sueltos cortos: **`portal-gobmx.yml` sigue sirviendo el 404 de Apache** en vez del
de WebLogic, y **la cabecera `Server` de `weblogic` sigue provisional** (`WebLogic Server
12.2.1.4.0`) esperando la de mi captura de Fonacot — si la necesitas, pídemela.
