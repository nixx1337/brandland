# Deploy BrandLand Landing Page on a VPS with Docker

This guide walks you through deploying the BrandLand landing page (Brand landing page on a virtual private server (VPS) using Docker and Docker Compose. It covers server preparation, Docker installation, deployment, and HTTPS setup.

## Prerequisites

- A VPS (Ubuntu 20.04/22.04, Debian, CentOS, etc.) with root or sudo access.
- A domain name (e.g., `example.com`) pointing to your server's IP address.
- Ports 80 and 443 open in the firewall (or use Cloudflare Tunnel as an alternative).
- Basic familiarity with the Linux command line.

## Step 1: Prepare the VPS

### Update the system
```bash
sudo apt update && sudo apt upgrade -y   # Ubuntu/Debian
# sudo yum update -y                     # CentOS/RHEL
```

### Install Docker and Docker Compose

#### Ubuntu/Debian
```bash
# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

#### CentOS/RHEL
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

### (Optional) Install Git
```bash
sudo apt install -y git   # Ubuntu/Debian
# sudo yum install -y git   # CentOS/RHEL
```

### Open firewall ports (if using ufw)
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Step 2: Prepare the Application Files

### Option A: Clone the repository (if available)
```bash
git clone <repository-url> /opt/brandland
cd /opt/brandland
```

### Option B: Copy files manually
If you have the files locally, copy them to the server:
```bash
# From your local machine:
scp -r docker-deploy/ user@your_server_ip:/opt/brandland
ssh user@your_server_ip
cd /opt/brandland
```
Ensure the folder contains:
- `docker-compose.yml`
- `nginx.conf`
- `index.html`
- any asset folders (`images/`, `css/`, etc.)

## Step 3: Configure DNS

Point your domain to the server's IP address:

1. Log in to your domain registrar's DNS management.
2. Create an **A record**:
   - **Name:** `@` (or leave blank for root domain)
   - **Value:** `YOUR_SERVER_IP`
   - **TTL:** `300` (5 minutes)
3. Create another A record for `www`:
   - **Name:** `www`
   - **Value:** `YOUR_SERVER_IP`
   - **TTL:** `300`

Wait for DNS propagation (5-30 minutes). You can check with:
```bash
dig +short yourdomain.com
dig +short www.yourdomain.com
```

## Step 4: Deploy with Docker Compose

Inside `/opt/brandland`:

```bash
# Build and start the containers
docker compose up -d --build

# Verify the containers are running
docker compose ps
```
You should see the `brandland` service (nginx) and possibly others.

Check the logs:
```bash
docker compose logs -f brandland
```

Test locally on the server:
```bash
curl -I http://localhost:8080
```
You should see a `200 OK` response with HTML content.

## Step 5: Set Up HTTPS (Recommended: Caddy)

The provided `docker-compose.yml` exposes the nginx container on port `8080`. We'll use Caddy as a reverse proxy to obtain and renew Let's Encrypt certificates automatically.

### Install Caddy
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy.list
sudo apt update
sudo apt install -y caddy
```

### Configure Caddy
Create or edit `/etc/caddy/Caddyfile`:
```bash
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
yourdomain.com, www.yourdomain.com {
    reverse_proxy localhost:8080
    encode gzip zstd
}
EOF
```
Replace `yourdomain.com` with your actual domain (both with and without `www`).

### Start Caddy
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now caddy
sudo systemctl status caddy
```

Caddy will automatically obtain a Let's Encrypt certificate for your domain(s). Check the logs:
```bash
sudo journalctl -u caddy -f
```

### Test HTTPS
```bash
curl -I https://yourdomain.com
curl -I https://www.yourdomain.com
```
You should see a `200 OK` and headers indicating `strict-transport-security`.

## Alternative: Cloudflare Tunnel (No open ports)

If you cannot open ports 80/443 on your server, follow the Cloudflare Tunnel method described in the README:

1. Sign up at https://dash.cloudflare.com.
2. Add your domain and change nameservers to Cloudflare's.
3. In Zero Trust → Networks → Tunnels, create a tunnel.
4. Install `cloudflared` on your server and run the tunnel command.
5. Add a public hostname: `yourdomain.com → http://localhost:8080`.

This provides HTTPS and DDoS protection without opening server ports.

## Step 6: Verify the Site

Visit `https://yourdomain.com` in a browser. You should see the BrandLand landing page.

You can also test with curl:
```bash
curl -I https://yourdomain.com
```

## Step 7: Maintenance and Updates

### Updating the site
If you modify `index.html` or assets:
- If using volume mounts (default in `docker-compose.yml`), changes are reflected instantly.
- To rebuild the image:
  ```bash
  cd /opt/brandland
  docker compose down
  docker compose build --no-cache
  docker compose up -d
  ```

### Renewing certificates
- Caddy automatically renews Let's Encrypt certificates.
- For Cloudflare Tunnel, certificates are managed by Cloudflare.

### Monitoring
- Check container logs: `docker compose logs -f brandland`
- Monitor resource usage: `docker stats`

### Backup
Backup the `/opt/brandland` directory (especially `index.html` and any custom assets) periodically.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Site not loading | Check container logs: `docker compose logs brandland` |
| 502 Bad Gateway | Ensure the `brandland` container is running: `docker compose ps` |
| DNS not propagated | Run `dig yourdomain.com` to verify IP |
| Permission denied | Use `sudo` for Docker commands or add your user to the `docker` group |
| Port 80 already in use | Stop conflicting service or change port mapping in `docker-compose.yml` |

## Success! 🎉

Your BrandLand landing page is now live on your domain with HTTPS.

---

*Guide generated by Hermes Agent.*