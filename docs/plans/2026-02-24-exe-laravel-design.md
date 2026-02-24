# exe-laravel Design

**Date:** 2026-02-24
**Status:** Approved

## Problem

The traditional deploy pipeline (local dev → push to GitHub → CI → staging → production) adds friction that doesn't serve small-to-medium projects well. For rapid prototyping and agent-driven development, the environment where you develop should BE the environment where the app runs.

Laravel Herd solves local development. Forge/Vapor solve deployment. exe-laravel eliminates the gap between them by making the server the development environment.

## Core Idea

A custom exe.dev VM image pre-loaded with a full Laravel stack, paired with a thin CLI, so that `exe-laravel new my-app` gives you a live Laravel app in ~2 seconds — ready for an agent to start building on.

No CI/CD. No staging. No deploy step. Develop in situ.

## Target User

Individual developers (initially the author) who want to spin up Laravel apps quickly on exe.dev VMs and develop them directly on the server using coding agents (Shelley, Claude Code, Codex, etc.).

## Architecture

Two components:

1. **`exe-laravel` container image** — Built on exeuntu, adds the Laravel stack
2. **`exe-laravel` CLI** — Thin shell script wrapping `ssh exe.dev` commands

### Workflow

```
exe-laravel new my-saas
  → VM boots (~2s), Laravel is live at https://my-saas.exe.xyz
  → Open Shelley or SSH in with Claude Code
  → Agent builds the app directly on the server
  → Every change is immediately live
  → Agent commits to local git as it goes
  → When ready: exe-laravel share my-saas → public
```

## Component 1: The Image

Built on `exeuntu` (Ubuntu 24.04 + systemd + Shelley + Claude Code + Codex + Docker + nginx + dev tools).

### Added by exe-laravel image

**Runtime:**
- PHP 8.3+ with extensions: pgsql, mbstring, xml, curl, zip, bcmath, intl, redis, gd
- PostgreSQL 16 (auto-started via systemd)
- Composer 2.x
- Node.js 22 LTS + npm (for Vite/frontend)
- Redis (for queues/cache)

**Laravel setup:**
- Fresh Laravel project at `/home/exedev/app`
- nginx configured to serve `/home/exedev/app/public` on port 80
- `.env` pre-configured for PostgreSQL (database created, user configured)
- Git repo initialized with initial commit
- php-fpm for production-grade serving (not `artisan serve`)

**Agent guidance:**
- `AGENTS.md` at `/home/exedev/app/AGENTS.md` with Laravel conventions
- Tells agents this is a live server and changes are immediately visible

**Ports:**
- 80: nginx → Laravel (proxied by exe.dev to HTTPS)
- 5432: PostgreSQL (local only)
- 9999: Shelley (inherited from exeuntu)

### Image distribution

Published to GitHub Container Registry at `ghcr.io/davekiss/exe-laravel`.
Used via: `ssh exe.dev new --image=ghcr.io/davekiss/exe-laravel`

**Future:** When exe.dev offers VM templates, this image becomes a template. The CLI abstracts this detail.

## Component 2: The CLI

A single shell script (`exe-laravel`). Dependencies: `ssh`, `jq`.

### Commands

| Command | Description |
|---------|-------------|
| `exe-laravel new [name]` | Create a VM with the exe-laravel image |
| `exe-laravel list` | List Laravel VMs |
| `exe-laravel ssh <name>` | SSH into a VM |
| `exe-laravel open <name>` | Open the app URL in browser |
| `exe-laravel share <name>` | Make app publicly accessible |
| `exe-laravel unshare <name>` | Return to private access |
| `exe-laravel destroy <name>` | Delete the VM |
| `exe-laravel clone <name> [new-name]` | Copy a VM (branch an experiment) |
| `exe-laravel logs <name>` | Tail Laravel logs via SSH |
| `exe-laravel artisan <name> <cmd>` | Run artisan commands remotely |
| `exe-laravel agent <name>` | Open Shelley in browser (port 9999) |

### Implementation

Each command maps directly to one or two `ssh exe.dev` commands. The CLI adds:
- Filtering `ls` output to show only exe-laravel VMs
- URL construction and `open` command for convenience
- Artisan passthrough over SSH
- Friendly output formatting

## Versioning and Backup

- Git runs on the VM; agents commit as they work
- `exe-laravel clone` snapshots entire VMs for safe experimentation
- Users can `git push` to GitHub whenever they want, but it's not required
- No automatic sync — the VM is the source of truth

## Non-Goals (for v1)

- Web dashboard (maybe later)
- Multi-user team management
- Database backups/migrations between VMs
- Custom domain management (use exe.dev's built-in support directly)
- Multiple PHP versions
