FROM ghcr.io/boldsoftware/exeuntu:latest

LABEL org.opencontainers.image.source=https://github.com/davekiss/exe-laravel

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

# Install PostgreSQL 16
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y postgresql postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Enable PostgreSQL to start on boot via systemd
# NOTE: apt auto-creates a cluster during install. We do NOT run setup-postgres.sh
# during build anymore — DB user/database are created at runtime by laravel-setup.
RUN systemctl enable postgresql

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Redis
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/* && \
    systemctl enable redis-server

# Copy nginx config for Laravel
COPY config/nginx-laravel.conf /etc/nginx/sites-available/default

# Install Laravel installer globally as exedev user
USER exedev
RUN composer global require laravel/installer
USER root

# Symlink laravel installer to /usr/local/bin for non-interactive SSH access
RUN ln -sf /home/exedev/.config/composer/vendor/bin/laravel /usr/local/bin/laravel

# Copy laravel-setup script
COPY scripts/laravel-setup.sh /usr/local/bin/laravel-setup
RUN chmod +x /usr/local/bin/laravel-setup

# Store AGENTS.md template for runtime copy
RUN mkdir -p /usr/local/share/exe-laravel
COPY config/AGENTS.md /usr/local/share/exe-laravel/AGENTS.md

# Enable nginx and php-fpm on boot
RUN systemctl enable nginx php8.4-fpm

# Laravel boot migrations service
COPY scripts/laravel-boot.sh /usr/local/bin/laravel-boot.sh
RUN chmod +x /usr/local/bin/laravel-boot.sh

COPY config/laravel-boot.service /etc/systemd/system/laravel-boot.service
RUN chmod 644 /etc/systemd/system/laravel-boot.service && \
    systemctl enable laravel-boot.service

EXPOSE 80 8000 9999
