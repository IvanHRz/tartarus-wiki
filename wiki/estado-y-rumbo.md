---
tipo: estado
creado: 2026-08-07
actualizado: 2026-08-07
commit_ref: PR#12 (rama feature/tier0-deployment-readiness)
---

# Estado y rumbo — qué tenemos, qué mejoramos, a dónde vamos

> Página de seguimiento para dirección/asesoría. Complementa [[sintesis]] (el proyecto en una página)
> y [[roadmap]] (el plan por fases). Estimados: **S ≈ 1 día · M ≈ 2–3 días · L ≈ 1 semana**.

## 1. Qué tenemos hecho (y verificado)

Todo lo de abajo está en **PR #12** (rama `feature/tier0-deployment-readiness`), con pruebas
automáticas (882) y verificación de punta a punta contra el sistema corriendo.

| Bloque | Qué resuelve | Estado |
|---|---|---|
| **Tier 0 — readiness** | Puerta de calidad antes de features: sana 11 puntos flojos; cierra el riesgo de "ingesta ciega" (#10) y añade prueba real de aislamiento entre clientes. | ✅ verde 11/11 |
| **Enrolamiento de sensores** | Un sensor se registra con un token y queda **auto-vinculado a su cliente**; borrar un cliente no deja sensores huérfanos. | ✅ |
| **Honeypot OT (Modbus)** | Trampa para redes **industriales** (SCADA/ICS): un intento de manipular el proceso = alerta crítica. | ✅ |
| **Detección de port-scan** | Alerta de "escaneo de puertos" de primera clase (reconocimiento/movimiento lateral). | ✅ |
| **Cebos consolidados** | Los documentos-trampa ahora **sí "llaman a casa"** al abrirse; credenciales señuelo únicas; migajas reconciliadas. | ✅ |
| **API para el SOC/SIEM** | Superficie **solo-lectura con token de menor privilegio** para que un SOC externo consuma alertas por cliente. | ✅ base (E-D1) |
| **Notificaciones** | Persistencia de configuración + campos de credenciales + "Ignorar IP" que de verdad silencia. | ✅ |
| **Consola reordenada** | Dashboard **centrado en alertas** (vistas Principal/Análisis/Gestión), inteligencia interna/externa honesta. | ✅ |

## 2. Qué estamos evaluando y mejorando (las 13 brechas)

Al probar la consola en vivo salieron **13 puntos** a validar/pulir. Agrupados por naturaleza:

### Aislamiento y confianza (prioridad de seguridad)
- **Fuga aparente entre clientes.** El backend **sí aísla**; lo que se veía "mezclado" en *Total de
  eventos / IPs* era un efecto visual de la UI (no repintaba el `0` de un cliente vacío). Se corrige
  fácil. **[S]** Pero hay dos vistas que sí salían sin filtrar (kill-chain, correlación) **[S–M]**, y
  —lo de fondo— la asignación *usuario→cliente* aún **no restringe** qué datos pide un usuario: es la
  pieza de aislamiento real para producción. **[M]**
- **Usuarios & Roles** poco claro (los roles no "hacen nada" con la autenticación apagada por
  defecto). Aclarar y, con lo anterior, hacer que la asignación de cliente sí limite el acceso. **[S–M]**

### Claridad de la consola (regla de oro: intuición)
- **El memo del analista** no guardaba al presionar Enter (solo al salir del campo) → se arregla en un
  punto y se resuelve en varias secciones a la vez. **[S]**
- **Session Correlation, Threat Intelligence, Remote Sensors, Breadcrumbs, Personalities**: potentes
  pero no se explican solas. Falta texto guía ("qué es, dónde se despliega, sensor ≠ cebo"), corregir
  un color de estado de sensores, y estados vacíos que se expliquen (mapas/hosts vacíos en LAN o sin
  escaneo). **[S cada una]**
- **Attack Map**: bueno, pero mejorar — al hacer **click** en un nodo debería abrir los **logs** de esa
  IP (hoy solo resalta el camino). **[M]**
- **Búsqueda de eventos**: enriquecerla para filtrados estratégicos (riesgo, táctica MITRE, texto). **[S–M]**
- **Reglas de detección**: en un ataque simulado saturaban la pantalla (cientos de reglas). Criterio:
  la plataforma muestra el **resumen** (cuántas, qué severidad, top); el detalle completo va al
  **reporte**. **[S–M]**

### Motor de IA del honeypot (seguridad + feature)
- **La llave de OpenAI** está fuera de git (subir el repo **no la filtra**), pero expuesta en el
  artefacto de despliegue → rotarla y tratarla como secreto en reposo. **[S–M]**
- **Panel de "prompts de persona"**: que desde la app se editen los prompts para que el señuelo actúe
  como **Windows/PowerShell** (no solo Ubuntu). La base ya existe (la persona Windows ya trae el
  prompt); falta el editor en la UI y conectar el SSH al LLM. **[L]**

### Validación end-to-end
- **Prueba de despliegue de cebos + alertas reales** (email/Telegram/SMS), en bucle hasta que todo
  jale. Requiere credenciales de los canales (y añadir el canal **SMS**, que hoy no existe). **[M]**

## 3. Próximas acciones (en orden)

1. **Documentación** (esta entrega): brief de cowork + estas wikis narrativas + el Tier F en el
   roadmap. **[S–M]**
2. **Quick-wins de claridad/seguridad UI**: la fuga cosmética + kill-chain/correlación, el memo, el
   color de sensores, los estados vacíos, y el texto guía de deception. **[S, alto impacto]**
3. **Validación en bucle de cebos + alertas** (email/Telegram/SMS). **[M, requiere credenciales]**
4. **Aislamiento fino MSSP** (restringir datos por usuario→cliente) + **rotar/asegurar la llave**. **[M]**
5. **Features mayores**: Attack Map con logs al click, detección concisa, búsqueda estratégica, y el
   **panel de prompts de persona**. **[M–L]**

## 4. Riesgos y dependencias
- La **validación de alertas** (email/SMS) depende de credenciales (App Password de Gmail, cuenta
  Twilio para SMS). Sin ellas, ese punto se planea pero no se cierra.
- El **despliegue en producción** de la API para el SOC necesita TLS real + hostname (hoy documentado
  como runbook en [[deploy-checklist]], falta la parte de infraestructura).
- **loaaan** (colaborador de hardware) aún no sube su despliegue físico; **dsantamaria** (asesoría)
  tiene lectura de esta wiki para dar seguimiento.

## Enlaces
[[sintesis]] · [[roadmap]] · [[deploy-checklist]] · [[brief-cowork]] · [[0011-dashboard-alerts-centric]] · [[0012-api-soc-menor-privilegio]]
