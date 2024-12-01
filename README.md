# Laravel Template

This project is a PHP application built using the Laravel framework. It utilizes Docker containers to manage the development
environment and ensure consistency across different systems. The project is designed to be portable and easy to set up.

## Project Structure

The project is structured as follows:

- `docker`: Docker infrastructure files.
- `src`: The main source code directory containing the application's PHP files.
- `.env*` files: Contain environment variables used by the Docker containers.
- `compose*.yml`: The Docker Compose file that defines the services and their configurations.
- `Makefile`: The Docker Compose CLI entry point.

## Getting Started

### Pre-Requisites

You must have installed on your system:

1. Docker, [native](https://docs.docker.com/engine/install/) or [OrbStack](https://docs.orbstack.dev/install). On MacOS it is preferable to install OrbStack:
    ```
    brew install --cask orbstack
    ```
   
1. `make`
    ```
    brew install make
    ```

To get started with the project, follow these steps:

1. Clone the repository to your local machine.
1. Navigate to the project directory in your terminal.
1. Run `make init` or `make init-dev` to initialize Docker infrastructure.
1. Edit `.env` file and set `PROJECT_NAME` to your desired project name (`my-app`).
1. Run `make build` to pull and build Docker images.
1. Run `make up` to start the Docker containers.

If it is fresh installation, prepare new Laravel application:

1. Run `make shell` to get bash inside PHP container.
1. Run `composer global require laravel/installer` to install Laravel installer.
1. Create new Laravel application and follow installer prompts. At this point the database is ready and migrations can be executed.

   ```
   laravel new my-app --stack=livewire --jet --api --teams --verification --pest --force --database=mysql
   ```

1. Move files from `my-app` directory to the project source root and remove `my-app` directory:

   ```
   mv my-app/* .
   mv my-app/.* .
   rm -rf my-app/
   ```

1. Update `src/vite.config.js`, add `server` section for proper hot module reload support:
    
    ```
    export default defineConfig(({ command }) => {
        const config = {
            plugins: [
                laravel({
                    input: [
                        'resources/css/app.css',
                        'resources/js/app.js',
                    ],
                    refresh: true,
                }),
            ],
            server: {
                host: true,
            }
        };
    
        if (command !== 'build') {
            config.server.hmr = {
                host: "my-app.docker.localhost"
            };
        }
    
        return config;
    });

1. Restart node container `make restart node`  and open your browser at https://my-app.docker.localhost/.

## Example run

- Run `make shell` to get bash inside PHP container.

## Log files

Logs are written to files under `src/storage/logs`.
