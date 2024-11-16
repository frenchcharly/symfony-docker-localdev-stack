# Define the name of your webapp container
WEBAPP_CONTAINER = webapp
WEBAPP_DIRECTORY = webapp

# Define the default platform in the compose.yaml file
DEFAULT_DOCKER_PLATFORM = linux/arm64/v8

# Detect the current platform and map it to Docker's format
CURRENT_PLATFORM := $(shell uname -m)

# Set a platform replacement based on detected architecture
ifeq ($(CURRENT_PLATFORM),x86_64)
    REPLACEMENT_PLATFORM := linux/amd64
else ifeq ($(CURRENT_PLATFORM),arm64)
    REPLACEMENT_PLATFORM := linux/arm64/v8
else
    $(error Unsupported platform: $(CURRENT_PLATFORM))
endif

# Set default values
MAILER_LOCATION = 192.168.2.122:1025 # default: "mailer:1025" (from compose.yaml
DEFAULT_DB_TYPE = "postgresql"
DEFAULT_DB_LOCATION = database:5432
DEFAULT_DB_USER = dbuser
DEFAULT_DB_PASSWORD = mysecretpassword
DEFAULT_DB_NAME = webapp
DEFAULT_DB_SERVER_VERSION = 16
DEFAULT_SF_VERSION = lts
DEFAULT_DOCKER_NETWORK = my_custom_network

# Define a command for Docker Compose
DC_EXEC = docker compose

# Define a command to execute Composer commands in the webapp diretory.
COMP_REQ = composer require --working-dir=$(WEBAPP_DIRECTORY)

# Define a command to execute Symfony console commands in the webapp container
SF_EXEC = $(DC_EXEC) exec $(WEBAPP_CONTAINER) php bin/console

# Setup the project (clears the console, sets up the Docker Network, creates the Symfony Project, cleans the installed files & fixes Docker Compose file)
setup: clearscr setup-network sf-new sf-setup-clean fix-platform
	MAILER_DSN="MAILER_DSN=smtp://$$MAILER_LOCATION"; \
	@echo "Updating .env with: $$MAILER_DSN"; \
	sed -i.bak "s|^MAILER_DSN=.*$$|$$MAILER_DSN|" .env \
	@echo "Removing the placeholder file in database directory..."; \
	rm -Rf database/.placeholder;

# Configure the Database URL in the .env file
db-config: clearscr
	@echo "Configuring Database..."; \
	echo "Enter the database type (mysql, mariadb, postgresql) (default: $(DEFAULT_DB_TYPE)): "; \
	read DB_TYPE; \
	if [ -z "$$DB_TYPE" ]; then \
		DB_TYPE="$(DEFAULT_DB_TYPE)"; \
	fi; \
	echo "Enter the database location (default: $(DEFAULT_DB_LOCATION)):"; \
	read DB_LOCATION; \
	if [ -z "$$DB_LOCATION" ]; then \
		DB_LOCATION="$(DEFAULT_DB_LOCATION)"; \
	fi; \
	echo "Enter the database username:  (default: $(DEFAULT_DB_USER))"; \
	read DB_USER; \
	if [ -z "$$DB_USER" ]; then \
		DB_USER="$(DEFAULT_DB_USER)"; \
	fi; \
	echo "Enter the database password:  (default: $(DEFAULT_DB_PASSWORD))"; \
	read DB_PASS; \
	if [ -z "$$DB_PASS" ]; then \
		DB_PASS="$(DEFAULT_DB_PASSWORD)"; \
	fi; \
	echo "Enter the database name:  (default: $(DEFAULT_DB_NAME))"; \
	read DB_NAME; \
	if [ -z "$$DB_NAME" ]; then \
		DB_NAME="$(DEFAULT_DB_NAME)"; \
	fi; \
	echo "Enter the server version (default: $(DEFAULT_DB_SERVER_VERSION)):"; \
	read SERVER_VERSION; \
	if [ -z "$$SERVER_VERSION" ]; then \
		SERVER_VERSION="$(DEFAULT_DB_SERVER_VERSION)"; \
	fi; \
	if [ "$$DB_TYPE" = "mysql" ] || [ "$$DB_TYPE" = "mariadb" ]; then \
		CHARSET="utf8mb4"; \
		if [ "$$DB_TYPE" = "mariadb" ]; then \
			DB_TYPE="mysql"; \
			SERVER_VERSION="$$SERVER_VERSION-MariaDB"; \
		fi; \
	else \
		CHARSET="utf8"; \
	fi; \
	DB_URL="DATABASE_URL=$$DB_TYPE://$$DB_USER:$$DB_PASS@$$DB_LOCATION/$$DB_NAME?serverVersion=$$SERVER_VERSION&charset=$$CHARSET"; \
	echo "Updating .env with: $$DB_URL"; \
	sed -i.bak "s|^DATABASE_URL=.*$$|$$DB_URL|" .env

# Prompts for a Symfony Version, Creates a new Symfony Project and runs composer install.
sf-new:
	@echo "Setting up the Project..."; \
	@echo "What Symfony Version do you want to create this project with? [latest/lts] (default: $(DEFAULT_SF_VERSION))"; \
	read VERSION; \
	if [ -z "$$VERSION" ]; then \
		VERSION="$(DEFAULT_SF_VERSION)"; \
	fi; \
	if [ "$$VERSION" = "latest" ]; then \
		symfony new $(WEBAPP_DIRECTORY) --version="7.1.*" --webapp; \
	elif [ "$$VERSION" = "lts" ]; then \
		symfony new $(WEBAPP_DIRECTORY) --version="6.4.*" --webapp; \
	else \
		echo "Invalid version. Please specify 'latest' or 'lts'."; \
		exit 1; \
	fi

# Symfony --webapp cleanup
sf-setup-clean:
	@echo "Cleaning up the Symfony default Webapp install..."; \
	rm -Rf $(WEBAPP_DIRECTORY)/compose.yaml $(WEBAPP_DIRECTORY)/compose.override.yaml 

# Create the Docker Network then updates the network name in the Docker compose.yaml file to match the prompted value
setup-network:
	@echo "Creating Docker Network..."; \
	@echo "What name should the Docker Network have? (default: $(DEFAULT_DOCKER_NETWORK))"; \
	read NETWORK_NAME; \
	if [ -z "$$NETWORK_NAME" ]; then \
		NETWORK_NAME="$(DEFAULT_DOCKER_NETWORK)"; \
	fi; \
	docker network create --driver=bridge --subnet=10.0.0.0/20 --gateway=10.0.0.1 "$$NETWORK_NAME"; \
	sed -i.bak "s/my_custom_network/$$NETWORK_NAME/g" compose.yaml

# Update the containers platform in the compose.yaml file to match the detected platform
fix-platform:
	@if [ "$(REPLACEMENT_PLATFORM)" != "$(DEFAULT_DOCKER_PLATFORM)" ]; then \
		echo "Updating platform in compose.yaml from $(DEFAULT_DOCKER_PLATFORM) to $(REPLACEMENT_PLATFORM)..."; \
		sed -i.bak "s/$(DEFAULT_DOCKER_PLATFORM)/$(REPLACEMENT_PLATFORM)/g" compose.yaml; \
		echo "Platform updated successfully."; \
	else \
		echo "Platform is already set to $(REPLACEMENT_PLATFORM) in compose.yaml."; \
	fi
# Install the Maker Bundle
inst-maker:
	@echo "Installing Maker Bundle..."; \
	$(COMP_REQ) --dev symfony/maker-bundle

# Install the Doctrine Fixtures Bundle
inst-fixtures:
	@echo "Installing ORM fixtures..."; \
	$(COMP_REQ) --dev orm-fixtures

# Install the EasyAmdin Bundle
inst-admin:
	@echo "Installing EasyAdmin..."; \
	$(COMP_REQ) easycorp/easyadmin-bundle

# Install the API Platform Bundle
inst-api:
	@echo "Installing API Platform..."; \
	$(COMP_REQ) api

# Install the Tailwind CSS Bundle
inst-tailwind:
	@echo "Installing Tailwind CSS Bundle..."; \
	$(COMP_REQ) symfonycasts/tailwind-bundle; \
	php $(WEBAPP_DIRECTORY)/bin/console tailwind:init

# Install the Webpack Encore Bundle
inst-webpack:
	@echo "Installing Webpack Encore..."; \
	$(COMP_REQ) symfony/webpack-encore-bundle

# Install the 2FA Bundle, the Backup Code extension and the TOTP extension
inst-2fa:
	@echo "Installing two-factor authentication..."; \
	$(COMP_REQ) 2fa scheb/2fa-backup-code scheb/2fa-totp

# Install the Doctrine Migrations Bundle
inst-migrations:
	@echo "Installing Symfony Migrations Bundle..."; \
	$(COMP_REQ) doctrine/doctrine-migrations-bundle "^3.0"

# Start & Build containers
dc-up: clearscr fix-platform
	@echo "Starting containers..."
	@$(DC_EXEC) up -d --build

# Stop (& Remove) containers
dc-down:
	@echo "Stopping & removing containers..."
	@$(DC_EXEC) down

# Custom Docker PS outpu
dps: clearscr
	@docker ps -a --format "table {{.Names}}\t{{.Status}}"

# Load Data Fixtures
sf-fixtures: clearscr
	@$(SF_EXEC) doctrine:fixtures:load --no-interaction

# Target to create a new migration
sf-mm: clearscr
	@$(SF_EXEC) make:migration

# Target to run migrations
sf-dmm: clearscr
	@$(SF_EXEC) doctrine:migrations:migrate

# Clear the cache
sf-cc:
	@$(SF_EXEC) cache:clear

# Clear the cache without warmup
sf-ccnw:
	@$(SF_EXEC) cache:clear --no-warmup

# Warmup the cache
sf-cw:
	@$(SF_EXEC) cache:warmup

# Clear Console
clearscr:
	clear
