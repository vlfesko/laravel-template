# Laravel Template

![Laravel](https://img.shields.io/badge/Laravel-12.x-red.svg)
![PHP](https://img.shields.io/badge/PHP-8.3-blue.svg)
![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)
![Wodby](https://img.shields.io/badge/Wodby-2.1.9-green.svg)

*Last updated: February 20, 2026*

This project is a PHP application built using the Laravel framework. It utilizes Docker containers based on the **Wodby Docker Stack** to manage the development environment and ensure consistency across different systems. The project is designed to be portable and easy to set up.

## Quick Start

For experienced developers:

```bash
# 1. Clone and setup
git clone <repository-url>
cd laravel-template
make init

# 2. Configure environment
# Edit PROJECT_NAME, PHP_TAG and any other values in .env

# 3. Start services
make build && make up

# 4. Setup Laravel (if fresh install)
make shell
composer global require laravel/installer
laravel new my-app --livewire --pest --force --database mariadb --no-interaction
mv my-app/* . && mv my-app/.* . && rm -rf my-app/
exit

# 5. Install additional packages
make post-create

# 6. Configure Vite and restart node
make restart node
```

Access your application at the `X_APP_URL` configured in your `.env` file.

## Getting Started

### Pre-Requisites

You must have installed on your system:

1. **Docker**, [native](https://docs.docker.com/engine/install/) or [OrbStack](https://docs.orbstack.dev/install). On MacOS it is
   preferable to install OrbStack:
    ```bash
    brew install --cask orbstack
    ```

2. **make**
    ```bash
    brew install make
    ```

### Setup Process

**Update Vite configuration** in `src/vite.config.js` for proper hot module reload support:
   ```javascript
   import { defineConfig } from 'vite';
   import laravel from 'laravel-vite-plugin';
   import tailwindcss from "@tailwindcss/vite";
   
   export default defineConfig(({ command }) => {
       const config = {
           plugins: [
               laravel({
                   input: ['resources/css/app.css', 'resources/js/app.js'],
                   refresh: [`resources/views/**/*`],
               }),
               tailwindcss(),
           ],
           server: {
               cors: true,
               host: true,
           },
       };
   
       if (command !== 'build') {
           config.server.hmr = {
               host: "my-app.docker.localhost"  // Replace with your APP_DOMAIN
           };
       }
   
       return config;
   });
   ```

**Restart node container and verify:**
   ```bash
   exit  # Exit app container shell
   make restart node
   make logs node
   ```
   Open your browser at the `APP_URL` displayed in the container.

## Available Commands

The project uses a Makefile for common Docker operations:

### Container Management
```bash
make init                  # Initialize Docker infrastructure
make build                 # Build Docker compose images
make pull                  # Pull container images
make up                    # Start all containers (default command)
make down                  # Stop all containers
make start                 # Start containers without updating
make restart               # Restart all containers
make restart <service>     # Restart specific service
make stop                  # Stop all containers
make stop <service>        # Stop specific service
make prune                 # Remove containers and their volumes
make prune <service>       # Remove specific container and its volumes
make ps                    # List running containers
```

### Development Tools
```bash
make shell                 # Access app container via bash
make shell <service>       # Access specific container via bash
make logs                  # View all container logs
make logs <service>        # View specific service logs
make artisan <command>     # Run Laravel Artisan commands
make composer <command>    # Run Composer commands
make pint                  # Run Laravel Pint to format code
make post-create           # Install additional dev packages
make test                  # Run Laravel test suite
```

## Troubleshooting

### Common Issues

**Permission Issues (Linux)**
```bash
# Fix file permissions
sudo chown -R $USER:$USER src/
sudo chmod -R 755 src/storage src/bootstrap/cache
```

**Container Won't Start**
```bash
# Check service logs
make logs <service-name>

# Restart specific service
make restart <service-name>

# Complete restart
make down && make up
```

### Log Files

Application logs are written to files under `src/storage/logs/`:

```bash
# View Laravel logs
tail -f src/storage/logs/laravel.log

# View all container logs
make logs

# View specific service logs
make logs app
make logs web
make logs db
```

### Service Health Checks

```bash
# Check all running services
make ps

# Test database connection
make shell
php artisan tinker
DB::connection()->getPdo();

# Test Redis connection
redis-cli -h redis ping
```

---

For additional help or to report issues, please check the project documentation or create an issue in the repository.
