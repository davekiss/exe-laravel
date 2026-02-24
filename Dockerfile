FROM ghcr.io/boldsoftware/exeuntu:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# Add Ondrej PPA for PHP 8.4 (Ubuntu 24.04 ships 8.3)
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get update

# Install PHP 8.4 and extensions
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
        php8.4-fpm \
        php8.4-pgsql \
        php8.4-mbstring \
        php8.4-xml \
        php8.4-curl \
        php8.4-zip \
        php8.4-bcmath \
        php8.4-intl \
        php8.4-redis \
        php8.4-gd \
        php8.4-cli \
        php8.4-common \
        php8.4-readline \
        php8.4-tokenizer \
    && rm -rf /var/lib/apt/lists/*

# Configure php-fpm to listen on a socket and run as exedev
RUN sed -i 's/^user = www-data/user = exedev/' /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i 's/^group = www-data/group = exedev/' /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i 's|^listen = .*|listen = /run/php/php-fpm.sock|' /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i 's/^listen.owner = www-data/listen.owner = exedev/' /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i 's/^listen.group = www-data/listen.group = exedev/' /etc/php/8.4/fpm/pool.d/www.conf && \
    mkdir -p /run/php && chown exedev:exedev /run/php
# PostgreSQL
# Composer
# Node.js
# Laravel project setup
# nginx configuration
# Agent guidance files

EXPOSE 80 8000 9999
