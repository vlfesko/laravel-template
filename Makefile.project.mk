.PHONY: pint artisan composer refresh test apidocs init post-create tail-logs deploy migrate

PINT_FILE := vendor/vlfesko/laravel-pint-config/pint.json

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
	$(DOCKER_COMPOSE) exec app php artisan config:clear
	$(DOCKER_COMPOSE) exec -e DB_CONNECTION=mariadb -e DB_HOST=$(COMPOSE_PROJECT_NAME)-db-test -e DB_DATABASE=test app php artisan test $(filter-out $@,$(MAKECMDGOALS))

## apidocs	:	Generate API docs.
apidocs:
	$(DOCKER_COMPOSE) exec -e APP_URL=$(X_APP_URL_PRODUCTION) -e APP_API_URL=$(X_APP_API_URL_PRODUCTION) app php artisan scribe:generate

## init	:	Initialize the project by setting up .env files.
init: init-env
	@if [ -d src ] &&  [ ! -f src/.env ]; then \
		echo "Creating src/.env file from .env.example..."; \
		cp src/.env.example src/.env; \
	else \
		echo "src/.env file already exists or src folder is missing. Skipping..."; \
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

## tail-logs	:	Follow all Laravel log files.
tail-logs:
	tail -f src/storage/logs/*.log

## deploy	:	Deploy the application with git pull, migrations, lighthouse cache refresh, worker restart, and container startup.
deploy:
	@echo "Starting deployment for $(PROJECT_NAME)..."
	@echo "1. Pulling latest changes from git..."
	git pull
	@echo "2. Updating composer..."
	$(DOCKER_COMPOSE) exec app composer install --prefer-dist --no-interaction
	@echo "3.1. Running main database migrations (forced)..."
	$(DOCKER_COMPOSE) exec app php artisan migrate --force
	@echo "4. Clearing Lighthouse schema cache..."
	$(DOCKER_COMPOSE) exec app php artisan lighthouse:clear-cache
	@echo "5. Rebuilding Lighthouse schema cache..."
	$(DOCKER_COMPOSE) exec app php artisan lighthouse:cache
	@echo "6. Restarting worker container..."
	$(DOCKER_COMPOSE_W_FILES) restart worker
	@echo "Restarting node container..."
	$(DOCKER_COMPOSE_W_FILES) restart node
	@echo "7. Starting up containers..."
	$(DOCKER_COMPOSE_W_FILES) up -d --remove-orphans
	@echo "✅ Deployment completed successfully!"

## migrate	:	Migrate the application database with lighthouse cache refresh, worker restart.
migrate:
	@echo "Starting migration for $(PROJECT_NAME)..."
	@echo "Running main database migrations (forced)..."
	$(DOCKER_COMPOSE) exec app php artisan migrate --force
	@echo "Clearing Lighthouse schema cache..."
	$(DOCKER_COMPOSE) exec app php artisan lighthouse:clear-cache
	@echo "Rebuilding Lighthouse schema cache..."
	$(DOCKER_COMPOSE) exec app php artisan lighthouse:cache
	@echo "Restarting worker container..."
	$(DOCKER_COMPOSE_W_FILES) restart worker
	@echo "Restarting node container..."
	$(DOCKER_COMPOSE_W_FILES) restart node
	@echo "Starting up containers..."
	$(DOCKER_COMPOSE_W_FILES) up -d --remove-orphans
	@echo "✅ Migration completed successfully!"
