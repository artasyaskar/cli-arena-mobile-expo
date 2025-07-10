# Makefile for cli-arena-mobile-expo

# Default shell
SHELL := /bin/bash

# Supabase project ID (if you're using Supabase CLI with a linked project)
# For local-only, this might not be strictly necessary unless specific CLI commands require it.
# SUPABASE_PROJECT_ID := your-project-id

# Docker Compose command
DOCKER_COMPOSE := docker-compose

# App service name in docker-compose.yml
APP_SERVICE_NAME := app

# Default target
.PHONY: all
all: help

# Help target to display available commands
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  setup          : Install dependencies, initialize Supabase local dev environment."
	@echo "  build          : Compile mobile CLI logic (TypeScript, Kotlin, Swift)."
	@echo "  serve          : Run the application logic via CLI."
	@echo "  test           : Run tests (unit and integration tests)."
	@echo "  lint           : Enforce code quality (Kotlin/Swift/TS)."
	@echo "  supabase-start : Start Supabase services using Docker Compose."
	@echo "  supabase-stop  : Stop Supabase services."
	@echo "  supabase-status: Check status of Supabase services."
	@echo "  supabase-logs  : View logs for Supabase services."
	@echo "  clean          : Remove build artifacts and node_modules."

# ------------------------------------------------------------------------------
# Setup and Environment
# ------------------------------------------------------------------------------
.PHONY: setup
setup: supabase-start npm-install supabase-init-db
	@echo "Setup complete. Dependencies installed and Supabase initialized."

.PHONY: npm-install
npm-install: package-lock.json
	@echo "Installing Node.js dependencies..."
	npm ci
	@echo "Node.js dependencies installed."

# If package.json is newer than package-lock.json, it means we might need to update lock file
package-lock.json: package.json
	@echo "package.json is newer than package-lock.json or package-lock.json does not exist. Running npm install..."
	npm install
	@echo "package-lock.json has been updated/created."

# Placeholder for package.json, will be created later
# This ensures npm-install runs at least once if package.json exists
# but no package-lock.json is present.
# Create an empty package.json if it doesn't exist to avoid errors on first run.
# This will be properly managed when we add actual JS/TS code.
# $(shell touch package.json > /dev/null 2>&1)

.PHONY: supabase-init-db
supabase-init-db:
	@echo "Initializing Supabase database schema and seed data..."
	@echo "Waiting for PostgreSQL to be ready..."
	# This is a simple wait. A more robust check would poll pg_isready inside the container.
	# $(DOCKER_COMPOSE) exec -T db bash -c "until pg_isready -U postgres -d postgres; do sleep 1; done"
	# The schema.sql and seed.sql are mounted and should be applied by docker-entrypoint-initdb.d
	# If migrations are handled by Supabase CLI:
	# supabase db reset # This would apply migrations from supabase/migrations
	# supabase db push # If you prefer this flow
	# For now, relying on mounted schema.sql and seed.sql in docker-compose.yml
	@echo "Supabase database initialization relies on volumes in docker-compose.yml for schema and seed."
	@echo "If db was already initialized, these scripts won't re-run unless db volume is cleared."

# ------------------------------------------------------------------------------
# Build, Serve, Test, Lint (Placeholders - to be run inside the app container)
# ------------------------------------------------------------------------------
.PHONY: build
build:
	@echo "Building the application (TypeScript, Kotlin, Swift)..."
	@echo "Running 'make build' inside the Docker container..."
	$(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) bash -c "echo 'TODO: Implement actual build process for TS, Kotlin, Swift'"
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) npm run build
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) ./gradlew build (for Kotlin/Android)
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) xcodebuild build (for Swift/iOS, requires macOS or complex Docker setup)

.PHONY: serve
serve:
	@echo "Serving the application CLI..."
	@echo "Running 'make serve' inside the Docker container..."
	# This should keep the terminal interactive for CLI usage
	$(DOCKER_COMPOSE) exec $(APP_SERVICE_NAME) bash -c "echo 'TODO: Implement actual serve command for the CLI application'"
	# Example: $(DOCKER_COMPOSE) exec $(APP_SERVICE_NAME) node dist/index.js
	# Or, if your Dockerfile's CMD is set up for the CLI:
	# $(DOCKER_COMPOSE) run --rm $(APP_SERVICE_NAME) <command-if-not-default-cmd>

.PHONY: test
test:
	@echo "Running tests..."
	@echo "Running 'make test' inside the Docker container..."
	$(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) bash -c "echo 'TODO: Implement actual test execution (Jest, KotlinTest, XCTest)'"
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) npm test
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) ./gradlew test (for Kotlin/Android)

.PHONY: lint
lint:
	@echo "Linting code (TypeScript, Kotlin, Swift)..."
	@echo "Running 'make lint' inside the Docker container..."
	$(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) bash -c "echo 'TODO: Implement actual linting commands (ESLint, ktlint, SwiftLint)'"
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) npm run lint
	# Example: $(DOCKER_COMPOSE) exec -T $(APP_SERVICE_NAME) ./gradlew ktlintCheck (for Kotlin/Android)

# ------------------------------------------------------------------------------
# Supabase Docker Compose Management
# ------------------------------------------------------------------------------
.PHONY: supabase-start
supabase-start:
	@echo "Starting Supabase services..."
	$(DOCKER_COMPOSE) up -d db auth rest realtime storage-api kong
	@echo "Waiting for Supabase services to initialize..."
	@sleep 15 # Basic wait, consider a more robust health check
	# supabase status # If Supabase CLI is configured and linked
	$(DOCKER_COMPOSE) ps
	@echo "Supabase services started."

.PHONY: supabase-stop
supabase-stop:
	@echo "Stopping Supabase services..."
	$(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "Supabase services stopped."

.PHONY: supabase-status
supabase-status:
	@echo "Supabase service status:"
	$(DOCKER_COMPOSE) ps
	# supabase status # If Supabase CLI is configured and linked

.PHONY: supabase-logs
supabase-logs:
	@echo "Tailing Supabase service logs (Ctrl+C to stop)..."
	$(DOCKER_COMPOSE) logs -f

# ------------------------------------------------------------------------------
# Cleaning
# ------------------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "Cleaning up project..."
	# Add commands to remove build artifacts for TypeScript, Kotlin, Swift
	# e.g., rm -rf dist/ build/ target/
	rm -rf node_modules/
	# Optionally, stop and remove Docker containers/volumes if a deep clean is desired
	# $(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "Cleanup complete."

# Ensure package.json exists for npm-install target dependency check
# This is a bit of a hack. Ideally, package.json would be created by `npm init` or similar.
# We'll create it properly when setting up the Node.js part of the project.
# For now, this prevents `make setup` from failing if `package.json` is missing.
# This line will attempt to create an empty package.json if it doesn't exist.
# It's commented out because `npm install` without a package.json isn't ideal.
# We will create package.json in a later step.
# $(shell test -f package.json || echo "{}" > package.json)
# Consider `npm init -y` as part of the setup if no `package.json` exists.

# Note on Supabase CLI vs Docker Compose:
# This Makefile primarily uses Docker Compose to manage Supabase services for simplicity
# and to avoid requiring the Supabase CLI to be installed and logged in on every developer's machine.
# However, for migrations and other Supabase-specific operations, the Supabase CLI is very powerful.
# You might integrate `supabase start`, `supabase stop`, `supabase db reset`, etc., if you prefer that workflow,
# which would typically be run outside the app container, directly on the host or in a CI step
# that has Supabase CLI configured.
# For this project, we're aiming for Docker Compose to handle the service orchestration.
# Schema and seed data are initially loaded via volume mounts in `docker-compose.yml`.
# For schema changes after initial setup, you'd typically use `supabase/migrations`
# and `supabase db push` or `supabase migration up` if using the Supabase CLI,
# or manually apply SQL scripts if managing schema directly.
# This Makefile currently assumes initial schema/seed load is sufficient for tasks.
# More advanced schema migration management can be added if required.Tool output for `overwrite_file_with_block`:
