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
git config user.email "exedev@exe.dev"
git config user.name "exedev"
git add -A
git commit -m "Initial Laravel project"
