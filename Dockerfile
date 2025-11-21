FROM alpine:latest AS nginx-builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    linux-headers \
    ca-certificates \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    libedit-dev \
    mercurial \
    bash \
    alpine-sdk \
    findutils \
    git \
    wget \
    curl

# Set nginx version
ENV NGINX_VERSION=1.25.3

# Set pagespeed version
ENV PAGESPEED_VERSION=1.13.35.2-stable

# Download and extract nginx source
RUN cd /tmp && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

# Download and extract ngx_pagespeed
RUN cd /tmp && \
    wget -L https://github.com/apache/incubator-pagespeed-ngx/archive/v${PAGESPEED_VERSION}.tar.gz -O ngx_pagespeed.tar.gz && \
    tar zxf ngx_pagespeed.tar.gz && \
    mv incubator-pagespeed-ngx-${PAGESPEED_VERSION} ngx_pagespeed-${PAGESPEED_VERSION} && \
    rm ngx_pagespeed.tar.gz

# Download PSOL (PageSpeed Optimization Libraries)
# For version 1.13.35.2-stable, use PSOL 1.13.35.2
RUN cd /tmp/ngx_pagespeed-${PAGESPEED_VERSION} && \
    wget -L -O psol.tar.gz https://dl.google.com/dl/page-speed/psol/1.13.35.2-x64.tar.gz && \
    tar zxf psol.tar.gz && \
    rm psol.tar.gz

# Configure nginx with pagespeed
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_perl_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-file-aio \
    --with-http_v2_module \
    --add-module=/tmp/ngx_pagespeed-${PAGESPEED_VERSION}

# Build and install nginx
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    openssl \
    pcre \
    zlib \
    libxslt \
    gd \
    geoip \
    perl \
    libedit \
    wget

# Copy nginx binary, configuration, and modules from builder
COPY --from=nginx-builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-builder /etc/nginx /etc/nginx
COPY --from=nginx-builder /usr/lib/nginx /usr/lib/nginx

# Copy pagespeed PSOL libraries if they exist in the builder
COPY --from=nginx-builder /tmp/ngx_pagespeed-*/psol /usr/lib/nginx/pagespeed-psol || true

# Create nginx user and necessary directories
RUN addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx && \
    mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/log/nginx \
    /var/cache/ngx_pagespeed && \
    chown -R nginx:nginx /var/cache/nginx \
    /var/log/nginx \
    /var/cache/ngx_pagespeed

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

