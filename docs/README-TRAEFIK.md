# Ham Radio Dashboard - Traefik Integration

This document explains how to use the Ham Radio Dashboard with Traefik reverse proxy and Pi-hole DNS.

## Quick Start

### Option 1: Use Existing Traefik Instance

If you already have Traefik running:

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and configure your settings:
   ```bash
   HAMDASH_DOMAIN=hamdash.yourdomain.com
   TRAEFIK_NETWORK=traefik
   PIHOLE_DNS=192.168.1.2
   ```

3. Make sure the Traefik network exists:
   ```bash
   docker network create traefik
   ```

4. Start the dashboard:
   ```bash
   make run
   # or
   docker-compose up -d
   ```

### Option 2: Full Stack with Traefik Included

If you don't have Traefik yet:

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Create the acme.json file for SSL certificates:
   ```bash
   touch traefik/acme.json
   chmod 600 traefik/acme.json
   ```

3. Start the full stack:
   ```bash
   docker-compose -f docker-compose.traefik.yml up -d
   ```

4. Access services:
   - Ham Dashboard: http://hamdash.local (or your configured domain)
   - Traefik Dashboard: http://traefik.local:8081

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HAMDASH_DOMAIN` | Domain name for accessing the dashboard | `hamdash.local` |
| `TRAEFIK_NETWORK` | Traefik Docker network name | `traefik` |
| `PIHOLE_DNS` | Pi-hole DNS server IP address | `1.1.1.1` |
| `TZ` | Timezone | `UTC` |

### DNS Configuration

#### Using Pi-hole

1. Set your Pi-hole IP in `.env`:
   ```bash
   PIHOLE_DNS=192.168.1.2
   ```

2. Add a DNS entry in Pi-hole:
   - Go to Pi-hole admin interface
   - Navigate to Local DNS → DNS Records
   - Add: `hamdash.local` → `<your-docker-host-ip>`

#### Using /etc/hosts (local testing)

Add to `/etc/hosts`:
```
127.0.0.1 hamdash.local traefik.local
```

### HTTPS/SSL Configuration

To enable HTTPS with Let's Encrypt:

1. Edit `docker-compose.yml` and uncomment the HTTPS labels:
   ```yaml
   - "traefik.http.routers.hamdashboard-secure.rule=Host(`hamdash.yourdomain.com`)"
   - "traefik.http.routers.hamdashboard-secure.entrypoints=websecure"
   - "traefik.http.routers.hamdashboard-secure.tls=true"
   - "traefik.http.routers.hamdashboard-secure.tls.certresolver=letsencrypt"
   ```

2. Edit `traefik/traefik.yml` and configure Let's Encrypt:
   ```yaml
   certificatesResolvers:
     letsencrypt:
       acme:
         email: your-email@example.com
         storage: /acme.json
         httpChallenge:
           entryPoint: web
   ```

3. Restart the services:
   ```bash
   make rebuild
   ```

## Makefile Commands

```bash
make help              # Show all available commands
make run               # Start with Traefik integration
make run-traefik       # Start full stack with Traefik
make stop              # Stop services
make restart           # Restart services
make logs              # View logs
make clean             # Clean up everything
```

## Network Architecture

```
Internet/LAN
    ↓
Traefik (Port 80/443)
    ↓
Ham Radio Dashboard (Internal Port 80)
    ↓
Pi-hole DNS (Optional)
```

## Troubleshooting

### Dashboard not accessible

1. Check if Traefik network exists:
   ```bash
   docker network ls | grep traefik
   ```

2. Check container logs:
   ```bash
   docker logs hamdashboard
   docker logs traefik
   ```

3. Verify Traefik can see the service:
   ```bash
   docker exec traefik wget -O- http://hamdashboard
   ```

### DNS issues

1. Check if Pi-hole is reachable:
   ```bash
   docker exec hamdashboard ping -c 3 192.168.1.2
   ```

2. Test DNS resolution:
   ```bash
   docker exec hamdashboard nslookup google.com
   ```

### Traefik labels not working

1. Ensure `traefik.enable=true` is set
2. Check that the container is on the Traefik network:
   ```bash
   docker inspect hamdashboard | grep Networks -A 10
   ```

## Additional Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Docker Networking](https://docs.docker.com/network/)

