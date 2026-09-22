# AGENTS.md — hamdashboard

## What this is
Ham radio dashboard — iframe tiles for weather, propagation, etc. (wrapper of VA3HDL/hamdashboard).

## Tech stack
nginx:1.31.5 Alpine, static HTML/JS, Compose (`mem_limit`), Traefik.


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
- When changing Dockerfile / Makefile / docker-compose.yml / .dockerignore, update all related files together
- Config changes go in `config.js` — preserve iframe URL structure
- Requires `traefik-network`

## Docker conventions (local Desktop)

Docker Desktop’s VM has limited RAM (~3.8 GiB). Heavy toolchains inside the image can OOM the engine.

- **Host-build, runtime-only image**: `make docker-build` / `make docker-run` must run the project build on the **host**, then `COPY` artifacts into a slim runtime Dockerfile (PHP/Apache, nginx, or JRE only).
- **Do not** add `FROM gradle` / `FROM maven` / Node build stages, or `npm ci` / `gradle` / `mvn package` in the production `Dockerfile`, for routine local builds.
- **Makefile**: keep `docker-build` dependent on the host build target; default `docker compose build` **without** `--no-cache`; expose `docker-rebuild` for `--no-cache`.
- **`.dockerignore`**: allow-list only what the runtime image needs (e.g. `src/main/webapp/`, host `build/…` or `target/…` or `dist/`, plus Apache/nginx config files). When you change `COPY` paths in the Dockerfile, update `.dockerignore` in the same change.
- **`docker-compose.yml`**: keep a modest `mem_limit`; route via Traefik labels; avoid binding host `:8080` when Traefik already owns it.
- Keep `Dockerfile`, `Makefile`, `docker-compose.yml`, and `.dockerignore` consistent whenever the image layout or build output path changes.

## Docs
- `README.md`, `docs/README-TRAEFIK.md`
