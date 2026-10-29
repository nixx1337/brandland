# BrandLand — Docker Deployment

Deploy your BrandLand landing page on your own server with your domain name.

## Architecture

```
Visitor → brandland.com.ua → Docker (port 80/443) → nginx → index.html
```

## Quick Start

### 1. Prerequisites

- A server with Docker & Docker Compose (any VPS, dedicated, or home server)
- A domain name pointed to your server's IP (A record)
- Ports 80 and 443 open in your firewall

### 2. Copy to your server

```bash
# From your local machine, copy the entire docker-deploy folder to the server:
scp -r docker-deploy/ user@your-server-ip:/opt/brandland/
ssh user@your-server-ip
cd /opt/brandland
```

### 3. Deploy

```bash
# Start (no build needed — uses stock nginx image + your files)
docker compose up -d

# Check it's running
docker compose ps

# View logs
docker compose logs -f brandland
```

### 4. Point your domain DNS

In your domain registrar's DNS settings, create an A record:

```
Type: A
Name: @          (or leave blank for root domain)
Value: YOUR_SERVER_IP
TTL: 300
```

Also create for www:

```
Type: A
Name: www
Value: YOUR_SERVER_IP
TTL: 300
```

DNS propagation takes 5-30 minutes typically.

### 5. Verify

```bash
# Local test (should return HTML)
curl -I http://localhost:8080

# Once DNS propagates:
curl -I https://brandland.com.ua
```

---

## HTTPS Setup (Recommended)

The Docker Compose exposes port 8080 by default. For HTTPS, you have two options:

### Option A: Caddy Reverse Proxy (Recommended — auto HTTPS)

```bash
# Install Caddy on the server, then create /etc/caddy/Caddyfile:
```

```caddyfile
brandland.com.ua, www.brandland.com.ua {
    reverse_proxy localhost:8080
    encode gzip zstd
}
```

```bash
sudo systemctl restart caddy
```

Caddy automatically gets and renews a Let's Encrypt certificate.

### Option B: Cloudflare Tunnel (No open ports needed)

If you don't want to open ports on your server:

1. Sign up at https://dash.cloudflare.com (free)
2. Add your domain → change nameservers to Cloudflare's
3. Go to **Zero Trust → Networks → Tunnels → Create a tunnel**
4. Install cloudflared on your server and run the tunnel command
5. Add public hostname: `brandland.com.ua` → `http://localhost:8080`

This gives you HTTPS + DDoS protection without opening any ports.

---

## Updating the Site

After changing `index.html` or images:

```bash
cd /opt/brandland

# If using volume mounts (docker-compose.yml default):
# Changes are instant, no rebuild needed

# If you want to rebuild the image:
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## Production Checklist

- [ ] DNS A record points to server IP
- [ ] Firewall allows ports 80/443 (or Cloudflare Tunnel for no open ports)
- [ ] HTTPS configured (Caddy or Cloudflare)
- [ ] `docker compose up -d` running
- [ ] `restart: unless-stopped` ensures auto-restart on reboot
- [ ] (Optional) Set up `certbot` for Let's Encrypt if not using Caddy/Cloudflare
- [ ] (Optional) Set up a cron job to pull latest changes

---

## Server Requirements

- Minimal: 512MB RAM, 1 vCPU, 10GB disk
- The nginx:alpine image is only ~45MB
- Handles thousands of concurrent connections easily for a static site

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Site not loading | `docker compose logs brandland` |
| 502 Bad Gateway | Container not running: `docker compose ps` |
| DNS not propagated | `dig brandland.com.ua` to check |
| Permission denied | `sudo` for docker commands |
| Port 80 already in use | Change port mapping in docker-compose.yml |
