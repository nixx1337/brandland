# Switch brandland.com.ua nameservers to Cloudflare

New NS:
- `lee.ns.cloudflare.com`
- `itzel.ns.cloudflare.com`

## Method A — ISPmanager / hosting control panel

1. Log into ISPmanager: `https://h107.hvosting.ua/manager/ispmgr`
2. Find **Domains** or **Domain management**
3. Open `brandland.com.ua`
4. Look for **Nameservers** / **NS records**
5. Replace existing NS with:
   - `lee.ns.cloudflare.com`
   - `itzel.ns.cloudflare.com`
6. Save

## Method B — Domain registrar panel

If nameservers are set at the domain registrar, not in ISPmanager:

1. Log into where you bought `brandland.com.ua`
2. Find **DNS** / **Nameservers** section
3. Change from:
   - `ns1.h107.hvosting.ua`
   - `ns2.h107.hvosting.ua`
   to:
   - `lee.ns.cloudflare.com`
   - `itzel.ns.cloudflare.com`
4. Save

## After changing NS

Wait 5–30 minutes, then verify:

```bash
dig +short brandland.com.ua NS
```

Expected output:
```
itzel.ns.cloudflare.com.
lee.ns.cloudflare.com.
```

Then in Cloudflare dashboard:
1. Add DNS records for brandland.com.ua
2. A @ → 91.200.40.107
3. A www → 91.200.40.107
4. Turn proxy orange/on for both
