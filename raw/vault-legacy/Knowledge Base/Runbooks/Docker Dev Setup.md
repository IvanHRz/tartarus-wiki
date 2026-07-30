---
title: Docker Dev Setup
tags:
  - runbook
  - setup
---

# Docker Dev Setup

## Prerequisites

- Docker Desktop for Mac (ARM64)
- Make

## Quick Start

```bash
make setup    # Copy .env, install pre-commit, setup Beelzebub
make up-dev   # Start 7 containers
make health   # Verify all services
```

## Dev URLs

| Service | URL |
|---------|-----|
| UI | http://localhost:8888 |
| Engine API | http://localhost:9000/health |
| RabbitMQ Mgmt | http://localhost:15672 (guest/guest) |
| Adminer (DB) | http://localhost:9080 |

## Trap URLs (for testing)

| Protocol | Command |
|----------|---------|
| SSH | `ssh -p 2222 root@localhost` |
| HTTP | `curl http://localhost:8880` |

## Common Commands

```bash
make logs     # Tail all container logs
make test     # Run pytest
make audit    # Check code constraints
make down     # Stop containers
make clean    # Remove containers + volumes
```

> [!tip] First Run
> After `make up-dev`, wait ~30 seconds for all services to initialize.
> Check `make health` to verify PostgreSQL, Redis, and RabbitMQ are ready.

> [!warning] Apple Silicon
> All Docker images must be ARM64 native. The `docker-compose.yml` uses `platform: linux/arm64` where needed.

## Related
- [[Services]]
- [[Network Topology.canvas]]
