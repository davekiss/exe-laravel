# exe-laravel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a custom exe.dev container image and CLI that gives you a live Laravel app in ~2 seconds, ready for agent-driven development.

**Architecture:** Two components — a Dockerfile extending exeuntu with PHP/PostgreSQL/nginx/Laravel, and a thin shell script CLI wrapping `ssh exe.dev` commands. The image does the heavy lifting; the CLI is sugar.

**Tech Stack:** Docker (Dockerfile), Bash (CLI), PHP 8.4, PostgreSQL 16, nginx, Composer, Node.js 22, Laravel 12

---

### Task 1: Project scaffolding

**Files:**
- Create: `Dockerfile`
- Create: `bin/exe-laravel`
- Create: `README.md` (minimal — just what it is and how to use it)

**Step 1: Initialize the Dockerfile skeleton**

Create `Dockerfile` with just the FROM line and a comment structure:

```dockerfile
FROM ghcr.io/boldsoftware/exeuntu:latest

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# PHP + extensions
# PostgreSQL
# Composer
# Node.js
# Laravel project setup
# nginx configuration
# Agent guidance files

EXPOSE 80 8000 9999
```

**Step 2: Create the CLI skeleton**

Create `bin/exe-laravel`:

```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/davekiss/exe-laravel"
VERSION="0.1.0"

usage() {
    cat <<EOF
exe-laravel $VERSION — Laravel on exe.dev

Usage:
    exe-laravel new [name]        Create a new Laravel VM
    exe-laravel list              List Laravel VMs
    exe-laravel ssh <name>        SSH into a VM
    exe-laravel open <name>       Open app URL in browser
    exe-laravel share <name>      Make app public
    exe-laravel unshare <name>    Make app private
    exe-laravel destroy <name>    Delete a VM
    exe-laravel clone <name> [new-name]  Copy a VM
    exe-laravel logs <name>       Tail Laravel logs
    exe-laravel artisan <name> <cmd...>  Run artisan command
    exe-laravel agent <name>      Open Shelley in browser
EOF
}

cmd="${1:-help}"
shift || true

case "$cmd" in
    help|--help|-h) usage ;;
    *) echo "Unknown command: $cmd"; usage; exit 1 ;;
esac
```

**Step 3: Make CLI executable**

Run: `chmod +x bin/exe-laravel`

**Step 4: Commit**

```bash
git add Dockerfile bin/exe-laravel
git commit -m "scaffold: Dockerfile and CLI skeleton"
```

---

### Task 2: PHP and extensions

**Files:**
- Modify: `Dockerfile`

**Step 1: Add PHP 8.4 and all required extensions**

Add after the FROM/SHELL lines in `Dockerfile`. Ubuntu 24.04 ships PHP 8.3,
so we need the Ondrej Sury PPA for 8.4.

```dockerfile
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
```

**Step 2: Verify it builds**

Run: `docker build --target= -t exe-laravel-test .` (or just `docker build -t exe-laravel-test .`)
Expected: Build completes, PHP 8.4 installed

**Step 3: Commit**

```bash
git add Dockerfile
git commit -m "feat: add PHP 8.4 with extensions and php-fpm config"
```

---

### Task 3: PostgreSQL

**Files:**
- Modify: `Dockerfile`

**Step 1: Install PostgreSQL 16 and configure it**

Add to `Dockerfile` after PHP section:

```dockerfile
# Install PostgreSQL 16
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y postgresql postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Configure PostgreSQL: create database and user for Laravel
# This runs during build to set up the initial state.
# PostgreSQL data lives on the persistent disk at runtime.
COPY scripts/setup-postgres.sh /usr/local/bin/setup-postgres.sh
RUN chmod +x /usr/local/bin/setup-postgres.sh
```

**Step 2: Create the PostgreSQL setup script**

Create `scripts/setup-postgres.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Start PostgreSQL temporarily for setup
pg_ctlcluster 16 main start

# Create the laravel user and database
sudo -u postgres createuser -s exedev 2>/dev/null || true
sudo -u postgres createdb -O exedev laravel 2>/dev/null || true

# Allow local connections without password (peer auth)
# This is fine — it's a single-user VM
pg_ctlcluster 16 main stop
```

**Step 3: Run the setup during build**

Add to `Dockerfile` after the COPY:

```dockerfile
RUN /usr/local/bin/setup-postgres.sh

# Enable PostgreSQL to start on boot via systemd
RUN systemctl enable postgresql
```

**Step 4: Commit**

```bash
git add Dockerfile scripts/setup-postgres.sh
git commit -m "feat: add PostgreSQL 16 with laravel database"
```

---

### Task 4: Composer and Node.js

**Files:**
- Modify: `Dockerfile`

**Step 1: Install Composer**

Add to `Dockerfile`:

```dockerfile
# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
```

**Step 2: Install Node.js 22 LTS**

```dockerfile
# Install Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*
```

**Step 3: Commit**

```bash
git add Dockerfile
git commit -m "feat: add Composer and Node.js 22"
```

---

### Task 5: Laravel project and nginx configuration

**Files:**
- Modify: `Dockerfile`
- Create: `config/nginx-laravel.conf`
- Create: `scripts/setup-laravel.sh`

**Step 1: Create the nginx config for Laravel**

Create `config/nginx-laravel.conf`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /home/exedev/app/public;
    index index.php index.html;

    server_name _;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

**Step 2: Create the Laravel setup script**

Create `scripts/setup-laravel.sh`:

```bash
#!/bin/bash
set -euo pipefail

cd /home/exedev

# Create fresh Laravel project
composer create-project laravel/laravel app --no-interaction

cd app

# Configure .env for PostgreSQL
sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=pgsql/' .env
sed -i 's/^DB_HOST=.*/DB_HOST=127.0.0.1/' .env
sed -i 's/^DB_PORT=.*/DB_PORT=5432/' .env
sed -i 's/^DB_DATABASE=.*/DB_DATABASE=laravel/' .env
sed -i 's/^DB_USERNAME=.*/DB_USERNAME=exedev/' .env
sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=/' .env

# Also update .env.example to match
sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=pgsql/' .env.example
sed -i 's/^DB_HOST=.*/DB_HOST=127.0.0.1/' .env.example
sed -i 's/^DB_PORT=.*/DB_PORT=5432/' .env.example
sed -i 's/^DB_DATABASE=.*/DB_DATABASE=laravel/' .env.example
sed -i 's/^DB_USERNAME=.*/DB_USERNAME=exedev/' .env.example
sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=/' .env.example

# Install npm dependencies
npm install

# Build frontend assets
npm run build

# Initialize git repo
git init
git add -A
git commit -m "Initial Laravel project"
```

**Step 3: Add to Dockerfile**

```dockerfile
# Copy nginx config for Laravel
COPY config/nginx-laravel.conf /etc/nginx/sites-available/default

# Create Laravel project as exedev user
COPY scripts/setup-laravel.sh /usr/local/bin/setup-laravel.sh
RUN chmod +x /usr/local/bin/setup-laravel.sh

USER exedev
RUN /usr/local/bin/setup-laravel.sh
USER root

# Enable nginx and php-fpm on boot
RUN systemctl enable nginx php8.4-fpm
```

**Step 4: Commit**

```bash
git add Dockerfile config/nginx-laravel.conf scripts/setup-laravel.sh
git commit -m "feat: add Laravel project with nginx and php-fpm"
```

---

### Task 6: Laravel AGENTS.md

**Files:**
- Create: `config/AGENTS.md`
- Modify: `Dockerfile`

**Step 1: Write the Laravel-specific AGENTS.md**

Create `config/AGENTS.md`:

```markdown
# Laravel on exe.dev

You are working on a live Laravel application running on an exe.dev VM.
Changes you make are immediately visible at the VM's public URL.

## Environment

- **App root:** /home/exedev/app
- **Web server:** nginx serving /home/exedev/app/public on port 80
- **PHP:** 8.4 with php-fpm
- **Database:** PostgreSQL 16 (database: laravel, user: exedev, no password, peer auth)
- **Node.js:** 22 LTS with npm
- **Frontend:** Vite (run `npm run dev` for HMR or `npm run build` for production)

## Common Commands

```bash
cd /home/exedev/app

# Artisan
php artisan migrate
php artisan make:model ModelName -mfc
php artisan make:livewire ComponentName
php artisan tinker

# Database
psql laravel                    # connect to database
php artisan migrate:fresh --seed # reset database

# Frontend
npm run dev                     # Vite dev server with HMR
npm run build                   # production build

# Services
sudo systemctl restart nginx
sudo systemctl restart php8.4-fpm
sudo systemctl restart postgresql

# Logs
tail -f /home/exedev/app/storage/logs/laravel.log
sudo journalctl -u nginx -f
sudo journalctl -u php8.4-fpm -f
```

## Conventions

- This is a live server. Test changes carefully.
- Commit frequently with descriptive messages.
- Use `php artisan` for all Laravel scaffolding.
- Database migrations go in `database/migrations/`.
- The app uses PostgreSQL — use PostgreSQL-compatible SQL.
- The `.env` file is already configured. Don't change DB settings unless adding a new database.

## exe.dev Specifics

- HTTPS proxy docs: https://exe.dev/docs/proxy
- Full docs: https://exe.dev/docs
- Only use documented exe.dev features. Undocumented local endpoints are internal infrastructure.
```

**Step 2: Add to Dockerfile**

```dockerfile
# Copy Laravel-specific AGENTS.md into the project
COPY config/AGENTS.md /home/exedev/app/AGENTS.md
RUN chown exedev:exedev /home/exedev/app/AGENTS.md
```

**Step 3: Commit**

```bash
git add config/AGENTS.md Dockerfile
git commit -m "feat: add Laravel-specific AGENTS.md for coding agents"
```

---

### Task 7: Migrations on boot

**Files:**
- Create: `scripts/laravel-boot.sh`
- Create: `config/laravel-boot.service`
- Modify: `Dockerfile`

On first boot (or after VM restart), we need PostgreSQL to be running before we can run migrations. Create a systemd service that runs migrations after PostgreSQL starts.

**Step 1: Create the boot script**

Create `scripts/laravel-boot.sh`:

```bash
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
```

**Step 2: Create the systemd service**

Create `config/laravel-boot.service`:

```ini
[Unit]
Description=Laravel boot tasks (migrations)
After=postgresql.service
Requires=postgresql.service

[Service]
Type=oneshot
User=exedev
WorkingDirectory=/home/exedev/app
ExecStart=/usr/local/bin/laravel-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Step 3: Add to Dockerfile**

```dockerfile
COPY scripts/laravel-boot.sh /usr/local/bin/laravel-boot.sh
RUN chmod +x /usr/local/bin/laravel-boot.sh

COPY config/laravel-boot.service /etc/systemd/system/laravel-boot.service
RUN chmod 644 /etc/systemd/system/laravel-boot.service && \
    systemctl enable laravel-boot.service
```

**Step 4: Commit**

```bash
git add scripts/laravel-boot.sh config/laravel-boot.service Dockerfile
git commit -m "feat: add systemd service for Laravel boot migrations"
```

---

### Task 8: Redis

**Files:**
- Modify: `Dockerfile`

**Step 1: Install Redis and enable on boot**

Add to `Dockerfile`:

```dockerfile
# Install Redis
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/* && \
    systemctl enable redis-server
```

**Step 2: Commit**

```bash
git add Dockerfile
git commit -m "feat: add Redis server"
```

---

### Task 9: CLI — `new` command

**Files:**
- Modify: `bin/exe-laravel`

**Step 1: Implement the `new` command**

Add to the case statement in `bin/exe-laravel`:

```bash
new)
    name="${1:-}"
    args="--image=$IMAGE --json"
    if [[ -n "$name" ]]; then
        args="$args --name=$name"
    fi
    result=$(ssh exe.dev new $args)
    vm_name=$(echo "$result" | jq -r '.vm_name')
    echo "Created Laravel app: $vm_name"
    echo ""
    echo "  App:     https://${vm_name}.exe.xyz"
    echo "  SSH:     ssh ${vm_name}.exe.xyz"
    echo "  Shelley: https://${vm_name}.exe.xyz:9999/"
    echo ""
    echo "Your Laravel app is live. Connect an agent and start building."
    ;;
```

**Step 2: Test locally**

Run: `bin/exe-laravel new --help` (should not error on parsing)
Run: `bin/exe-laravel help` (should show usage)

**Step 3: Commit**

```bash
git add bin/exe-laravel
git commit -m "feat: implement 'new' command in CLI"
```

---

### Task 10: CLI — `list` command

**Files:**
- Modify: `bin/exe-laravel`

**Step 1: Implement the `list` command**

```bash
list)
    result=$(ssh exe.dev ls --json)
    echo "$result" | jq -r '.vms[] | select(.image | contains("exe-laravel")) | "\(.vm_name)\t\(.status)\thttps://\(.vm_name).exe.xyz"' | column -t -s $'\t'
    ;;
```

**Step 2: Commit**

```bash
git add bin/exe-laravel
git commit -m "feat: implement 'list' command in CLI"
```

---

### Task 11: CLI — remaining commands

**Files:**
- Modify: `bin/exe-laravel`

**Step 1: Implement all remaining commands**

```bash
ssh)
    name="${1:?Usage: exe-laravel ssh <name>}"
    ssh "${name}.exe.xyz"
    ;;
open)
    name="${1:?Usage: exe-laravel open <name>}"
    open "https://${name}.exe.xyz" 2>/dev/null || xdg-open "https://${name}.exe.xyz" 2>/dev/null || echo "https://${name}.exe.xyz"
    ;;
share)
    name="${1:?Usage: exe-laravel share <name>}"
    ssh exe.dev share set-public "$name"
    echo "App is now public: https://${name}.exe.xyz"
    ;;
unshare)
    name="${1:?Usage: exe-laravel unshare <name>}"
    ssh exe.dev share set-private "$name"
    echo "App is now private: https://${name}.exe.xyz"
    ;;
destroy)
    name="${1:?Usage: exe-laravel destroy <name>}"
    read -p "Delete VM '$name' and all its data? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh exe.dev rm "$name"
        echo "Deleted: $name"
    else
        echo "Cancelled."
    fi
    ;;
clone)
    name="${1:?Usage: exe-laravel clone <name> [new-name]}"
    new_name="${2:-}"
    if [[ -n "$new_name" ]]; then
        ssh exe.dev cp "$name" "$new_name"
    else
        ssh exe.dev cp "$name"
    fi
    ;;
logs)
    name="${1:?Usage: exe-laravel logs <name>}"
    ssh "${name}.exe.xyz" tail -f /home/exedev/app/storage/logs/laravel.log
    ;;
artisan)
    name="${1:?Usage: exe-laravel artisan <name> <command...>}"
    shift
    ssh "${name}.exe.xyz" "cd /home/exedev/app && php artisan $*"
    ;;
agent)
    name="${1:?Usage: exe-laravel agent <name>}"
    open "https://${name}.exe.xyz:9999/" 2>/dev/null || xdg-open "https://${name}.exe.xyz:9999/" 2>/dev/null || echo "https://${name}.exe.xyz:9999/"
    ;;
```

**Step 2: Commit**

```bash
git add bin/exe-laravel
git commit -m "feat: implement remaining CLI commands"
```

---

### Task 12: Assemble final Dockerfile

**Files:**
- Modify: `Dockerfile`

**Step 1: Assemble all pieces into the final Dockerfile**

Combine all the sections from Tasks 2-8 into a single, clean Dockerfile. Order:

1. FROM exeuntu
2. PHP + extensions + php-fpm config
3. PostgreSQL + setup
4. Composer
5. Node.js 22
6. Redis
7. nginx config
8. Laravel project (as exedev user)
9. AGENTS.md
10. Boot migration service
11. Enable systemd services (nginx, php-fpm, postgresql, redis)
12. EXPOSE ports

**Step 2: Verify the Dockerfile is syntactically valid**

Run: `docker build --check .` (or just attempt a build if on a machine with Docker)

**Step 3: Commit**

```bash
git add Dockerfile
git commit -m "chore: assemble final Dockerfile with all components"
```

---

### Task 13: Build and test the image locally (if Docker available)

**Files:** None (verification only)

**Step 1: Build the image**

Run: `docker build -t exe-laravel:latest .`
Expected: Successful build

**Step 2: Smoke test**

Run: `docker run --rm exe-laravel:latest php -v`
Expected: PHP 8.4.x output

Run: `docker run --rm exe-laravel:latest composer --version`
Expected: Composer version 2.x

Run: `docker run --rm exe-laravel:latest node --version`
Expected: v22.x.x

Run: `docker run --rm exe-laravel:latest ls /home/exedev/app/artisan`
Expected: File exists

**Step 3: Commit any fixes**

If any issues found, fix and commit.

---

### Task 14: Final commit and README

**Files:**
- Create or update: `README.md`

**Step 1: Write a minimal README**

```markdown
# exe-laravel

Laravel on [exe.dev](https://exe.dev). Spin up a live Laravel app in seconds.

## Quick Start

```bash
# Install the CLI
curl -fsSL https://raw.githubusercontent.com/davekiss/exe-laravel/main/bin/exe-laravel -o /usr/local/bin/exe-laravel
chmod +x /usr/local/bin/exe-laravel

# Create a new Laravel app
exe-laravel new my-app

# Open it
exe-laravel open my-app

# Or use the image directly
ssh exe.dev new --image=ghcr.io/davekiss/exe-laravel --name=my-app
```

## Commands

| Command | Description |
|---------|-------------|
| `exe-laravel new [name]` | Create a new Laravel VM |
| `exe-laravel list` | List your Laravel VMs |
| `exe-laravel ssh <name>` | SSH into a VM |
| `exe-laravel open <name>` | Open app in browser |
| `exe-laravel share <name>` | Make app public |
| `exe-laravel unshare <name>` | Make app private |
| `exe-laravel destroy <name>` | Delete a VM |
| `exe-laravel clone <name> [new]` | Copy a VM |
| `exe-laravel logs <name>` | Tail Laravel logs |
| `exe-laravel artisan <name> <cmd>` | Run artisan remotely |
| `exe-laravel agent <name>` | Open Shelley |

## What's in the image

- PHP 8.4 + php-fpm
- PostgreSQL 16
- nginx
- Composer
- Node.js 22 + npm
- Redis
- Fresh Laravel project at `/home/exedev/app`
- Git initialized
- AGENTS.md for coding agents

Built on [exeuntu](https://github.com/boldsoftware/exeuntu) — includes Shelley, Claude Code, Codex, Docker, and more.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with quick start and command reference"
```
