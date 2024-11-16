# Usage

1. (Optional) Update the default values inside the `Makefile` if you plan to reuse/fork this:
    - if you require your symfony folder to be named differently (from `webapp`), update `WEBAPP_DIRECTORY` value
    - if you have custom database that you reuse for multiple projects, update the `DEFAULT_DB_TYPE`, `DEFAULT_DB_LOCATION`, `DEFAULT_DB_USER`, `DEFAULT_DB_PASSWORD`, `DEFAULT_DB_NAME` and `DEFAULT_DB_SERVER_VERSION` so it matches your instance. Do not customise these values otherwise, they correspond to the `compose.yaml` default values.
    - if you always want to switch the symfony default version to be `latest` instead of `lts`, update the `DEFAULT_SF_VERSION`
    - if you want to update the default value for the Docker Network that'll be created, update the `DEFAULT_DOCKER_NETWORK` value
    - if you don't have a dedicated mailer on your network like me, remove the comments (# symbol) for the mailer container/service.
2. run `make setup`, this will:
    - Create a Docker Network (will prompt you for a name)
    - Create a new Symfony project (will prompt you for the Version) into the `WEBAPP_DIRECTORY` directory
    - Remove both the default docker compose YAML files from the Symfony template (`compose.yaml` & `compose.override.yaml`)
    - Update the `compose.yaml` file with the actual platform you're running on (Apple Silicon by default, aka arm64/v8)
    - Replace the `MAILER_DSN` variable with the correct value into the `.env` file (from the Symfony application)
    - Remove the placeholder file in the `./database` directory
3. run `make db-config` to Configure the `DATABASE_URL` in the `.env` file (from the Symfony application), this will prompt for every parameter of the URL required by Symfony
4. launch the containers : `make dc-up`
5. check the containers: `make dps`

If you need to shut down the containers, you can run `make dc-down`.

## Utilities (Makefile)

There is a bunch of commands in the `Makefile` to improve QoL, as follow:

### Databases Commands

- `make sf-fixtures` to load fixtures into the database
- `make sf-mm` to make a new migration
- `make sf-dmm` to migrate any migrations awaiting to be pushed to the database

### Cache related Commands

- `make sf-cc` to clear cache
- `make sf-ccnw` to clear cache without warmup
- `make sf-cw` to warmup the cache only

### Popular and Often-Reused-Packages Commands

- `make inst-maker` to install the Maker Bundle
- `make inst-fixtures` to install the Doctrine Fixtures Bundle
- `make inst-admin` to install the EasyAmdin Bundle
- `make inst-api` to install the API Platform Bundle
- `make inst-tailwind` to install the Tailwind CSS Bundle
- `make inst-webpack` to install the Webpack Encore Bundle
- `make inst-2fa` to install the 2FA Bundle, the Backup Code extension & the TOTP extension
- `make inst-migrations` to install the Doctrine Migrations Bundle
