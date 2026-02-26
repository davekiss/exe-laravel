# Laravel on exe.dev

You are working on a live Laravel application running on an exe.dev VM.
Changes you make are immediately visible at the VM's public URL.

## Environment

- **App root:** /home/exedev/app
- **Web server:** nginx serving /home/exedev/app/public on port 80
- **PHP:** 8.4 with php-fpm
- **Database:** PostgreSQL 16 with pgvector (database: app, user: exedev, no password, trust auth)
- **Mail:** Resend (`MAIL_MAILER=resend`, add `RESEND_API_KEY` to `.env`)
- **Cache/Queue:** Redis
- **Node.js:** 22 LTS with npm
- **Frontend:** Vite (run `npm run dev` for HMR or `npm run build` for production)
- **Process manager:** supervisord (not systemd)

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

# Services (managed by supervisord)
sudo supervisorctl restart nginx
sudo supervisorctl restart php-fpm
sudo supervisorctl restart postgresql
sudo supervisorctl restart redis
sudo supervisorctl status       # see all service statuses

# Logs
tail -f /home/exedev/app/storage/logs/laravel.log
sudo tail -f /var/log/supervisor/nginx-*.log
sudo tail -f /var/log/supervisor/php-fpm-*.log
```

## Laravel AI SDK

This environment is pre-configured for the [Laravel AI SDK](https://github.com/laravel/ai) (`laravel/ai`):

- **pgvector** is installed and enabled — use `vector` columns for embeddings and similarity search out of the box.
- **Redis** is available for caching embeddings and powering queues.
- **PostgreSQL** supports `Schema::ensureVectorExtensionExists()`, `$table->vector()`, and `whereVectorSimilarTo()`.

To get started:

```bash
composer require laravel/ai
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider"
php artisan migrate
```

Then add API keys to `.env`:

```ini
ANTHROPIC_API_KEY=your-key
OPENAI_API_KEY=your-key
```

Key features: Agents, structured output, streaming, tools, images, audio, transcription, vector embeddings, reranking, and failover across providers.

## Laravel MCP

This environment supports [Laravel MCP](https://github.com/laravel/mcp) (`laravel/mcp`) for exposing your app's capabilities to AI clients via the Model Context Protocol:

```bash
composer require laravel/mcp
php artisan vendor:publish --tag=ai-routes
```

Create servers, tools, resources, and prompts:

```bash
php artisan make:mcp-server MyServer
php artisan make:mcp-tool MyTool
php artisan make:mcp-prompt MyPrompt
php artisan make:mcp-resource MyResource
```

Test with the MCP Inspector: `php artisan mcp:inspector mcp/my-server`

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
- Laravel is configured to trust the proxy via `$middleware->trustProxies(at: '*')` in `bootstrap/app.php`.
- By default, the app is **private** (requires exe.dev login to access).
- To make public: run `ssh exe.dev share set-public <vm-name>` from outside the VM.
- Ports 3000-9999 are also forwarded (e.g., Vite dev server on port 5173).
- Only one port can be made public; additional ports require exe.dev authentication.

## exe.dev Specifics

- HTTPS proxy docs: https://exe.dev/docs/proxy
- Full docs: https://exe.dev/docs
- Only use documented exe.dev features. Undocumented local endpoints are internal infrastructure.
