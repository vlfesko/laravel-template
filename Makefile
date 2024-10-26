include .env.example
-include .env

.PHONY: up down stop prune ps shell logs

default: up

SHELL := /bin/bash
UNAME := $(shell uname -sm)
DOCKER_COMPOSE := docker compose
DOCKER_FILES = -f compose.yml -f compose.$(COMPOSE_ENV).yml

ifeq ($(UNAME),Darwin arm64)
    DOCKER_FILES += -f compose.$(COMPOSE_ENV).arm64v8.yml
    export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8
endif

## help	:	Print commands help.
help : Makefile
	@sed -n 's/^##//p' $<

## build	:	Build PHP image with Node.js.
build:
	@echo "Building images $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) build
	@echo "Installing PHP composer packages..."
	docker run --rm -it -v ./src:/var/www/html:cached wodby/php:$(PHP_TAG) composer install --prefer-dist

## pull	:	Pull container images.
pull:
	@echo "Pulling container images for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) pull

## up	:	Start up containers.
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) up -d --remove-orphans

## down	:	Stop all containers.
down:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) stop

## start	:	Start containers without updating.
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) start

## stop	:	Stop containers.
##		You can optionally pass an argument with the service name to stop single container
##		stop mariadb	: Stop `mariadb` container.
##		stop mariadb app	: Stop `mariadb` and `app` containers.
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) stop $(filter-out $@,$(MAKECMDGOALS))

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb app	: Prune `mariadb` and `app` containers and remove their volumes.
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	$(DOCKER_COMPOSE) $(DOCKER_FILES) down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `app` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)-$(or $(filter-out $@,$(MAKECMDGOALS)), 'app')' --format "{{ .ID }}") bash

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs app	: View `app` container logs.
##		logs nginx app	: View `nginx` and `app` containers logs.
logs:
	@docker compose logs -f $(filter-out $@,$(MAKECMDGOALS))

## init	:	Initialize the project by setting up .env files.
init:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
	else \
		echo ".env file already exists. Skipping..."; \
	fi
	@if [ ! -f src/.env ]; then \
		echo "Creating src/.env file from .env.example..."; \
		cp src/.env.example src/.env; \
	else \
		echo "src/.env file already exists. Skipping..."; \
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

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
