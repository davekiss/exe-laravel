#!/bin/bash
set -euo pipefail

APP_DIR="/home/exedev/app"

if [ -f "$APP_DIR/artisan" ]; then
    echo "Laravel app already exists at $APP_DIR"
    exit 0
fi

export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Wait for PostgreSQL to be ready
for i in $(seq 1 30); do
    if pg_isready -q 2>/dev/null; then
        break
    fi
    sleep 1
done

# Create PostgreSQL user and database if they don't exist
# The database name "app" matches what `laravel new app` puts in .env
sudo -u postgres createuser -s exedev 2>/dev/null || true
sudo -u postgres createdb -O exedev app 2>/dev/null || true

cd /home/exedev

# Run laravel new with passthrough flags
# Always include: pgsql database, boost, npm build, git init, non-interactive
laravel new app \
    --database=pgsql \
    --boost \
    --npm \
    --git \
    --branch=main \
    --no-interaction \
    "$@"

cd app

# Get VM name for APP_URL
VM_NAME="${HOSTNAME%%.*}"

# Configure .env for exe.dev environment
sed -i "s|^APP_URL=.*|APP_URL=https://${VM_NAME}.exe.xyz|" .env
sed -i 's/^DB_HOST=.*/DB_HOST=127.0.0.1/' .env
sed -i 's/^DB_USERNAME=.*/DB_USERNAME=exedev/' .env
sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=/' .env
sed -i 's/^DB_DATABASE=.*/DB_DATABASE=app/' .env

# Trust exe.dev reverse proxy (sends X-Forwarded-Proto, X-Forwarded-Host, X-Forwarded-For)
if ! grep -q '^TRUSTED_PROXIES=' .env; then
    echo 'TRUSTED_PROXIES=*' >> .env
fi

# Configure .env.example
sed -i 's|^APP_URL=.*|APP_URL=https://your-vm.exe.xyz|' .env.example
sed -i 's/^DB_HOST=.*/DB_HOST=127.0.0.1/' .env.example
sed -i 's/^DB_USERNAME=.*/DB_USERNAME=exedev/' .env.example
sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=/' .env.example
sed -i 's/^DB_DATABASE=.*/DB_DATABASE=app/' .env.example

# Copy exe.dev AGENTS.md
cp /usr/local/share/exe-laravel/AGENTS.md ./AGENTS.md

# Run migrations (PostgreSQL is running at this point)
php artisan migrate --force

# Set git identity and commit
git config user.email "exedev@exe.dev"
git config user.name "exedev"
git add -A
git commit -m "Initial Laravel project"

echo ""
echo "Laravel app ready at $APP_DIR"
