---
tipo: adr
estado: aceptada
creado: 2026-03-10
actualizado: 2026-07-30
commit_ref: 0085c31
adr_original: .raw/vault-legacy/Knowledge Base/Decisions/ADR-002 RabbitMQ Event Bus.md
tags: [rabbitmq, amqp, consumer, ingesta]
bugs: ["#10"]
---

# ADR-0008 — RabbitMQ como event bus

> Destilada del vault legacy (marzo 2026, v0.5.0). La decisión es sólida; **su promesa
> central ("los eventos nunca se pierden") es falsa hoy** — el código la contradice por
> dos vías.

## Contexto

Beelzebub genera eventos a ritmo variable (ráfagas en brute-force). El consumer debe
procesarlos de forma asíncrona sin bloquear el honeypot.

## Decisión

**RabbitMQ como broker** entre Beelzebub y el consumer Python.

- Cola `event`, un solo consumer. Beelzebub publica JSON vía AMQP; el consumer
  (`engine/engine/consumer.py`) procesa asíncrono. Desacopla honeypot de pipeline.
  Management UI en `:15672`.

## Alternativas descartadas

| Opción | Por qué se rechazó |
|---|---|
| Escritura directa Beelzebub → Postgres | Acopla el honeypot al ritmo de la DB; una ráfaga bloquearía la captura. El broker absorbe el burst. |
| Redis Streams / Kafka | Sobredimensionado para una instancia; RabbitMQ ya estaba y la Management UI ayuda a depurar. |

## Consecuencias

> [!danger] La promesa "los eventos nunca se pierden" es falsa
> La ADR original afirma *"Events are never lost (RabbitMQ persistence)"*. Contra
> `0085c31` eso **no se cumple**, por dos razones independientes:
>
> 1. **La cola es no-durable.** `consumer.py:444` → `declare_queue(QUEUE_NAME, durable=False)`.
>    Si el broker se reinicia, los mensajes en cola se pierden. (Beelzebub crea la cola
>    non-durable; el consumer se adapta con `durable=False` — lección aprendida ya
>    registrada en la memoria del proyecto.)
> 2. **El canal AMQP de Beelzebub se cae por inactividad** (issue `#10`): los honeypots
>    capturan pero dejan de publicar (`channel/connection is not open`), y los eventos se
>    pierden **en silencio**. El dashboard muestra 0 — indistinguible de "no me atacan".

Ninguna de las dos invalida elegir RabbitMQ; invalidan la frase de que el bus *por sí
solo* garantiza durabilidad. La garantía real exige: cola durable + reconexión del
publisher + healthcheck de ingesta. Ver `#10`.

## Estado real — verificado contra `0085c31` (2026-07-30)

El bus funciona: con el canal sano, un ataque real de 116 sondas produce ~128 eventos y
427 detecciones. El problema es la **fiabilidad de la conexión**, no el diseño del bus.
`#10` es bloqueante de despliegue y candidato a [[postmortems|postmortem]] cuando se
arregle.

## Enlaces

- [[0005-attack-map-contexto-de-despliegue]] — consume los eventos de este bus
- [[roadmap]] — `#10` en "bloqueantes de despliegue"
