# ISPManager — Stop Cloudflare tunnel, bind brandland to your IP

IP: 91.200.40.107  
Domain: brandland.com.ua

## Step 1 — Stop cloudflared on the server

SSH into the server where you ran `cloudflared service install`, then:

```bash
sudo systemctl stop cloudflared
sudo systemctl disable cloudflared
```

If it wasn’t installed as a service, ignore this.

## Step 2 — Remove Cloudflare nameservers at your registrar

Go to the domain control panel of your registrar and set NS back to:

  ns1.h107.hvosting.ua.  
  ns2.h107.hvosting.ua.

## Step 3 — Create “WWW” domain as alias in ISPmanager

1. Log into ISPmanager.
2. Menu → **Domains**.
3. Find `www.brandland.com.ua`.
4. Set it as **Alias → brandland.com.ua**.

Do the reverse only if asked to set `brandland.com.ua` as alias of `www`.

## Step 4 — Remove any Cloudflare/extra A/AAAA records

Leave ONLY:

  Type: A  
  Name: @  
  Value: 91.200.40.107

And:

  Type: A  
  Name: www  
  Value: 91.200.40.107

Delete any CNAME/AAAA records that point to `brandland.com.ua.cdn.cloudflare.net` or similar.

## Step 5 — Check IP on the server

```bash
hostname -I | tr ' ' '\n' | grep -F '91.200.40.107' || echo IP_NOT_INTERFACE
```

If the server doesn’t actually have `91.200.40.107` assigned, stop and fix the IP assignment first.

## Step 6 — Verify locally

```bash
curl -I http://91.200.40.107
curl -skI https://91.200.40.107
```

Expect the existing stack on `91.200.40.107` to answer.

## Step 7 — Optional HTTPS via Let’s Encrypt in ISPmanager

Use the built-in Let’s Encrypt button for `brandland.com.ua`. Do not paste Cloudflare certs into the stack — those only apply if Cloudflare is in proxy mode.
