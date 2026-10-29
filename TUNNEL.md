# Cloudflare Tunnel Setup for BrandLand

## Prereqs
- cloudflared installed: `/usr/bin/cloudflared` present
- Cloudflare account: `981f67a43ff9088f259cde0832d1ca0b`
- Tunnel name: `brandland`
- Local site: http://localhost:8080

## Step 1 — Authenticate (run once per server)

    cloudflared tunnel login

A browser opens. Log in to Cloudflare and authorize the domain.

## Step 2 — Create tunnel

    cloudflared tunnel create brandland

Output includes a tunnel UUID. Save it.

## Step 3 — Write tunnel config

Place at `/home/dan/.cloudflared/config.yml`:

    tunnel: <TUNNEL_UUID>
    credentials-file: /home/dan/.cloudflared/<TUNNEL_UUID>.json

    ingress:
      - hostname: brandland.com.ua
        service: http://localhost:8080
      - hostname: www.brandland.com.ua
        service: http://localhost:8080
      - service: http_status:404

Notes:
- Replace <TUNNEL_UUID> with the ID from Step 2.
- `hostname` must match the DNS records you create in the Cloudflare dashboard.
- `service` points to YOUR local application. Do NOT point tunnel DNS at Cloudflare NS IPs.

## Step 4 — Route DNS in Cloudflare

    cloudflared tunnel route dns brandland <TUNNEL_UUID> brandland.com.ua
    cloudflared tunnel route dns brandland <TUNNEL_UUID> www.brandland.com.ua

## Step 5 — Install and start the service

    sudo cloudflared service install
    sudo systemctl enable --now cloudflared

## Step 6 — Verify

    systemctl status cloudflared
    curl -I https://brandland.com.ua
    curl -I https://www.brandland.com.ua

## Cloudflare dashboard

After completing steps above:
- Add A/AAAA/cname records ONLY if tunnel routing above did not create them.
- Ensure no "proxied" A records conflict with the tunnel CNAME if using Full/Strict.

## Troubleshooting

Failed routing? Make sure the hostnames are added in Cloudflare Zero Trust dashboard under **Tunnels**.

Tunnel down?
    journalctl -u cloudflared -f

Stop tunnel?
    sudo systemctl stop cloudflared
