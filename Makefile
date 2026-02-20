# VoxGuard Platform Monorepo

.PHONY: help install dev build test lint clean docker codegen

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
NC     := \033[0m

help: ## Display this help
	@echo "$(BLUE)VoxGuard Platform - Monorepo Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# ============================================================================
# Setup & Installation
# ============================================================================

install: ## Install all dependencies
	@echo "$(YELLOW)Installing pnpm dependencies...$(NC)"
	pnpm install
	@echo "$(YELLOW)Setting up Husky hooks...$(NC)"
	pnpm prepare

setup: install ## Full setup including Docker and database
	@echo "$(YELLOW)Starting Docker services...$(NC)"
	$(MAKE) docker-up
	@echo "$(YELLOW)Waiting for services to be ready...$(NC)"
	sleep 10
	@echo "$(YELLOW)Running Hasura migrations...$(NC)"
	$(MAKE) hasura-migrate
	@echo "$(GREEN)Setup complete!$(NC)"

# ============================================================================
# Development
# ============================================================================

dev: ## Start all development servers
	pnpm dev

dev-web: ## Start web development server
	pnpm dev:web

dev-mobile: ## Start mobile development
	cd packages/mobile && flutter run

dev-android: ## Start Android development
	cd packages/android && ./gradlew run

dev-ios: ## Start iOS development (macOS only)
	cd packages/ios && xed .

# ============================================================================
# Build
# ============================================================================

build: ## Build all packages
	pnpm build

build-web: ## Build web package
	pnpm build:web

build-mobile: ## Build mobile for all platforms
	cd packages/mobile && flutter build apk && flutter build ios --no-codesign

build-android: ## Build Android release
	cd packages/android && ./gradlew assembleRelease

build-ios: ## Build iOS release (macOS only)
	cd packages/ios && xcodebuild -scheme ACM -configuration Release

# ============================================================================
# Testing
# ============================================================================

test: ## Run all tests
	pnpm test

test-web: ## Run web tests
	pnpm --filter @voxguard/web test

test-mobile: ## Run mobile tests
	cd packages/mobile && flutter test

test-android: ## Run Android tests
	cd packages/android && ./gradlew test

test-ios: ## Run iOS tests (macOS only)
	cd packages/ios && xcodebuild test -scheme ACM

test-coverage: ## Run tests with coverage
	pnpm test:coverage

# ============================================================================
# Code Quality
# ============================================================================

lint: ## Lint all code
	pnpm lint

lint-fix: ## Fix linting issues
	pnpm lint:fix

format: ## Format all code
	pnpm format

format-check: ## Check code formatting
	pnpm format:check

# ============================================================================
# Code Generation
# ============================================================================

codegen: ## Generate types from GraphQL schema
	pnpm codegen

codegen-watch: ## Watch and regenerate on schema changes
	pnpm codegen:watch

# ============================================================================
# Docker & Infrastructure
# ============================================================================

docker-up: ## Start all Docker services
	docker-compose -f infrastructure/docker/docker-compose.yml up -d

docker-down: ## Stop all Docker services
	docker-compose -f infrastructure/docker/docker-compose.yml down

docker-logs: ## View Docker logs
	docker-compose -f infrastructure/docker/docker-compose.yml logs -f

docker-clean: ## Remove all Docker volumes
	docker-compose -f infrastructure/docker/docker-compose.yml down -v

# ============================================================================
# Hasura
# ============================================================================

hasura-console: ## Open Hasura console
	cd hasura && hasura console

hasura-migrate: ## Apply Hasura migrations
	cd hasura && hasura migrate apply --all-databases

hasura-metadata: ## Apply Hasura metadata
	cd hasura && hasura metadata apply

hasura-seed: ## Seed Hasura database
	cd hasura && hasura seed apply

# ============================================================================
# Deployment
# ============================================================================

deploy-staging: ## Deploy to staging (all platforms)
	@echo "$(YELLOW)Deploying to staging...$(NC)"
	./tools/scripts/deploy.sh staging

deploy-production: ## Deploy to production (all platforms)
	@echo "$(YELLOW)Deploying to production...$(NC)"
	./tools/scripts/deploy.sh production

# ============================================================================
# Cleanup
# ============================================================================

clean: ## Clean all build artifacts
	pnpm clean
	cd packages/mobile && flutter clean 2>/dev/null || true
	cd packages/android && ./gradlew clean 2>/dev/null || true
	rm -rf node_modules .turbo

clean-docker: ## Remove all Docker resources
	docker-compose -f infrastructure/docker/docker-compose.yml down -v --rmi all

# codex-frontend-stack:start
schema:pull:
	./scripts/schema-pull.sh

codegen:all:
	./scripts/codegen-all.sh

test:all:
	./scripts/test-all.sh
# codex-frontend-stack:end
