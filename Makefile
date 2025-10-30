include .env.example
-include .env

.PHONY: help build pull up down start restart stop prune ps shell logs pint artisan composer refresh test apidocs init init-dev post-create

default: up

SHELL := /bin/bash
UNAME := $(shell uname -sm)
DOCKER_COMPOSE := docker compose
COMPOSE_FILES := -f compose.yml -f compose.$(COMPOSE_ENV).yml
DOCKER_COMPOSE_W_FILES = $(DOCKER_COMPOSE) $(COMPOSE_FILES)
PINT_FILE := vendor/vlfesko/laravel-pint-config/pint.json

ifeq ($(UNAME),Darwin arm64)
    COMPOSE_FILES += -f compose.$(COMPOSE_ENV).arm64v8.yml
    export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8
endif

## help	:	Print commands help.
help : Makefile
	@sed -n 's/^##//p' $<

## build	:	Build docker compose images.
build:
	@echo "Building images $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) build

## pull	:	Pull container images.
pull:
	@echo "Pulling container images for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) pull

## up	:	Start up containers.
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) up -d --remove-orphans

## down	:	Stop all containers.
down:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) stop

## start	:	Start containers without updating.
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	$(DOCKER_COMPOSE_W_FILES) start

## restart	:	Restart containers without updating.
restart:
	@echo "Restarting containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) restart $(filter-out $@,$(MAKECMDGOALS))

## stop	:	Stop containers.
##		You can optionally pass an argument with the service name to stop single container
##		stop mariadb	: Stop `mariadb` container.
##		stop mariadb app	: Stop `mariadb` and `app` containers.
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) stop $(filter-out $@,$(MAKECMDGOALS))

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb app	: Prune `mariadb` and `app` containers and remove their volumes.
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE_W_FILES) down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `app` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
shell:
	$(DOCKER_COMPOSE) exec $(or $(filter-out $@,$(MAKECMDGOALS)), 'app') bash

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs app	: View `app` container logs.
##		logs nginx app	: View `nginx` and `app` containers logs.
logs:
	$(DOCKER_COMPOSE) logs -f $(filter-out $@,$(MAKECMDGOALS))

## pint	:	Run Laravel Pint to reformat the app code.
pint:
	$(DOCKER_COMPOSE) exec app php vendor/bin/pint --config $(PINT_FILE)

## artisan	:	Run Laravel Artisan commands.
##		You can pass arguments to artisan
##		artisan migrate	: Run migrations.
##		artisan make:model Post	: Create a Post model.
artisan:
	$(DOCKER_COMPOSE) exec app php artisan $(filter-out $@,$(MAKECMDGOALS))

## composer	:	Run Composer commands.
##		You can pass arguments to composer
##		composer install	: Install dependencies.
##		composer require spatie/laravel-ray	: Require a package.
composer:
	$(DOCKER_COMPOSE) exec app composer $(filter-out $@,$(MAKECMDGOALS))

## refresh	:	Reset database with migrations and seeders.
refresh:
	$(DOCKER_COMPOSE) exec app php artisan migrate:fresh --seed

## test	:	Run application tests using Pest/PHPUnit.
##		You can optionally pass arguments to filter tests
##		test	: Run all tests.
##		test tests/Feature	: Run only Feature tests.
##		test --filter=ApiKeyGenerateCommandTest	: Run specific test class.
test:
	$(DOCKER_COMPOSE) exec app php artisan test $(filter-out $@,$(MAKECMDGOALS))

## apidocs	:	Generate API docs.
apidocs:
	$(DOCKER_COMPOSE) exec -e APP_URL=$(APP_URL_PRODUCTION) -e APP_API_URL=$(APP_API_URL_PRODUCTION) app php artisan scribe:generate

## init	:	Initialize the project by setting up .env files.
init:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
	else \
		echo ".env file already exists. Skipping..."; \
	fi
	@if [ -d src ] &&  [ ! -f src/.env ]; then \
		echo "Creating src/.env file from .env.example..."; \
		cp src/.env.example src/.env; \
	else \
		echo "src/.env file already exists or src folder is missing. Skipping..."; \
	fi

## init	:	Initialize the project by setting up .env, installing mkcert, and generating certificates.
init-dev: init
	@if [ ! -f /usr/local/bin/mkcert ]; then \
		echo "Installing mkcert..."; \
		./docker/certs/bin/install-mkcert; \
	else \
		echo "mkcert already installed. Skipping..."; \
	fi
	@if [ ! -f ./docker/certs/conf/certs/server.crt ]; then \
		echo "Generating certificates..."; \
		cd ./docker/certs/; ./bin/generate-certificates; cd -; \
	else \
		echo "Certificates already exist. Skipping..."; \
	fi

## post-create	:	Run post-create project commands.
post-create:
	$(DOCKER_COMPOSE) exec app composer require -W --dev \
 		laravel-shift/blueprint \
 		jasonmccreary/laravel-test-assertions \
 		larastan/larastan:^3.0 \
 		barryvdh/laravel-debugbar \
 		vlfesko/laravel-pint-config
	$(DOCKER_COMPOSE) exec app composer require spatie/laravel-ray
	$(DOCKER_COMPOSE) exec app php artisan ray:publish-config --docker
	@if [ ! -f src/phpstan.neon.dist ]; then \
		echo "Copy larastan config..."; \
		cp init/phpstan.neon.dist src; \
		echo "Copy blueprint stubs..."; \
		cp -r init/stubs src; \
	fi

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
