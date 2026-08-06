---
title: "NeuralGraph — Force-Directed Attack Visualization"
tags: [tartarus, component, canvas, frontend, visualization, javascript]
status: active
date: 2026-03-13
file: ui/src/js/graph.js
lines: ~650
---

# NeuralGraph — Force-Directed Attack Visualization

## Propósito

Visualización en tiempo real del panorama de ataque usando HTML5 Canvas puro y `requestAnimationFrame`. Sin librerías de grafos (D3, Cytoscape, vis.js) — restricción explícita del [[ADR-001 Canvas Only UI]].

---

## Arquitectura

### Modelo de Datos

**Nodos** (`graph.nodes: Map<id, node>`):
```js
{
    id: "192.168.1.100",  // IP o "SSH:22"
    type: "attacker" | "service",
    risk: 75,             // max risk score observado
    x, y,                 // posición actual
    vx, vy,               // velocidad (physics)
    radius: 14 | 22,      // attacker | service
    eventCount: 42,
    label: "192.168.1.100",
    pinned: false,        // service nodes = true
    pulsePhase: 1.23,     // fase de animación glow
    lastHit: 1712345678,  // timestamp del último evento (para flash)
}
```

**Edges** (`graph.edges: Map<"src->tgt", edge>`):
```js
{
    source: "192.168.1.100",
    target: "SSH:22",
    weight: 15,           // event count (determina grosor)
    maxRisk: 75,
}
```

**Pulsos** (`graph.pulses: Array`):
```js
{
    srcId: "192.168.1.100",
    tgtId: "SSH:22",
    risk: 75,
    startTime: performance.now(),
    // progress calculado como (now - startTime) / PULSE_LIFE
}
```

---

## Physics — Force-Directed Layout

Implementado en JS puro. Se ejecuta en cada frame antes del render.

### Fuerzas

| Fuerza | Tipo | Constante |
|--------|------|-----------|
| Repulsión entre nodos | Coulomb `F = K/d²` | `REPULSION = 8000` |
| Atracción en edges | Spring `F = k(d - L₀)` | `SPRING_K = 0.04`, `IDEAL_LEN = 160px` |
| Gravedad central | `F = G * (center - pos)` | `GRAVITY = 0.02` |
| Damping | `v *= D` cada frame | `DAMPING = 0.82` |

### Convergencia
Los nodos convergen cuando la velocidad es tan pequeña que el damping la hace tender a 0. Los **service nodes son `pinned: true`** — no se mueven por física, solo por drag del usuario.

---

## Rendering

### Orden de capas (Z-index Canvas)
1. **Edges** — líneas con gradiente de color según `maxRisk`
2. **Arrowheads** — flechas en el extremo del edge (dirección attacker → service)
3. **Pulsos viajeros** — puntos que viajan a lo largo del edge en 700ms
4. **Nodos** — círculos con texto, glow para high-risk
5. **Tooltip** — overlay flotante en hover

### Colores por Risk Level
| Score | Color | CSS |
|-------|-------|-----|
| ≥ 80 | Rojo | `#ef4444` (critical) |
| ≥ 60 | Naranja | `#f97316` (high) |
| ≥ 30 | Amarillo | `#eab308` (medium) |
| < 30 | Verde | `#22c55e` (low) |
| Service | Azul | `#3b82f6` |

### Efectos Visuales
- **Glow crítico (risk ≥ 80)**: `shadowBlur` animado con `sin(ts * 0.005 + phase)` — rango 10–26px
- **Glow alto (risk 60–79)**: `shadowBlur` estático de 7px — distinguible sin saturar
- **Flash de hit**: al llegar un evento nuevo, el nodo recibe `lastHit = now`. Por 600ms tiene `shadowBlur = 28`.
- **Pulse viajero**: punto de radio 4px con shadow del color del risk, animado en t=[0,1] a lo largo del edge
- **Kick de velocidad**: nodo atacante recibe `vx/vy += random * 4` para efecto de "sacudida"
- **Label pill**: texto bajo el nodo con fondo semitransparente `rgba(13,17,23,0.72)` + `roundRect` — legible sobre edges

---

## WebSocket Integration

```js
connectWS() {
    this.ws = new WebSocket(`ws://${location.host}/api/ws/events`);
    ws.onmessage = (evt) => {
        const msg = JSON.parse(evt.data);
        if (msg.type === 'event') this._handleEvent(msg.data);
    };
    ws.onclose = () => setTimeout(() => this.connectWS(), 4000);  // auto-reconnect
}
```

### Seeding Histórico
Al inicializar, llama `/api/sessions` para poblar el grafo con sesiones existentes:
```js
graph.seedFromSessions(sessions);
// sessions: [{ ip, max_risk, ports_targeted, event_count }]
```

---

## Interactividad

| Acción | Resultado |
|--------|-----------|
| Hover sobre nodo | Tooltip con IP, events, max risk |
| Click en nodo `attacker` | `showIntelPopoverAt(ip, x, y)` → intel Shodan/GeoIP |
| Drag nodo | Mueve el nodo, libera la física |
| Scroll wheel | Zoom hacia/desde cursor (scale 0.2–5.0) |
| Mouse drag (fondo) | Pan del canvas |

---

## Inicialización en main.js

```js
import { NeuralGraph } from './graph.js';

async function initGraph() {
    const canvas = document.getElementById('neuralGraph');
    graph = new NeuralGraph(canvas, (ip, _node, screenX, screenY) => {
        showIntelPopoverAt(ip, screenX, screenY);
    });
    const { sessions } = await fetch('/api/sessions').then(r => r.json());
    graph.seedFromSessions(sessions);
    graph.connectWS();
}
```

---

## Constantes de Tuning

| Constante | Valor | Efecto |
|-----------|-------|--------|
| `REPULSION` | 8000 | Mayor = nodos más separados |
| `SPRING_K` | 0.04 | Mayor = edges más tensos (nodos más juntos) |
| `IDEAL_LEN` | 160px | Longitud "natural" de un edge |
| `GRAVITY` | 0.02 | Mayor = todo más cerca del centro |
| `DAMPING` | 0.82 | Menor = convergencia más rápida |
| `PULSE_SPEED` | 0.0025 | Velocidad del pulso viajero |
| `PULSE_LIFE` | 700ms | Duración del pulso viajero |

---

## HiDPI / Retina (v0.5.1)

> [!important] Canvas Sharp en Apple Silicon M4
> Sin escalar, Canvas renderiza en píxeles CSS → borroso en pantallas Retina (DPR 2x).
>
> Fix aplicado en `_resize()`:
> ```js
> const dpr = window.devicePixelRatio || 1;
> canvas.style.width  = w + 'px';   // CSS (logical)
> canvas.style.height = h + 'px';
> canvas.width  = Math.round(w * dpr);  // físico (sharp)
> canvas.height = Math.round(h * dpr);
> ```
> En `_render()`: `ctx.scale(dpr, dpr)` antes de cualquier dibujo.
> Todas las coordenadas de física y render usan `_logW`/`_logH` (píxeles lógicos).

## Layout (v0.5.1)

**Antes**: grid `1fr 420px` side-by-side, altura fija 540px compartida.
**Ahora**: flex column — Graph (ancho completo, 580px) arriba, Live Events (ancho completo, max 300px) abajo.

---

## Relacionado

- [[ws_manager]] — Fuente de eventos en tiempo real
- [[ADR-001 Canvas Only UI]]
- [[Fase 4 Neural Graph + WebSocket]]
