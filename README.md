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

Your app is immediately live at `https://<name>.exe.xyz`. SSH in and start building:

```bash
ssh my-app.exe.xyz
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
- PostgreSQL 16 + pgvector
- nginx
- Composer + Laravel installer
- Node.js 22 + npm
- Redis
- Resend mail driver (pre-configured)
- [Laravel Boost](https://github.com/laravel/boost) for AI-assisted development

When you run `exe-laravel new`, the CLI creates a VM from the image, waits for SSH, then runs `laravel new` with your chosen flags. The app is created at `/home/exedev/app` with PostgreSQL configured, migrations run, and git initialized.

## AI-Ready

Every VM is pre-configured for building AI-native Laravel apps:

- **[Laravel AI SDK](https://github.com/laravel/ai)** — pgvector is installed and the `vector` extension is enabled. Just `composer require laravel/ai` and start using agents, embeddings, structured output, and more.
- **[Laravel MCP](https://github.com/laravel/mcp)** — expose your app's capabilities to AI clients via the Model Context Protocol. `composer require laravel/mcp` to get started.
- **[Laravel Boost](https://github.com/laravel/boost)** — included by default. Provides MCP tools for inspecting your app, querying the database, and searching Laravel docs.

## Workflow

Each VM is a live server. There is no deployment pipeline. Create a VM, SSH in, and start coding — changes are immediately live.

```bash
exe-laravel new my-app --react     # create VM + install Laravel
ssh my-app.exe.xyz                 # SSH in and start building
# edit code, run artisan/npm — app is always live
```

The app lives at `/home/exedev/app`. PHP changes are instant. Run `npm run build` after frontend changes. See `AGENTS.md` in the app root for full environment details.
