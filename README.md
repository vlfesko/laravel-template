# Laravel Template

This project is a PHP application built using the Laravel framework. It utilizes Docker containers to manage the development
environment and ensure consistency across different systems. The project is designed to be portable and easy to set up.

## Project Structure

The project is structured as follows:

- `src`: The main source code directory containing the application's PHP files.
- `compose*.yml`: The Docker Compose file that defines the services and their configurations.
- `Makefile`: The Docker Compose CLI entry point.
- `.env.example`: A file containing environment variables that are used by the Docker containers, should be copied to `.env` and
  managed locally.

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
1. Copy `.env.example` to `.env`.
1. Copy `src/.env.example` to `src/.env`.
1. Run `make up` to start the Docker containers.
1. Run `make shell` to get bash inside PHP container.
1. Run `composer install --prefer-dist` to install the project's dependencies.
1. Run `php artisan migrate` to install or update project's database schema. Whenever you need to cleanup database and start from scratch, run `php artisan migrate:fresh` to delete and recreate all tables. If you setting up local environment, to get test data add `--seed` argument to migrate command.

## Example run

- Run `make shell` to get bash inside PHP container.

## Log files

Logs are written to files under `src/storage/logs`.
