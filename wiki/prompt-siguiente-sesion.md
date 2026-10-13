---
tipo: guia
creado: 2026-09-11
actualizado: 2026-10-13
tags: [sesion, prompt]
---

# Prompt para la siguiente sesión — TARTARUS

> Copia todo lo que hay **debajo de la línea** y pégalo como primer mensaje de la conversación
> nueva. Se **reescribe** al cerrar cada sesión; no se acumula.
>
> **Reescrito el 13-oct-2026 (madrugada), y el cambio de fondo es este:** este prompt **ya no te
> dice en qué trabajar**. Las cuatro versiones anteriores nombraban un ancla concreta y las cuatro
> **caducaron antes de usarse** porque otra sesión ya la había cogido (`L-056`, `L-080`). Lo que
> queda escrito aquí es **cómo elegir** y **con qué no chocar**; la tarea la derivas del tablero,
> que es lo único que no se desfasa.
>
> Los `prompt-sesion-*.md` del repo de código (27 a esta fecha) son **historia**: no los uses como
> punto de partida sin comprobar antes en el tablero que su ancla sigue abierta.

---

Trabajas en TARTARUS (`~/Documents/Tartarus`), rama `feature/tier0-deployment-readiness`.
Quedan **10 días** para la presentación a ejecutivos (2026-10-23) y **cabe el 6 %** de la lista.

## 0 · Antes de tocar nada

1. `python3 scripts/tablero.py` — cuánto falta, **quién trabaja ahora** (lo dice la actividad de su
   copia, no la hora en que se declaró) y con quién chocarías. Léelo entero.
2. `CLAUDE.md` → `.agents/TRASPASO.md` (las notas `⏱` de arriba traen el estado **medido**, con el
   comando que lo produce) → `python3 scripts/tablero.py --bloque <el que elijas>`.
3. `scripts/sesion_paralela.sh nueva <nombre>` y **dentro de tu copia**:
   `git checkout --detach origin/feature/tier0-deployment-readiness`. La copia principal suele ir
   por detrás; si no la mueves, planificas contra un ROADMAP viejo. (Anoche eso mismo ofrecía
   cuatro anclas ya cerradas.)

## 1 · Elegir, con el criterio que no caduca

De «LO QUE CABE ANTES DEL 2026-10-23», coge el **P1 más alto** que:

- **(a)** no aparezca reclamado en «TRABAJANDO AHORA» ni en «¿SIGUEN AHÍ?», y
- **(b)** cuyo `tablero.py --ancla <ese>` **no** esté ya ✅ ni 🟡.

Confírmalo con `python3 scripts/revisar_sesiones.py`: **commits que no alcanzan ninguna rama son
trabajo invisible de otra copia**, y mirarlo antes de empezar es lo que impide hacer dos veces lo
mismo (`L-021`). Declárate en `.agents/COORDINACION.md` **por inserción** (bloque, reclamo,
no-toco, stack) y **empuja la declaración antes de tocar código**.

**Y mide el ancla antes de planificarla.** Las dos últimas sesiones encontraron que el titular era
**más grande que el hecho** —escrito por la sesión anterior— y lo corrigieron a la baja con el
número al lado. Un `--ancla` no es un diagnóstico: es la última vez que alguien miró.

## 2 · Estado al cerrar la madrugada del 13-oct

- **Cerradas anoche, por si el tablero tarda en reflejarlo:** los guiones de montaje de campo ya
  no reparten el repositorio (`#la-imagen-reparte-los-secretos`), el aparato de campo ya no lleva
  la llave de la flota (`#la-pi-lleva-el-secreto-de-la-flota`, y la vieja le da **401**), el
  guardarraíl del aislamiento ya mira también lo que vive en **ficheros**
  (`#el-trinquete-no-ve-los-ficheros`) y los labs sin cubrir tienen **orden y motivo**
  (`#labs-ir-mas-alla`).
- **🔴 Hay una copia viva sin declararse: `Tartarus-ruido`**, y a las 05:30 llevaba **2 commits
  fuera de toda rama** (iba por 1 veinte minutos antes, o sea que está trabajando). Por el nombre,
  lo más probable es que esté en `#pi-ruido-propio`, el nº 3 de la lista: **no cojas ese ancla sin
  mirar antes su sección**. Si la copia aparece abandonada, trae su trabajo **antes** de que se
  pierda — `python3 scripts/revisar_sesiones.py` imprime el commit exacto y el `git merge` que toca
  (no lo copies de aquí: cambia cada vez que commitea).
- **El stack está libre** (motor · base · Beelzebub · Raspberry). Se pide por turno, en tu sección.
- **Pendientes nuevos que dejó la madrugada, por si buscas algo corto:** que el motor central deje
  de aceptar la llave compartida para los sensores que no firman nunca; que la consola **avise**
  cuando un aparato de campo lleva minutos sin latir (recrear el motor del portátil lo deja mudo y
  nadie lo vigila); y poner en servicio un honeypot de WordPress, que es lo único que falta para
  cerrar el lab de wp2shell.

## 3 · Las cuatro cosas que esta madrugada volvió a confirmar

1. **Mide donde vive la capacidad, no donde está desplegado el servicio.** Un 404 contra el
   honeypot equivocado da un número cierto y una conclusión falsa.
2. **Escribe la detección contra el suceso GUARDADO**, no contra la documentación. Ocho reglas web
   de este repositorio vivieron muertas por no comprobar qué campos trae el emisor de verdad.
3. **Si el trabajo es RETIRAR algo** —una llave, un permiso—, la prueba no es que el servicio siga
   andando: es que **lo retirado ya no abra**, con una ruta sana en la misma pasada para que el
   rechazo no sea falta de ruta.
4. **Un detector se mide primero por lo que señala DE MÁS.** El primero que escribas marcará
   demasiado; cuenta cuántos antes de escribir la lista de pendientes (`L-085`).

## 4 · Cómo se cierra

`guardarrail-en-rojo` para cualquier prueba · `verificar-protocolo` si tocas lo que un honeypot
enseña · y la cadena del §10 de `CLAUDE.md`: `destilar-leccion` → `pendientes-roadmap` → cerrar el
ancla **en el corchete** → nota con `python3 scripts/podar_traspaso.py --nota <fichero> --aplicar`
→ **`cerrar-sesion`** (cierra tu declaración y republica «Ruta de los 25 días») → **parte de
avance** en el chat → `registrar-plan`.

Numera cualquier lección **desde `L-087`** (hasta `L-086` están usadas). Y antes de empujar:
`bash scripts/suite_en_produccion.sh` — «la suite pasa» no significa «el CI pasa».

**Números de referencia, medidos el 13-oct a las 05:00** (se sacan, no se citan: si tu pasada no
los da, mira qué cambió antes de culpar a tu trabajo):

```bash
cd engine && python3 -m pytest tests/ -q | tail -1     # 4.589 · 15 saltadas
bash scripts/suite_en_produccion.sh                    # 4.288 · 37, con el 3.12 de producción
python3 scripts/comparar_superficies.py                # 0 / 44 diferencias
python3 scripts/verificar_labs.py                      # 7 del todo · 4 parcial · 13 no · 5 n/a
python3 scripts/coste_arranque.py                      # ~113 KB de los 150.000 del trinquete
npx playwright test --list | tail -1                   # la cifra de la batería se saca, no se cita
```
