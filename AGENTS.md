# Schema — Wiki Tartarus

Wiki de conocimiento del proyecto **Tartarus** (deception & honeypots). Tú la mantienes; Iván la lee y dirige.

## Regla que define esta wiki

**El código es la fuente de verdad de *qué hace* el sistema. Esta wiki es la fuente de verdad de *por qué es así*.**

Nunca documentes aquí lo que un `grep` en el repo responde mejor. Si una página se puede volver obsoleta con un commit, o no debería existir, o debe declarar de qué commit habla.

## Reglas duras

1. **`.raw/repo` es inmutable desde esta wiki.** Es un symlink a `~/Documents/Tartarus`. Lees; nunca editas código desde aquí. Para tocar código, se abre el repo directamente (que tiene su propio `CLAUDE.md`).
2. **`wiki/`, `index.md`, `log.md` son tuyos.**
3. Toda afirmación técnica se ancla a un commit, PR, archivo o issue. Formato: `` `a1b2c3d` `` o `engine/parser.py:L88`.
4. Lee `index.md` antes de cualquier query.

## Estructura

```
.raw/repo/       symlink al repo Tartarus (git)
.raw/docs/       symlink a Tartarus/Docs
wiki/
  adr/          decisiones de arquitectura — el corazón de esta wiki
  postmortems/  incidentes y bugs no triviales, con causa raíz
  modulos/      un mapa por componente, anclado a commit
  releases/     una página por versión: qué cambió y por qué importa
  roadmap.md    hacia dónde va, con estado por ítem
  backlog.md    ideas con razonamiento, no implementadas
  sintesis.md   estado actual del proyecto en una página
index.md
log.md          bitácora de actualizaciones (append-only)
tools/git_digest.sh
```

## Frontmatter

```yaml
---
tipo: adr | postmortem | modulo | release | roadmap | backlog
creado: YYYY-MM-DD
actualizado: YYYY-MM-DD
commit_ref: a1b2c3d      # commit vigente cuando se escribió
tags: [beelzebub, sensors]
---
```

### ADR — `wiki/adr/NNNN-slug.md`
Numeración correlativa, nunca se reutiliza. Campos extra: `estado: propuesta | aceptada | reemplazada-por-NNNN | rechazada`.
Secciones fijas: **Contexto** → **Decisión** → **Alternativas descartadas (y por qué)** → **Consecuencias** (incluyendo las malas).
Una ADR **jamás se edita para cambiar de opinión**. Se marca `reemplazada-por` y se escribe una nueva. La historia del pensamiento es el activo.

### Postmortem — `wiki/postmortems/YYYY-MM-DD-slug.md`
Secciones: **Impacto** → **Timeline** → **Causa raíz** → **Fix** (con commit) → **Cómo lo detectamos** → **Qué lo habría prevenido**.
Sin culpables. Si el postmortem es de seguridad y toca a un cliente, va en `wiki-mabe`, no aquí.

### Módulo — `wiki/modulos/<componente>.md`
Obligatorio: `commit_ref` + una línea `> Verificado contra \`<commit>\` el <fecha>. Si el HEAD actual difiere mucho, esta página miente.`
Contenido: responsabilidad, entradas/salidas, invariantes, trampas conocidas. **No** listado de funciones.

## Operaciones

### `ingest`
Fuentes válidas: un commit range, un PR, un documento de `.raw/docs/`, una sesión de debugging, una conversación de diseño.
Flujo: leer → discutir hallazgos conmigo → escribir/actualizar páginas → actualizar `index.md` → `log.md`.

### `bitacora` (bitácora de actualizaciones)
`bash tools/git_digest.sh` te da los commits desde la última entrada de log.
Con eso: agrupa por tema, escribe **una entrada de log por tanda**, y decide qué merece página:
- ¿Hubo una decisión no obvia? → **ADR**
- ¿Se arregló algo que dolió? → **postmortem**
- ¿Cambió el contrato de un componente? → actualiza su **módulo** y su `commit_ref`
- ¿Cerró un ítem del roadmap? → mueve su estado, no lo borres
Un commit de `fix typo` no merece nada. Sé severo.

### `release <version>`
Genera `wiki/releases/<version>.md` desde el rango de commits del tag anterior a este. Enlaza a las ADRs y postmortems del periodo. Actualiza `roadmap.md` y `sintesis.md`.

### `query` / `lint`
`query`: index → páginas → respuesta con citas. Si el análisis es duradero, ofrécele archivarlo.
`lint`, en orden de valor:
1. **Páginas de módulo cuyo `commit_ref` quedó atrás** — las que mienten. `git log --oneline <commit_ref>..HEAD -- <ruta>` te dice si el componente cambió.
2. ADRs `aceptada` que el código contradice hoy
3. Ítems de roadmap completados y no marcados
4. Postmortems sin "qué lo habría prevenido"
5. Huérfanas, entidades sin página, cross-refs faltantes

## Nota: ADRs preexistentes

El repo ya tiene `.raw/docs/adr/`. **No las dupliques.** En el primer `ingest`, léelas, y para cada una crea en `wiki/adr/` una página que la referencie por ruta y añada lo que falte (alternativas descartadas, consecuencias observadas después). Si una ADR del repo quedó obsoleta, dilo aquí, no la edites allá.

## GitHub

- `log.md` referencia PRs como `#123`, issues como `#456`, commits como `` `a1b2c3d` `` (7 chars).
- Cuando una ADR se acepta, propón abrir un issue que la implemente y anota el número en la ADR.
- Cuando un ítem del roadmap se convierte en trabajo real, enlaza el issue.
- Esta wiki es su propio repo git. Commitea con `wiki: <op> <tema>` — `wiki: adr 0007 aislamiento de sensores`.

## Formato de log.md

```
## [2026-07-09] bitacora | sensors: aislamiento de red del honeypot
- Commits: `a1b2c3d`..`f7e8d9a` (11)
- Páginas: wiki/adr/0007-aislamiento-sensores.md (nueva), wiki/modulos/sensors.md (commit_ref → f7e8d9a)
- Nota: cambia el docker-compose de producción
```
Tipos: `ingest`, `bitacora`, `release`, `query`, `lint`, `refactor`.

## Múltiples agentes (Claude, Antigravity, Codex)

Este archivo es `AGENTS.md`. `CLAUDE.md` es un symlink a él. Cualquier agente lee el mismo schema — no hay dos verdades.

Reglas al operar con más de un agente:

1. **Un agente escribe a la vez.** La wiki es un repo git. Antes de empezar cualquier operación: `git status` debe estar limpio. Al terminar: commit. Si está sucio, otro agente dejó trabajo a medias — repórtalo, no lo pises.
2. **Commit atómico por operación.** Un `ingest` = un commit. Formato: `wiki: <op> <tema>`.
3. **Firma tu trabajo.** Cada entrada de `log.md` termina con `— <agente>` (`— claude`, `— antigravity`). Así `git blame` y el log cuentan la misma historia.
4. **Si Antigravity necesita reglas propias**, van en `GEMINI.md`, no aquí. `GEMINI.md` tiene precedencia sobre `AGENTS.md` en Antigravity y es invisible para los demás — úsalo solo para cosas específicas del IDE, nunca para reglas de contenido.
5. **Presupuesto de contexto:** este schema debe mantenerse por debajo de ~200 líneas. Si crece, extrae el detalle a una página de la wiki y déjalo enlazado.
## Graphify — la capa estructural

Hay **dos** fuentes de contexto y no se pisan:

| | Responde | Quién la escribe |
|---|---|---|
| **El grafo** (`.graph/graphify-out/`) | *qué llama a qué*, quién depende de quién, dónde está `X` | Tree-sitter, determinista |
| **La wiki** (`wiki/`) | *por qué* está así, qué se descartó, qué dolió | tú, con Iván |

Regla: **si la pregunta es estructural, consulta el grafo antes de leer código.** Nunca hagas `grep` a ciegas sobre `.raw/repo`.

```bash
bash tools/graph_query.sh "cómo se genera el reporte forense"   # BFS, sin LLM
graphify explain "EnrichmentCache" --graph .graph/graphify-out/graph.json
graphify affected "get_conn()" --graph .graph/graphify-out/graph.json   # qué rompo si toco esto
bash tools/graph_rebuild.sh                                      # tras cambios grandes
```

`.graph/graphify-out/GRAPH_REPORT.md` está en la bóveda: god nodes, comunidades y "surprising connections". **Léelo antes de escribir una página de módulo.** Los god nodes son, casi siempre, las páginas de módulo que faltan.

### Reglas del grafo

1. **Local por defecto.** `graph_rebuild.sh` corre `--code-only` + `cluster-only --no-label`: Tree-sitter y Leiden, cero llamadas al modelo. `--semantic` sí llama al LLM — úsalo solo con consentimiento explícito de Iván.
2. **`graph.json` no se versiona.** Se regenera en ~5 s. Solo `GRAPH_REPORT.md` va a git.
3. **`.graphifyignore` vive en el repo, no en la bóveda.** Es la única excepción a la inmutabilidad de `.raw/repo`: es configuración, como `.gitignore`. Si el grafo produce god nodes con nombres de una letra (`t`, `p`, `s()`), estás indexando código minificado — arregla el ignore, no el grafo.
4. **El grafo no sustituye a la wiki.** Sabe que `A` llama a `B`. No sabe por qué se rechazó la Opción B. Eso solo vive en las ADRs.

## Convenciones (kepano)

- **El nombre del archivo es el título.** Sin prefijos numéricos ni fechas, salvo donde el orden temporal *es* la identidad (postmortems, releases, casos).
- **Una nota, una idea.** Si una página necesita dos encabezados de nivel 1, son dos páginas.
- **Enlaces, no rutas.** `[[EnrichmentCache]]`, nunca `wiki/modulos/enrichment.md`.
- **Bottom-up.** No inventes taxonomías vacías. Una carpeta nace cuando ya hay 3 páginas que la piden.
- **Las propiedades viven en el frontmatter**, no en el cuerpo. Si un dato se va a filtrar o consultar, es una propiedad.
- **Plantillas en `Templates/`.** Úsalas al crear páginas; no improvises la estructura.
