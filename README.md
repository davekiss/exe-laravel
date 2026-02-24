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
