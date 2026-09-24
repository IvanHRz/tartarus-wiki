---
tipo: guia
creado: 2026-09-24
actualizado: 2026-09-24
tags: [sesion, prompt, http, fachada, web]
---

# Prompt para la sesión de la fachada web — HTTP y HTTPS

> Copia todo lo que hay debajo de la línea y pégalo como primer mensaje de la conversación nueva.
>
> **Por qué éste.** Iván configuró una portada en «Configurar honeypot · HTTP», la consola **no le
> dijo qué página había copiado**, y al abrir el editor de la persona le apareció **otra URL
> distinta** de una selección pasada. Al medirlo salieron **cinco cosas**, ninguna registrada hasta
> el 24-sep, y una de ellas es que el guardarraíl de la fachada **está verde sobre la portada**.
>
> **Se puede correr a la vez que** las demás: este frente es `engine/engine/web_facade.py`,
> `web_honeypot_router.py` y el bloque web de la consola. No toca la shell SSH ni el motor de
> notificaciones.
>
> Las cifras de abajo están **medidas el 24-sep-2026 de madrugada**, y cada una va con el comando
> que la produce. **Remídelas antes de planificar sobre ellas** — no las heredes.

---

Trabajo en TARTARUS, plataforma de decepción (honeypots) para respuesta a incidentes.

Código: `~/Documents/Tartarus` (github.com/IvanHRz/Tartarus — repo **privado**).
Rama `feature/tier0-deployment-readiness`, PR #25. Motor Python/FastAPI en `engine/`, consola JS
vanilla en `ui/src`, Postgres en `db/init.sql`, honeypots Beelzebub. Motor en `localhost:9001`.
Wiki aparte: `~/Documents/Wikis/wiki-tartarus` (repo propio, **público**).

**Antes de tocar nada**, en este orden: `CLAUDE.md` → `.agents/TRASPASO.md` →
`.agents/COORDINACION.md` (hay más sesiones en este repo; **declárate con la plantilla del
principio** y comprueba con `python3 scripts/revisar_sesiones.py`) → `.agents/ROADMAP.md`.

**Abre tu propia copia**: `scripts/sesion_paralela.sh nueva http`. No trabajes en
`Tartarus-diseno`, que está para retirarse.

## El encargo: primero AUDITAR, y sólo entonces tocar

Es decisión de Iván y va en este orden a propósito. Las cinco entradas de abajo se registraron
**sin arreglar nada**, para que la sesión que las coja las remida y decida, en vez de heredar un
diagnóstico. **Lo primero es correr esto y comparar con lo que dicen las entradas:**

```bash
python3 scripts/comparar_superficies.py portal-gobmx --api http://localhost:9001
curl -s  http://localhost:8880/  | wc -c
curl -sk https://localhost:8443/ | wc -c
curl -s  http://localhost:8880/.env           | wc -c
curl -s  http://localhost:8880/noexiste-jamas | wc -c
```

Si alguna cifra no cuadra, **eso es el primer hallazgo de la sesión**, no un error de la entrada.

### 1. `#portada-con-tres-respuestas` (P1·M) — la que Iván pidió

«¿Cuál es la portada de este honeypot?» tiene **tres** respuestas y ninguna pantalla nombra a las
otras:

| quién lo dice | qué dice | dónde se ve |
|---|---|---|
| `.clones/http-80.clone.json` | `https://www.ine.mx/` | «🟢 Portada clonada desde…» del modal |
| la persona, `protocols.http.portada_url` | `https://mujeresdeaccion.pan.org.mx/` | «📎 Página de referencia» del editor |
| el barrido de la consola, fila `/` | 863 B, regla `estatica` | la tabla del banco de pruebas |

Y lo que se sirve son **1.080.690 B**, o sea el primero.

**No son tres defectos: son tres cosas distintas que en pantalla se llaman igual.** El sidecar es
el ESTADO, `portada_url` es una SUGERENCIA —el código ya la trata así al prellenar el campo del
modal (`main.js:6879`)— y el 863 es lo que el banco sirve sin clon.

**Decidido con Iván: manda lo aplicado.** `portada_url` se queda como sugerencia, y el editor tiene
que decir **las dos cosas** —«aplicada: X · tú sugieres Y»— en vez de enseñar sólo la sugerencia
como si fuera el estado. Ojo: esa sugerencia lleva **dos semanas** desfasada y la misma URL está en
otra persona distinta (`portal-gobmx-portal-gob-mx-java-jsf`), así que no es un accidente de una.

### 2. `#el-barrido-miente-en-la-portada` (P1·S) — la que da más miedo

`comparar_superficies.py` da **0 / 19** en web… y la única fila que difiere es `/`:

```
/   200/863B   200/1080690B   portada clonada (1,080,690 B) — excepción conocida
```

`comparar_superficies.py:291-297`: si la fila trae `nota`, la diferencia **no cuenta como fallo**.
O sea que el guardarraíl más caro de la fachada está en verde sobre **la ruta que ve primero
cualquiera**, y la excusa se escribió a sabiendas.

Es `L-047` otra vez: un comprobador que mira donde ya estaba la cosa. El criterio `0 / N` no puede
declararse cumplido saltándose la portada.

### 3. `#las-dos-404-del-mismo-host` (P2·S) — el delator

259 B para las rutas de una lista estática, 448 B para el resto. **Un Apache real devuelve una.**
Dos tamaños no dicen «no existe»: dicen «aquí hay una lista de rutas que alguien consideró
sospechosas», que es justo lo que un señuelo no puede contar de sí mismo.

Sale en el propio barrido de la consola —columnas `estatica` y `escaner`— y nada lo marca.
**El criterio no es «que coincidan» sino que haya UNA.** (El 10-sep ya se cazó una pareja parecida,
259 contra 257; aquélla se arregló y ésta es otra.)

### 4. `#https-sin-portada` (P2·S)

`:8880` sirve el clon de 1 MB; `:8443` **no tiene clon** y sirve 1.009 B de otra cosa. Clonar es
por servicio y `https-443` se quedó fuera sin que nada lo dijera. **Lo que hay que decidir** —y por
eso no es XS— es si una portada debe aplicarse a las dos fachadas del mismo despliegue o si son dos
honeypots aparte a propósito y lo que falta es que la consola lo diga.

### 5. `#rutas-por-fichero-sin-cablear` (P3·XS)

`web_facade.py:985` declara qué rutas lleva cada fachada y **fuera de `engine/tests/` no la llama
nadie**. O se cablea o se retira.

> **Lo que se miró y NO es un defecto**, para que nadie lo persiga: el «9 deterministas /
> 11 reales» del mapa de rutas son dos categorías distintas, no un descuadre.

## Lo que YA existe y no hay que inventar

- **`scripts/comparar_superficies.py` tiene modo web desde el 10-sep-2026.** Compara las tres
  superficies —mapa de rutas del editor, barrido del banco, honeypot desplegado— **ruta por ruta y
  con status Y tamaño**, criterio `0 / N`. Lo que le falta no es capacidad: es que deje de excusar
  la portada.
- **La skill `verificar-protocolo` es obligatoria** antes de decir que un protocolo funciona, y ya
  cubre web explícitamente. Su cabecera documenta este mismo síntoma: «en HTTP, `/` daba 863 bytes
  en el probe y 478.978 en el real».
- **`web_facade.py:555`** es la fuente única del mapa de rutas del editor y de la wordlist del
  barrido, «para que no se dupliquen ni se desincronicen». Si algo diverge, empieza por ahí.
- Nueve personas declaran web: `portal-gobmx`, `wordpress`, `apache-php`, `nginx-webapp`,
  `tomcat-spring`, `jenkins`, `synology`, `fortigate` y `portal-gobmx-portal-gob-mx-java-jsf`.
  **Repite la comparación con cada una afectada, no sólo con una.**

## Las trampas de este frente

1. **Aplicar una persona reinicia Beelzebub** con hasta 60 s de retraso (lo hace un vigilante) y
   **corta las sesiones SSH abiertas**. Espera a `restart-status` antes de medir.
2. **`L-048` — el arnés visual puede dar CERO por la caché del navegador.** Si tocas la consola y
   `instantanea_visual` sale verde sospechosamente rápido, comprueba que `hojaAlDia` corrió.
3. **`L-047` — antes de mover un valor, `grep` del nombre por `scripts/` y `engine/tests/`.** Aquí
   hay comprobadores que leen ficheros con expresiones regulares y **enmudecen** en vez de fallar.
4. **`L-051` — desnuda los comentarios antes de afirmar sobre un fichero.** Este repo cita su
   propio código en la prosa, y comentar una línea la deja intacta para un `grep`.
5. **El gancho de pre-commit NO corre la batería si tu commit no lleva un `.py`.** Corre la suite a
   mano antes de cada commit de consola.
6. **El barrido gasta modelo.** El profundo de 4.743 rutas hizo 18 llamadas a DeepSeek; el resto lo
   cortó el gate. No lo repitas en bucle sin mirar el contador que imprime.
7. **`:8888` no sirve tu copia**: sirve la de `~/Documents/Tartarus`. Tu copia tendrá su puerto.

## Cómo se trabaja aquí

- **Verifica en vivo y enseña números**, y verifica **contenidos**, no códigos de respuesta.
- **Guardarraíl en rojo**: ninguna prueba cuenta hasta verla fallar contra su defecto. Y comprueba
  **la causa del color**.
- **Derivado, no copiado**: las listas se calculan desde el código, no se mantienen a mano.
- **Nunca `git add -A`**: rutas explícitas. Commits en español, sin `Co-Authored-By`, excluyendo
  `presentacion/`. El título dice **qué estaba mal**.
- **Nada de borrados masivos en la base sin preguntar a Iván**, y no toques
  `beelzebub/configurations/personalities/portal-gobmx.yml` sin avisar: es donde está el trabajo
  en vivo de esta auditoría.
- **🔒 CONGELACIÓN: no se empuja nada al repo de código hasta el 1 de octubre.** Hay un gancho
  `pre-push` que lo impide y caduca solo. **No hay CI**, así que toda la verificación es local y el
  commit tiene que decirlo. La wiki **sí** se empuja.
- **Antes de numerar una lección: `python3 scripts/destilar_leccion.py --siguiente`**, que lee las
  once copias. Esto ya chocó tres veces en un día.
- Avanza sin preguntar de más cuando la dirección esté clara; pregunta sólo si es ambiguo o
  destructivo. Documentación en español claro, sin anglicismos.

## Verificación

```bash
cd engine && python3 -m pytest tests/ -q      # 3.817 pasando · 11 saltadas al 24-sep
python3 scripts/comparar_superficies.py <persona> --api http://localhost:9001   # criterio 0 / N
TARTARUS_UI_URL=http://localhost:88XX npx playwright test
python3 scripts/revisar_tokens.py             # 0 de 11 en rojo
python3 scripts/revisar_controles.py && python3 scripts/validate_docs.py
scripts/base_limpia.sh                        # 3 fallos, los tres con ancla desde el 21-sep
```

Trinquetes vigentes: `revisar_tokens.py::hex_a_pelo` **0** · `::fuera_de_escala` **61** ·
`::estilos_en_linea` **262**. **Ninguno sube.**

**Y en el navegador, que es donde esto se ve.** Abre la consola, configura una portada, ciérrala,
vuelve a abrirla y abre el editor de la persona. Si las dos pantallas siguen contando historias
distintas, no está arreglado — por muchas pruebas verdes que haya.

## Lo que hay fuera de este frente, para no pisarlo

Hay más sesiones con copia propia. Mira `.agents/COORDINACION.md` antes de reclamar nada: el shell
SSH, el secreto por sensor y el escáner de C5 han estado activos estos días.

Al cerrar: skill `destilar-leccion` (**`--siguiente` antes de numerar**), luego
`pendientes-roadmap`, y `registrar-plan` cuando Iván acepte el plan. **La wiki es pública: lee el
plan antes de pegarlo ahí.**
