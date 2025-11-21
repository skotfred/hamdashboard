FROM nginx:1.29.3-alpine

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
COPY examples ./examples

# Ensure nginx user has no shell access (Alpine uses /sbin/nologin)
RUN sed -i 's|/bin/sh|/sbin/nologin|g' /etc/passwd

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Expose port 80
EXPOSE 80

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
