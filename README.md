# exe-laravel

Laravel on [exe.dev](https://exe.dev). Spin up a live Laravel app in seconds.

## Quick Start

```bash
# Install the CLI
curl -fsSL https://raw.githubusercontent.com/davekiss/exe-laravel/main/bin/exe-laravel -o /usr/local/bin/exe-laravel
chmod +x /usr/local/bin/exe-laravel

# Create a new Laravel app
exe-laravel new my-app

# With a starter kit
exe-laravel new my-app --react
exe-laravel new my-app --vue --pest
exe-laravel new my-app --livewire

# Open it
exe-laravel open my-app
```

## Commands

| Command | Description |
|---------|-------------|
| `exe-laravel new [name] [flags]` | Create a new Laravel VM |
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

## Starter Kit Flags

Pass these flags to `exe-laravel new` to choose a starter kit:

| Flag | Description |
|------|-------------|
| `--react` | Inertia + React |
| `--vue` | Inertia + Vue |
| `--livewire` | Livewire |
| `--pest` | Use Pest for testing |
| `--typescript` | Use TypeScript (with React/Vue) |

These flags are passed directly to `laravel new`. Any flag supported by `laravel new` will work.

## How It Works

Each VM is created from a Docker image with all infrastructure pre-installed. No app is baked in — the Laravel app is created at runtime via `laravel new`.

**What's in each VM:**

- PHP 8.4 + php-fpm
- PostgreSQL 16
- nginx
- Composer
- Laravel installer
- Node.js 22 + npm
- Redis
- AGENTS.md for coding agents

When you run `exe-laravel new`, the CLI creates a VM from the image, waits for SSH, then runs `laravel new` with your chosen flags. The app is created at `/home/exedev/app` with PostgreSQL configured, migrations run, and git initialized.
