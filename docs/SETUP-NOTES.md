# Ham Radio Dashboard - Current Setup

## Network Configuration

Your hamdashboard is now properly connected to your **existing Traefik instance**.

### Current Status

- **Traefik Container:** `docker-traefik-reverse-proxy-1` (already running)
- **Network:** `traefik-network`
- **Containers on Network:**
  - docker-traefik-reverse-proxy-1 (Traefik)
  - hamdashboard (this app)
  - pihole

## Access URLs

- **Direct Access:** http://localhost:8091
- **Via Traefik:** http://hamdash.local (requires DNS configuration)

## DNS Configuration

To access via `hamdash.local`:

1. Add to Pi-hole DNS records:
   - Domain: `hamdash.local`
   - IP: Your Docker host IP

2. Or add to `/etc/hosts`:
   ```
   127.0.0.1 hamdash.local
   ```

## Traefik Labels

The hamdashboard container has these Traefik labels:

```yaml
traefik.enable=true
traefik.http.routers.hamdashboard.rule=Host(`hamdash.local`)
traefik.http.routers.hamdashboard.entrypoints=web
traefik.http.services.hamdashboard.loadbalancer.server.port=80
```

## Important Notes

⚠️ **Do NOT use `make run-traefik`** - This would start a second Traefik instance!

✅ **Use `make run`** - This connects to your existing Traefik instance

## Modifying Configuration

Edit `.env` file to change:
- `HAMDASH_DOMAIN` - Change the domain name
- `TRAEFIK_NETWORK` - Currently set to `traefik-network`
- `PIHOLE_DNS` - Your Pi-hole IP address

After changing `.env`, restart:
```bash
make clean
make run
```
