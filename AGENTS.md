# AGENTS.md — hamdashboard

## What this is
Ham radio dashboard — iframe tiles for weather, propagation, etc. (wrapper of VA3HDL/hamdashboard).

## Tech stack
nginx:1.31 Alpine, static HTML/JS, Compose, Traefik.

## Key files
- `docker-compose.yml`, `Dockerfile`, `hamdash.html`, `config.js`, `nginx.conf`
- `.env.example`, `docs/README-TRAEFIK.md`

## Commands
- Start: `docker compose up -d` or `make run`
- Port 8091; Traefik: `http://hamdash.localhost`

## Environment
- `HAMDASH_DOMAIN`, `TRAEFIK_NETWORK`, `PIHOLE_DNS`, `TZ`
- Mount `config.js` for live config changes

## Rules for agents
- Config changes go in `config.js` — preserve iframe URL structure
- Requires `traefik-network`

## Docs
- `README.md`, `docs/README-TRAEFIK.md`
