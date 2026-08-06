---
title: Adding a Honeypot Service
tags:
  - runbook
  - honeypot
---

# Adding a Honeypot Service

## Steps

### 1. Create service config

```yaml
# beelzebub/configurations/services/new-service-PORT.yaml
apiVersion: v1
protocol: TCP  # or SSH, HTTP, Telnet
address: ":PORT"
description: "Description of the service"
commands:
  - regex: ".*"
    handler: LLM
llmModel: deepseek-chat  # or gpt-4, claude
```

### 2. Expose port in docker-compose

```yaml
beelzebub:
  ports:
    - "PORT:PORT"
```

### 3. Update consumer field mapping

If the new protocol has unique fields, update `engine/consumer.py` to parse them.

### 4. Update risk engine

Add protocol-specific scoring in `engine/risk_engine.py`:

```python
elif protocol == "NEW_PROTOCOL":
    risk_score = BASE_SCORE
    # Add modifiers...
```

> [!warning] LLM API Key Required
> Beelzebub uses LLM for dynamic responses. Ensure `OPEN_AI_SECRET_KEY` or `DEEPSEEK_API_KEY` is set in `.env`.

### 5. Test

```bash
make up-dev
# Connect to new service and verify events appear
make test
```

## Related
- [[Beelzebub Honeypot]]
- [[ADR-002 RabbitMQ Event Bus]]
