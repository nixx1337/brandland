# BrandLand — static site on nginx (Alpine, ~45 MB image)
FROM nginx:1.27-alpine

# Custom nginx config: gzip + image caching + security headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Site files
COPY index.html /usr/share/nginx/html/
COPY images/ /usr/share/nginx/html/images/

EXPOSE 80
# nginx starts automatically (CMD from base image)
