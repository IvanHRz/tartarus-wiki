---
tipo: sintesis
creado: 2026-07-09
actualizado: 2026-09-23
commit_ref: f854217 (PR#25, rama feature/tier0-deployment-readiness)
---

# TARTARUS — el proyecto en una página

> Para lectura rápida de dirección/asesoría. El detalle técnico vive en las [[modulos|páginas de
> módulo]], los ADRs y el `.agents/ROADMAP.md`. La bitácora de cambios está en `log.md`.

## Qué es TARTARUS

Una **plataforma de engaño para respuesta a incidentes (deception / IR)**: despliega *honeypots*
(trampas que imitan servidores reales) y *cebos* (tokens y migajas que se siembran en activos
reales), captura cómo actúa un atacante, le pone **riesgo** (0–100) y **contexto MITRE ATT&CK**, y lo
pinta en tiempo real en una consola propia (Canvas, sin frameworks). El diferenciador frente a
productos como Thinkst Canary: honeypots con **LLM** (respuestas creíbles), analítica inline
(Sigma/YARA), kill-chain automático y reportería forense — todo self-hosted.

Modelo de operación: **MSSP multi-cliente**. Cada cliente es un *flock* aislado; una sola consola de
dos niveles (madre = visión global; workspace = un cliente) los gobierna.

## Dónde estamos hoy

> **Foto del 20-sep-2026.** PR **#25**, CI verde en los seis trabajos. Suite **3.393 pasando** y
> 9 saltadas —todas declaradas—; batería de navegador **157** pruebas. El plan va por **360
> entradas, 117 cerradas**.

**Septiembre fue el mes de cerrar la seguridad propia**, y conviene decir qué significa eso: no
que aparecieran agujeros nuevos, sino que **se fueron a buscar y se midieron**. Lo que se cerró,
por familias:

- **Aislamiento entre clientes.** Una credencial cebo del cliente A disparaba la alerta más fuerte
  de la plataforma en un suceso del B. Un atacante que golpeaba a dos clientes producía **un solo
  rastro** de kill chain —con la evidencia de los dos dentro— y **la segunda víctima no generaba
  ninguno**. Y borrar una regla de atribución mandaba los sucesos a la vista del operador sin
  decirlo. Los tres, cerrados y verificados en vivo con A/B.
- **Roles.** Un `watcher` —el rol de sólo mirar— podía **silenciar una IP para todo el equipo**.
  Lo grave no fue la ruta: fue que el control que decía vigilarlo **eximía al router entero**.
- **Las dos puertas de máquina.** La ingesta de sensores y los tres shims de honeypot siguen
  abiertas **a propósito**, y ahora por primera vez se sabe a quién se dejaría fuera al cerrarlas.
  Ver [[0013-modo-aviso-antes-de-exigir]].

**Lo que esto le dice a dirección:** la plataforma pasó de «funciona» a «se puede demostrar que
funciona». Casi todo lo anterior se encontró **midiendo**, no revisando — y seis pruebas del
repositorio documentaban un agujero como correcto, dos de ellas porque **no se ejecutaban en
ningún entorno**. El activo que deja el mes no son los arreglos: es que ahora hay controles que
fallan cuando eso vuelve a pasar.

Detalle vivo: [[estado-y-rumbo]] · [[roadmap]] · [[0013-modo-aviso-antes-de-exigir]] ·
[[0012-api-soc-menor-privilegio]].

## La foto anterior (agosto)


El periodo pasado cerró el **salto a MSSP** (multi-tenancy: flocks, RBAC, dos niveles, acknowledge,
attack-map — todo con su ADR). Sobre esa base, la sesión más reciente entregó dos programas grandes,
hoy en **PR #12** (rama `feature/tier0-deployment-readiness`, suite 882 verde):

- **Tier 0 — "listo para desplegar".** Un *health-gate* re-ejecutable (`scripts/audit_gate.sh`) que
  sana 11 puntos flojos del proceso y del despliegue antes de meter features nuevas. **Aquí se cerró
  el riesgo crítico que nos frenaba** (la ingesta ciega, #10) y se puso un test real de aislamiento
  entre clientes. Ver [[2026-08-07-ingesta-amqp-ciega|postmortem #10]].
- **Tier E — sensores, despliegue y consola.** El arranque del modelo de campo: **enrolamiento** de
  sensores por token (auto-vinculados a su cliente), un **honeypot OT (Modbus)** para redes
  industriales, **detección de escaneo de puertos**, **consolidación de los cebos** (que antes no
  "llamaban a casa"), una **API de solo-lectura con token de menor privilegio** para que un SOC/SIEM
  consuma alertas, y un **dashboard reordenado** (centrado en alertas, como la referencia del mercado).

Detalle vivo: [[estado-y-rumbo]] · [[roadmap]] · [[0012-api-soc-menor-privilegio]] · [[0011-dashboard-alerts-centric]].

## Lo que cambió respecto a la foto anterior

La "tensión central" de julio era: *chasis sólido, falta demostrar que el motor enciende fiable.*
Eso ya se movió:

- **La ingesta ciega (#10) está detectada y con auto-reconexión** — `/health` avisa si deja de
  entrar tráfico. Ya no es un riesgo silencioso de "cliente ciego".
- **El aislamiento entre flocks ya tiene test de integración** contra Postgres real (antes solo
  había pruebas con base mockeada).
- **El conteo de detección es honesto**: la plataforma ya distingue reglas *cargadas* de las
  *aplicables al honeypot* (antes anunciaba un número inflado).

## A dónde vamos — la tensión de ahora

La tensión de agosto era *«chasis sólido, falta pulir la cabina y cerrar el aislamiento fino»*.
**El aislamiento fino se cerró** —los tres hilos de multi-cliente, el recorte por rol y la
atribución— y la cabina sigue pendiente. La de hoy es otra, y es más incómoda:

1. **Lo que falta para cerrar las dos puertas no es código: es otro equipo.** La firma de sensores
   y los shims esperan dos cosas de la Raspberry y de la configuración de Beelzebub. Una decisión
   que depende de otro se queda esperando si nadie la empuja; por eso quedan en estado
   **👁 en monitoreo**, con su criterio escrito. Ver [[0013-modo-aviso-antes-de-exigir]].
2. **La batería de pruebas de interfaz no es fiable, y eso cuesta horas.** 155·153·157 en tres
   pasadas: cada fallo obliga a descartar antes de poder creerse nada. Es el impuesto que paga
   todo lo demás, y es el P1 con más retorno.
3. **Un cliente todavía no puede desplegar solo.** No hay imagen de Docker publicada, el despliegue
   en la Raspberry no es de un paso, y faltan los dos modos nuevos (Tailscale e instalador con
   token). Es lo que separa «lo desplegamos nosotros» de «producto».
4. **~~La consola sigue sin sistema de diseño.~~ Hecho el 22-sep-2026.** De 13 variables a **55**,
   con escalas de espaciado, radios, tipografía y capas; los colores a pelo bajaron de 289 usos a
   **104** y los `style=` en línea de 398 a **335**. Todo **con cambio visual cero demostrado**: hay
   un arnés que compara 45 propiedades calculadas de 25 vistas con tolerancia cero. Y lo deja
   vigilado —`scripts/revisar_tokens.py`, once cifras derivadas—, que es lo que no existía: antes no
   había ni un linter de CSS ni una prueba que contara variables.
   De paso salieron **cuatro defectos visibles** que nadie veía, todos de variables CSS usadas sin
   valor de respaldo —que no es «el valor por defecto» sino una declaración inválida que el
   navegador descarta entera—: dos paneles transparentes, un enlace que salía gris como texto
   normal, 17 nombres de equipo apagados y cuatro errores en un rojo ajeno a la paleta.
   Lo que queda es decisión de producto, no deuda: [[prompt-sesion-diseno-2]].

## En una frase

**TARTARUS ya no sólo funciona: se puede demostrar que funciona, y cuando deja de hacerlo hay un
control que lo dice.** Lo que queda es producto —que un cliente lo despliegue solo y que la consola
se explique sola— y una deuda de fiabilidad en las pruebas de interfaz que encarece todo lo demás.

Y una lección que ya va por su cuarta aparición y merece decirse aquí: **un comprobador que mira
donde la cosa estaba se queda verde cuando la cosa se mueve.** No falla — enmudece, que es peor,
porque además tranquiliza. Pasó cuatro veces en un solo día de refactor, y es `L-047` (nació `L-040`; se renumeró el 23-sep al fusionar).

## Enlaces
- [[estado-y-rumbo]] — qué tenemos, qué se evalúa/mejora, próximas acciones con estimados.
- [[roadmap]] — el plan por fases. · [[deploy-checklist]] — qué es "desplegable".
- [[brief-cowork]] — onboarding para quien llega a ayudar a dirigir.
