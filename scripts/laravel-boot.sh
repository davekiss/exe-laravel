#!/bin/bash
set -euo pipefail

cd /home/exedev/app

# Wait for PostgreSQL to be ready
for i in $(seq 1 30); do
    if pg_isready -q; then
        break
    fi
    sleep 1
done

# Run migrations
php artisan migrate --force 2>/dev/null || true
