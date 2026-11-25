FROM nginx:1.31.10-alpine

LABEL maintainer="Scott Fredrickson <scott@giantgeek.com>"
LABEL description="Ham Radio Dashboard - VA3HDL Hamdash"
LABEL version="1.0"

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set working directory to nginx html root
WORKDIR /usr/share/nginx/html

# Copy application files
COPY hamdash.html index.html
COPY config.js .
COPY wheelzoom.js .
COPY favicon.ico .
COPY favicon.svg .
COPY robots.txt .
COPY examples ./examples

# Ensure nginx user has no shell access (Alpine uses /sbin/nologin)
RUN sed -i 's|/bin/sh|/sbin/nologin|g' /etc/passwd

# Exactly HTTP 200 from nginx on /admin ("/" is a 301 to /admin; redirects are not followed)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -S -O /dev/null -T 4 http://127.0.0.1/admin 2>&1 | grep -m1 -E '^ *HTTP/' | grep -qE '^ *HTTP/1[.][01] 200 ' || exit 1

# Expose port 80
EXPOSE 80

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

# Build time (UTC) for `docker ps`/`docker inspect`; set by the Makefile via BUILD_DATE.
# Kept last so a new timestamp does not invalidate any cached layers above.
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.created=$BUILD_DATE
