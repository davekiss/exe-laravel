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
