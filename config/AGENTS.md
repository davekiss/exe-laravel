# Laravel on exe.dev

You are working on a live Laravel application running on an exe.dev VM.
Changes you make are immediately visible at the VM's public URL.

## Environment

- **App root:** /home/exedev/app
- **Web server:** nginx serving /home/exedev/app/public on port 80
- **PHP:** 8.4 with php-fpm
- **Database:** PostgreSQL 16 (database: app, user: exedev, no password, trust auth)
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
psql app                        # connect to database
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

## Laravel Boost

This project includes [Laravel Boost](https://github.com/laravel/boost) for AI-assisted development.

- **MCP Server:** `php artisan boost:mcp` — provides tools for inspecting the app, querying the database, searching Laravel docs, and more.
- **Documentation API:** Use the `Search Docs` MCP tool to look up Laravel framework and ecosystem documentation.
- **Guidelines:** Boost-generated guidelines are in `CLAUDE.md` (for Claude Code) and agent-specific locations.
- **Skills:** Agent skills for Livewire, Pest, Tailwind, etc. are installed based on project dependencies.
- **Update:** Run `php artisan boost:update` after adding new packages to refresh guidelines and skills.

## Conventions

- This is a live server. Test changes carefully.
- Commit frequently with descriptive messages.
- Use `php artisan` for all Laravel scaffolding.
- Database migrations go in `database/migrations/`.
- The app uses PostgreSQL — use PostgreSQL-compatible SQL.
- The `.env` file is already configured. Don't change DB settings unless adding a new database.

## exe.dev HTTPS Proxy

This app is served through exe.dev's reverse proxy:
- exe.dev terminates TLS and proxies HTTPS requests to nginx on port 80.
- The proxy sends `X-Forwarded-Proto`, `X-Forwarded-Host`, and `X-Forwarded-For` headers.
- `TRUSTED_PROXIES=*` is set in `.env` so Laravel trusts these headers.
- By default, the app is **private** (requires exe.dev login to access).
- To make public: run `ssh exe.dev share set-public <vm-name>` from outside the VM.
- Ports 3000-9999 are also forwarded (e.g., Vite dev server on port 5173).
- Only one port can be made public; additional ports require exe.dev authentication.

## exe.dev Specifics

- HTTPS proxy docs: https://exe.dev/docs/proxy
- Full docs: https://exe.dev/docs
- Only use documented exe.dev features. Undocumented local endpoints are internal infrastructure.
