include .env.example
-include .env
-include Makefile.project.mk

.PHONY: help build pull up down start restart stop prune ps shell logs init-env

default: up

SHELL := /bin/bash
UNAME := $(shell uname -sm)
DEFAULT_CONTAINER := $(or $(MAKEFILE_DEFAULT_CONTAINER),app)
ifneq ($(shell which docker-compose),)
    DOCKER_COMPOSE := docker-compose
else
    DOCKER_COMPOSE := docker compose
endif
COMPOSE_FILES := -f compose.yaml
ifneq ($(wildcard compose.$(COMPOSE_ENV).yaml),)
    COMPOSE_FILES += -f compose.$(COMPOSE_ENV).yaml
endif

ifeq ($(UNAME),Darwin arm64)
    ifneq ($(wildcard compose.$(COMPOSE_ENV).arm64v8.yaml),)
        COMPOSE_FILES += -f compose.$(COMPOSE_ENV).arm64v8.yaml
    endif
    export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8
endif

ifneq ($(wildcard compose.override.yaml),)
    COMPOSE_FILES += -f compose.override.yaml
endif

DOCKER_COMPOSE_W_FILES = $(DOCKER_COMPOSE) $(COMPOSE_FILES)

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

## shell	:	Access `$(DEFAULT_CONTAINER)` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
shell:
	$(DOCKER_COMPOSE) exec $(or $(filter-out $@,$(MAKECMDGOALS)), $(DEFAULT_CONTAINER)) sh

## logs	:	View containers logs.
##		You can optionally pass an argument with the service name to limit logs
##		logs app	: View `app` container logs.
##		logs nginx app	: View `nginx` and `app` containers logs.
logs:
	$(DOCKER_COMPOSE) logs -f $(filter-out $@,$(MAKECMDGOALS))

## init-env	:	Initialize the project environment
init-env:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
	else \
		echo ".env file already exists. Skipping..."; \
	fi

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
