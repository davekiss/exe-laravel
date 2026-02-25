#!/bin/bash
set -euo pipefail

# Ensure runtime directories exist
mkdir -p /run/php && chown exedev:exedev /run/php
mkdir -p /var/run/postgresql && chown postgres:postgres /var/run/postgresql
mkdir -p /var/log/supervisor

# Initialize PostgreSQL data directory if needed
if [ ! -f /var/lib/postgresql/16/main/PG_VERSION ]; then
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/main
fi

# Start supervisord (manages nginx, php-fpm, postgresql, redis)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
