# CLOUDFLARE SETUP — BrandLand

This guide covers two Cloudflare options:
- Option A: Cloudflare Tunnel (`cloudflared`) — no open firewall ports
- Option B: Cloudflare DNS + proxy + HTTPS on origin (Caddy)

## Prereqs

- Domain pointed to Cloudflare nameservers
- Docker site already up: `docker compose -f /home/dan/Brandland/docker-compose.yml ps`
- Access to the server shell

---

## Option A — Cloudflare Tunnel (recommended, no open ports)

### 1) Install cloudflared

Debian/Ubuntu:

  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

  sudo apt update && sudo apt install -y cloudflared

Verify:

  cloudflared --version

### 2) Authenticate cloudflared

  cloudflared tunnel login

A browser window opens. Log in to Cloudflare and authorize the domain.

Uploaded certs are stored at `~/.cloudflared/`.

### 3) Create the tunnel

  TUNNEL=$(cloudflared tunnel create brandland)
  echo "$TUNNEL"

Save the tunnel ID shown.

### 4) Write tunnel config

Create `~/.cloudflared/config.yml`:

  tunnel: <TUNNEL_ID>
  credentials-file: /home/dan/.cloudflared/<TUNNEL_ID>.json

  ingress:
    - hostname: brandland.com.ua
      service: http://localhost:8080
    - hostname: www.brandland.com.ua
      service: http://localhost:8080
    - service: http_status:404

Then test the route:

  cloudflared tunnel route dns brandland <TUNNEL_ID> brandland.com.ua
  cloudflared tunnel route dns brandland <TUNNEL_ID> www.brandland.com.ua

### 5) Start the tunnel service

Install a systemd service:

  cloudflared service install
  sudo systemctl enable --now cloudflared

Verify DNS CNAME:

  dig +short brandland.com.ua
  dig +short www.brandland.com.ua

### 6) Verify

  http -b https://brandland.com.ua | head
  http -b https://www.brandland.com.ua | head

Cloudflare provides HTTPS + DDoS protection automatically.

---

## Option B — Cloudflare DNS proxy + HTTPS on origin

### 1) Create DNS records in Cloudflare dashboard

  A   @     YOUR_SERVER_IP   Proxy only (orange cloud)
  A   www   YOUR_SERVER_IP   Proxy only (orange cloud)

Ensure `Proxy status` is ON in the dashboard.

### 2) Expose one non-proxied internal address

For origin TLS between Cloudflare and your server, install Caddy on
the host:

  sudo apt install -y caddy

Place the site on the host at `/var/www/brandland/html/index.html`,
or keep Docker and change `docker-compose.yml` to `127.0.0.1:8080:80`
without exposing 80 directly.

Caddyfile `/etc/caddy/Caddyfile`:

  origin.brandland.com.ua {
      reverse_proxy localhost:8080
      encode gzip zstd
  }

Then enable HTTPS directly:

  brandland.com.ua, www.brandland.com.ua {
      reverse_proxy localhost:8080
      encode gzip zstd
  }

Restart:

  sudo systemctl restart caddy

Set Cloudflare SSL/TLS mode to **Full (strict)**.

---

## Verify either option

  curl -I https://brandland.com.ua
  curl -I https://www.brandland.com.ua

Headers should show `CF-Ray`.

---

## Useful commands

  # tunnel status
  cloudflared tunnel info brandland

  # live tunnel logs
  journalctl -u cloudflared -f

  # re-authenticate
  cloudflared tunnel login
