# Laravel Template

![Laravel](https://img.shields.io/badge/Laravel-12.x-red.svg)
![PHP](https://img.shields.io/badge/PHP-8.3-blue.svg)
![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)
![Wodby](https://img.shields.io/badge/Wodby-2.1.4-green.svg)

This project is a PHP application built using the Laravel framework. It utilizes Docker containers based on the **Wodby Docker Stack v2.1.4** to manage the development environment and ensure consistency across different systems. The project is designed to be portable and easy to set up.

## Table of Contents

- [Environment Information](#environment-information)
- [Docker Services](#docker-services)
- [Quick Start](#quick-start)
- [Getting Started](#getting-started)
- [Available Commands](#available-commands)
- [Environment Variables](#environment-variables)
- [Development Workflows](#development-workflows)
- [Production Deployment](#production-deployment)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)

## Environment Information

This Laravel template is built on:
- **Wodby Docker Stack**: v2.1.4
- **PHP**: 8.3 (configurable for 8.1, 8.2, 8.4)
- **Laravel**: 12.x
- **Database**: MariaDB 11.4
- **Web Server**: Nginx 1.28
- **Cache**: Redis 7.4
- **Node.js**: 22 (for asset compilation)

## Docker Services

The development environment consists of the following services:

| Service | Purpose | Container Name | Access |
|---------|---------|----------------|--------|
| **app** | Main PHP/Laravel application | `{PROJECT_NAME}-app` | Via web service |
| **web** | Nginx web server | `{PROJECT_NAME}-web` | `http://{APP_DOMAIN}` |
| **db** | MariaDB database | `{PROJECT_NAME}-db` | Internal port 3306 |
| **redis** | Cache and session storage | `{PROJECT_NAME}-redis` | Internal port 6379 |
| **worker** | Laravel queue processing | `{PROJECT_NAME}-worker-*` | Background service |
| **cron** | Scheduled task execution | `{PROJECT_NAME}-cron` | Background service |
| **node** | Asset compilation & dev server | `{PROJECT_NAME}-node` | `http://localhost:5173` |
| **mailpit** | Email testing interface | `{PROJECT_NAME}-mailpit` | `http://mailpit.{APP_DOMAIN}` |
| **pma** | PhpMyAdmin database UI | `{PROJECT_NAME}-pma` | `http://pma.{APP_DOMAIN}` |
| **traefik** | Reverse proxy & SSL | `{PROJECT_NAME}-traefik` | `http://traefik.docker.localhost` |

### Service Restart Policies

- **Development**: `restart: on-failure:5` - Services restart up to 5 times on failure
- **Production**: `restart: unless-stopped` - Services restart unless explicitly stopped

## Quick Start

For experienced developers:

```bash
# 1. Clone and setup
git clone <repository-url>
cd laravel-template
make init

# 2. Configure environment
cp .env.example .env
# Edit PROJECT_NAME and PHP_TAG in .env

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

Access your application at the `APP_URL` configured in your `.env` file.

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

To get started with the project, follow these steps:

1. **Clone the repository** to your local machine.
2. **Navigate to the project directory** in your terminal.
3. **Initialize Docker infrastructure:**
   ```bash
   make init        # For production-like setup
   make init-dev    # For development setup
   ```
4. **Configure environment:**
   - Edit `.env` file and set `PROJECT_NAME` to your desired project name (e.g., `my-app`)
   - Uncomment the appropriate PHP tag:
     - **Linux**: Under `# Linux (uid 1000 gid 1000)` section
     - **macOS**: Under `# macOS (uid 501 gid 20)` section (default)
5. **Build and start containers:**
   ```bash
   make build
   make up
   ```

### Fresh Laravel Installation

If this is a fresh installation, prepare a new Laravel application:

1. **Access PHP container:**
   ```bash
   make shell
   ```

2. **Install Laravel installer:**
   ```bash
   composer global require laravel/installer
   ```

3. **Create new Laravel application:**
   ```bash
   laravel new my-app --livewire --pest --force --database mariadb --no-interaction
   ```

4. **Move files to project root** (inside the app container):
   ```bash
   mv my-app/* .
   mv my-app/.* .
   rm -rf my-app/
   ```

5. **Update Vite configuration** in `src/vite.config.js` for proper hot module reload support:
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

6. **Restart node container and verify:**
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
make init          # Initialize Docker infrastructure
make init-dev      # Initialize for development
make build         # Build/pull Docker images
make up           # Start all services
make down         # Stop all services
make restart      # Restart all services
make restart <service>  # Restart specific service
```

### Development Tools
```bash
make shell        # Access PHP container bash
make shell-root   # Access PHP container as root
make logs         # View all container logs
make logs <service>  # View specific service logs
make ps           # Show running containers
```

### Cleanup
```bash
make prune        # Clean up Docker system
```

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_NAME` | Unique project identifier | `my-app` |
| `APP_DOMAIN` | Application domain | `my-app.docker.localhost` |
| `APP_URL` | Full application URL | `https://my-app.docker.localhost` |
| `DB_DATABASE` | Database name | `laravel` |
| `DB_USERNAME` | Database user | `laravel` |
| `DB_PASSWORD` | Database password | `laravel` |

### Service Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PHP_TAG` | PHP version tag | `8.3-dev-macos-4.56.7` |
| `NGINX_TAG` | Nginx version tag | `1.28-5.42.0` |
| `MARIADB_TAG` | MariaDB version tag | `11.4-3.31.0` |
| `NODE_TAG` | Node.js version tag | `22-dev-1.50.0` |
| `REDIS_TAG` | Redis version tag | `7.4.3-alpine` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_TIMEZONE` | Application timezone | `Europe/Kyiv` |
| `RAY_ENABLED` | Enable Spatie Ray debugging | `true` |
| `RAY_HOST` | Ray server host | `host.docker.internal` |
| `RAY_LOCAL_PATH` | Local project path for Ray | `/path/to/project/src` |

## Development Workflows

### Asset Compilation

The Node.js service handles asset compilation with Vite:

```bash
# Development mode (watch)
make logs node  # Assets compile automatically

# Production build
make shell
npm run build
```

### Database Operations

```bash
# Run migrations
make artisan migrate

# Seed database
make artisan db:seed

# Create migration
make artisan make:migration create_posts_table

# Fresh migration with seeding
make artisan migrate:fresh --seed
```

### Queue Management

The worker service automatically processes queues. To manage queues:

```bash
# View queue status
make artisan queue:work --once

# Clear failed jobs
make artisan queue:clear

# Restart workers (after code changes)
make restart worker
```

### Cron Jobs

Scheduled tasks are managed by the cron service. Edit `docker/conf/cron/crontab` to add tasks:

```bash
# Example: Run Laravel scheduler every minute
* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1
```

## Production Deployment

### Environment Setup

1. **Copy production environment:**
   ```bash
   cp .env.example .env.app.production
   ```

2. **Configure production variables** in `.env.app.production`:
   - Set `APP_ENV=production`
   - Set `APP_DEBUG=false`
   - Configure secure database credentials
   - Set proper `APP_URL` and `APP_DOMAIN`

3. **Deploy with production compose:**
   ```bash
   docker-compose -f compose.yml -f compose.production.yml up -d
   ```

### SSL Configuration

The template includes Traefik with SSL support:

1. **Place SSL certificates** in `docker/certs/conf/certs/`
2. **Update certificate configuration** in `docker/certs/conf/certs-traefik.yml`
3. **Enable HTTPS redirects** via Traefik middlewares

### Production Considerations

- Services use `restart: unless-stopped` policy
- Logs are persistent in `src/storage/logs`
- Database data is stored in `docker/data/mariadb`
- Redis data is ephemeral (configure persistence if needed)

## File Structure

```
laravel-template/
├── docker/                    # Docker infrastructure
│   ├── certs/                # SSL certificates and Traefik config
│   ├── conf/                 # Service configurations
│   │   ├── cron/            # Crontab configuration
│   │   └── php/             # PHP/Bash configuration
│   └── data/                # Persistent data storage
├── docker4php/              # Wodby stack reference
├── init/                    # Initialization scripts and stubs
├── src/                     # Laravel application source
│   ├── app/                 # Laravel app directory
│   ├── config/              # Configuration files
│   ├── database/            # Migrations, factories, seeders
│   ├── public/              # Web root
│   ├── resources/           # Views, assets, lang files
│   ├── routes/              # Route definitions
│   ├── storage/             # Logs, cache, uploads
│   └── tests/               # Test files
├── .env                     # Environment variables
├── .env.example             # Environment template
├── .env.app                 # App-specific variables
├── .env.app.production      # Production variables
├── compose.yml              # Base Docker services
├── compose.local.yml        # Local development overrides
├── compose.production.yml   # Production overrides
├── Makefile                 # Docker command shortcuts
└── README.md               # This file
```

### Key Configuration Files

- **`.env*`**: Environment variables for different contexts
- **`compose*.yml`**: Docker service definitions
- **`Makefile`**: Convenient command shortcuts
- **`docker/conf/`**: Service-specific configurations
- **`src/`**: Standard Laravel application structure

## Install Additional Components

Run `make post-create` to install additional composer packages and run setup commands. It will install:

- **`laravel-shift/blueprint`**: Database modeling and code generation
- **`larastan/larastan`**: Static analysis for Laravel
- **`barryvdh/laravel-debugbar`**: Debug toolbar for development
- **`vlfesko/laravel-pint-config`**: Code style configuration
- **`spatie/laravel-ray`**: Advanced debugging tool

### Spatie Ray Setup

If using Spatie Ray for debugging:

1. **Adjust the local path** in `.env:RAY_LOCAL_PATH` to point to your project sources
2. **Configure firewall** on Linux:
   ```bash
   sudo ufw allow 23517/tcp
   # Or for specific container network:
   sudo ufw allow from 172.30.0.0/16 to 172.17.0.1 port 23517 proto tcp
   ```

## Using Laravel Pint with PHPStorm

1. **Add PHP CLI Interpreter** using Docker:
   - Use image: `wodby/php:8.3-dev-macos-4.56.7`
   - Configure Docker server (OrbStack for macOS)

2. **Configure Laravel Pint**:
   - Enable Laravel Pint inspection in PHP Quality Tools
   - Set configuration path: `/opt/project/src/vendor/vlfesko/laravel-pint-config/pint.json`
   - Select preset: `laravel`

## Troubleshooting

### Common Issues

**Port Conflicts**
```bash
# Check for conflicting processes
lsof -i :80 -i :443 -i :3306

# Stop conflicting services
sudo systemctl stop apache2 nginx mysql
```

**Permission Issues (Linux)**
```bash
# Fix file permissions
sudo chown -R $USER:$USER src/
sudo chmod -R 755 src/storage src/bootstrap/cache
```

**Database Connection Issues**
```bash
# Check database service status
make logs db

# Reset database
make down
docker volume prune
make up
```

**Asset Compilation Problems**
```bash
# Clear node_modules and reinstall
make shell
rm -rf node_modules package-lock.json
npm install
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
