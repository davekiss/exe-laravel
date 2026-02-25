FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/davekiss/exe-laravel
# Note: exe.dev/login-user label added after user setup is verified

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# Base packages + supervisor
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
        supervisor \
        nginx \
        curl \
        git \
        unzip \
        sudo \
        software-properties-common \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# Create exedev user (UID 1000)
RUN usermod -l exedev -d /home/exedev -m ubuntu && \
    groupmod -n exedev ubuntu && \
    echo "exedev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chmod 711 /home/exedev

# Add www-data to exedev group (nginx needs to access php-fpm socket)
RUN usermod -aG exedev www-data

# Add Ondrej PPA for PHP 8.4 (Ubuntu 24.04 ships 8.3)
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
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

# Configure php-fpm: socket, run as exedev
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

# Configure PostgreSQL: trust auth for local TCP (no password)
RUN sed -i 's/^host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+scram-sha-256/host    all             all             127.0.0.1\/32            trust/' /etc/postgresql/16/main/pg_hba.conf && \
    sed -i 's/^host\s\+all\s\+all\s\+::1\/128\s\+scram-sha-256/host    all             all             ::1\/128                 trust/' /etc/postgresql/16/main/pg_hba.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Redis
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/*

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

# Copy laravel-boot script (runs at startup for migrations)
COPY scripts/laravel-boot.sh /usr/local/bin/laravel-boot.sh
RUN chmod +x /usr/local/bin/laravel-boot.sh

# Store AGENTS.md template for runtime copy
RUN mkdir -p /usr/local/share/exe-laravel
COPY config/AGENTS.md /usr/local/share/exe-laravel/AGENTS.md

# Supervisord config
COPY config/supervisord.conf /etc/supervisor/conf.d/laravel.conf

# Entrypoint: initialize services then start supervisor
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80 8080

CMD ["/usr/local/bin/entrypoint.sh"]
