SHELL := /bin/bash

DOCKER_COMPOSE := sudo docker-compose
APP_SERVICE_NAME := cli

.PHONY: all
all: help

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  setup          : Install dependencies, initialize Supabase local dev environment."
	@echo "  build          : Compile mobile CLI logic (TypeScript)."
	@echo "  serve          : Run the application logic via CLI."
	@echo "  test           : Run tests (unit and integration)."
	@echo "  lint           : Lint code (ESLint)."
	@echo "  supabase-start : Start Supabase services."
	@echo "  supabase-stop  : Stop Supabase services."
	@echo "  supabase-status: Check status of Supabase services."
	@echo "  supabase-logs  : View logs for Supabase services."
	@echo "  clean          : Remove build artifacts and node_modules."

.PHONY: setup
setup: supabase-start npm-install supabase-init-db
	@echo "Setup complete."

.PHONY: npm-install
npm-install: package-lock.json
	@echo "Installing Node.js dependencies..."
	npm ci
	@echo "Dependencies installed."

package-lock.json: package.json
	@echo "package.json is newer, running npm install..."
	npm install

.PHONY: supabase-init-db
supabase-init-db:
	@echo "Initializing Supabase DB..."
	@echo "Using docker-compose volumes for schema.sql + seed.sql."
	@echo "To force re-initialization, run 'make supabase-stop' then 'make setup' again."

.PHONY: build
build:
	@echo "Building CLI (TypeScript)..."
	$(DOCKER_COMPOSE) run --rm -T $(APP_SERVICE_NAME) npm run build

.PHONY: serve
serve:
	@echo "Serving CLI..."
	$(DOCKER_COMPOSE) run --rm $(APP_SERVICE_NAME) node dist/index.js

.PHONY: test
test:
	@echo "Running tests with Jest..."
	$(DOCKER_COMPOSE) run --rm -T $(APP_SERVICE_NAME) npm test

.PHONY: lint
lint:
	@echo "Linting with ESLint..."
	$(DOCKER_COMPOSE) run --rm -T $(APP_SERVICE_NAME) npm run lint

.PHONY: supabase-start
supabase-start:
	@echo "Starting Supabase services..."
	$(DOCKER_COMPOSE) up -d db auth rest realtime storage-api api-gateway
	@sleep 10
	$(DOCKER_COMPOSE) ps
	@echo "Supabase services started."

.PHONY: supabase-stop
supabase-stop:
	@echo "Stopping Supabase services..."
	$(DOCKER_COMPOSE) down -v --remove-orphans

.PHONY: supabase-status
supabase-status:
	@echo "Supabase service status:"
	$(DOCKER_COMPOSE) ps

.PHONY: supabase-logs
supabase-logs:
	@echo "Tailing Supabase logs (Ctrl+C to stop)..."
	$(DOCKER_COMPOSE) logs -f

.PHONY: clean
clean:
	@echo "Cleaning up..."
	rm -rf dist/ node_modules/
	@echo "Clean complete."
