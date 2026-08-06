---
tipo: modulo
creado: 2026-08-06
actualizado: 2026-08-06
commit_ref: 0085c31
tags: [reporting, vra, engagement, export]
---

# Módulo: Reporting

> Verificado contra `0085c31` el 2026-08-06. Si el HEAD actual difiere mucho, esta página miente.
> Comprobar: `bash tools/stale_modules.sh`

## Responsabilidad

Generar el reporte de engagement (HTML/PDF) para el cliente: resumen de amenazas (VRA),
atacantes, kill chain, IOCs. `engine/engine/report_router.py`. God-node
`_generate_engagement_report_impl()` (30 edges).

## Entradas / salidas

- **In:** eventos, VRA (`vra_correlator`), detecciones, kill-chain — el **100%** del
  histórico (los reportes NO aplican el filtro acknowledge; ver [[0004-acknowledge-limpieza-de-ruido]]).
- **Out:** documento HTML/PDF. `POST /report/engagement?format=html&lang=es`.

## Invariantes

- **El forense ve todo.** A diferencia de las vistas de pantalla, el reporte nunca filtra
  por `acknowledged` ni por ventana — es el registro completo. Verificado: reconocer una IP
  la saca del feed pero el export sigue trayéndola.

## Trampas conocidas

> [!warning] El generador de reportes lee `remote_sensors` (la tabla muerta)
> `docs/generate_report.py:553` lista `remote_sensors` como "Sensores RPi registrados".
> La tabla tiene 0 filas pero el `DROP TABLE` que prescribe [[0001-arquitectura-de-sensores]]
> **rompería la generación de reportes** si no se actualiza esta ruta primero. El audit §2
> de esa ADR omitió este consumidor.

## Grafo

God-node: `_generate_engagement_report_impl()` (30), `make_docx`, `EngagementReportModel`
(34 — el modelo de datos del reporte). `bash tools/graph_query.sh "cómo se genera el reporte forense"`.
