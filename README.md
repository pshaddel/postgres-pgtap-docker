# PostgreSQL with pgTAP Docker Images

This repository provides multi-version Docker images for PostgreSQL with the pgTAP extension pre-installed. pgTAP is a unit testing framework for PostgreSQL that allows you to write tests for your database in a familiar TAP (Test Anything Protocol) format.

## Features

- **Multi-version support**: PostgreSQL 18 and 17 images available
- **Multi-platform**: Supports linux/arm/v7, linux/arm64/v8, and linux/amd64
- **Multiple variants**: Standard (Debian), Alpine, Bookworm, and Trixie images
- **pgTAP pre-installed**: Ready-to-use testing framework
- **Auto-configured**: pgTAP extension enabled automatically on startup
- **Production-ready**: Based on official PostgreSQL images

## What is pgTAP?

pgTAP is a unit testing framework for PostgreSQL that provides a set of functions for writing tests in SQL. It supports functions like `ok()`, `is()`, and `isnt()` to test database objects, queries, and logic.

> TAP, the Test Anything Protocol, is a simple text-based interface between testing modules in a test harness. It decouples the reporting of errors from the presentation of the reports.

## Available Tags

### PostgreSQL 18 (Latest)

- `pshaddel/postgres-pgtap:latest` (same as 18.0)
- `pshaddel/postgres-pgtap:18` or `pshaddel/postgres-pgtap:18.0`
- `pshaddel/postgres-pgtap:18.0-alpine` or `pshaddel/postgres-pgtap:alpine`
- `pshaddel/postgres-pgtap:18.0-bookworm` or `pshaddel/postgres-pgtap:bookworm`
- `pshaddel/postgres-pgtap:18.0-trixie` or `pshaddel/postgres-pgtap:trixie`

### PostgreSQL 17

- `pshaddel/postgres-pgtap:17` or `pshaddel/postgres-pgtap:17.6`
- `pshaddel/postgres-pgtap:17.6-alpine`
- `pshaddel/postgres-pgtap:17.6-bookworm`
- `pshaddel/postgres-pgtap:17.6-trixie`

## How to Use

### Pull the Pre-Built Image

You can pull any of the available images from Docker Hub:

```sh
# Latest PostgreSQL 18 (recommended)
docker pull pshaddel/postgres-pgtap:latest

# Specific versions
docker pull pshaddel/postgres-pgtap:18
docker pull pshaddel/postgres-pgtap:17

# Alpine variants (smaller size)
docker pull pshaddel/postgres-pgtap:alpine
docker pull pshaddel/postgres-pgtap:17.6-alpine
```

### Run the Container

Run the container with the following command:

```sh
docker run -d --name my_postgres_pgtap \
       -e POSTGRES_USER=myuser \
       -e POSTGRES_PASSWORD=mypassword \
       -e POSTGRES_DB=mydb \
       -p 5432:5432 \
       pshaddel/postgres-pgtap:latest
```

### Access the Database

You can access the database in two ways:

1. **Using a shell inside the container:**

   ```sh
   docker exec -it my_postgres_pgtap sh
   ```

   Then, use `psql` to connect to the database:

   ```sh
   psql -U myuser -d mydb
   ```

2. **Using a PostgreSQL client:**

   Connect to the database using the environment variables and the exposed port:

   ```sh
   psql -h localhost -p 5432 -U myuser -d mydb
   ```

### Verify pgTAP Installation

Once connected to the database, you can verify that the `pgTAP` extension is installed and get its version:

```sql
-- Check if pgTAP extension is available
SELECT * FROM pg_available_extensions WHERE name = 'pgtap';

-- Get pgTAP version (it's pre-enabled in these images)
SELECT pgtap_version();
```

You should see `pgTAP` listed as an available extension and the version should return `1.3`.

### Writing Tests with pgTAP

To write tests, you can use pgTAP functions like `ok()`, `is()`, and `isnt()`. For example:

```sql
SELECT plan(2);

SELECT ok(1 = 1, '1 equals 1');
SELECT is(2 + 2, 4, '2 plus 2 equals 4');

SELECT * FROM finish();
```

## Building Images Locally

If you want to build the images locally, clone this repository and run the build script:

```sh
# Make the script executable
chmod +x build-all-versions.sh

# Build all versions and push to Docker Hub (requires login)
./build-all-versions.sh
```

Or build specific versions manually:

```sh
# Build PostgreSQL 18 locally (for testing)
docker build -t local-postgres-pgtap-18 -f test-dockerfile-18 .

# Build PostgreSQL 17 locally
docker build -t local-postgres-pgtap-17 -f dockerfile .
```

## How It Works

The build process performs different steps depending on the PostgreSQL version:

### PostgreSQL 18 Build Process

1. Starts with the official PostgreSQL 18 image
2. Installs `postgresql-17-pgtap` package (since 18-specific package isn't available yet)
3. Copies pgTAP extension files from PostgreSQL 17 directories to PostgreSQL 18 directories
4. Enables the `pgTAP` extension automatically on container startup

### PostgreSQL 17 Build Process

1. Starts with the official PostgreSQL 17 image
2. Installs `postgresql-17-pgtap` package directly
3. Enables the `pgTAP` extension automatically on container startup

### Multi-Platform Support

All images are built for multiple architectures:

- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64/v8` (ARM 64-bit, Apple Silicon, etc.)
- `linux/arm/v7` (ARM 32-bit)

## Automatic Updates

This repository includes automated workflows that:

- **Daily checks**: Automatically check for new PostgreSQL versions every day at 2 AM UTC
- **Auto-building**: Automatically build and push new images when updates are detected
- **Pull requests**: Create pull requests with version updates for review
- **Multi-version support**: Handle both PostgreSQL 18 and 17 updates independently

The automation ensures that the latest PostgreSQL versions with pgTAP are always available.

## Troubleshooting

If you encounter any issues:

- Ensure that the required ports (default: `5432`) are not blocked by your firewall.
- Verify that the environment variables (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`) are correctly set.
- Check the container logs for errors:

  ```sh
  docker logs my_postgres_pgtap
  ```

## License

This project is licensed under the MIT License.

## Acknowledgments

- [pgTAP GitHub Repository](https://github.com/theory/pgtap)
- [PostgreSQL Official Docker Image](https://hub.docker.com/_/postgres)
