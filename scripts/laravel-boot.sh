#!/bin/bash
set -euo pipefail

APP_DIR="/home/exedev/app"

# Skip if no Laravel app exists yet
if [ ! -f "$APP_DIR/artisan" ]; then
    exit 0
fi

cd "$APP_DIR"

# Wait for PostgreSQL to be ready
for i in $(seq 1 30); do
    if pg_isready -q; then
        break
    fi
    sleep 1
done

# Run migrations
php artisan migrate --force 2>/dev/null || true

# Keep Boost resources up to date
php artisan boost:update --no-interaction 2>/dev/null || true
