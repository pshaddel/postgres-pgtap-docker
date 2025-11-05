# PostgreSQL with pgTAP Docker Image

This repository contains a Dockerfile for creating a PostgreSQL 17 container with the pgTAP extension pre-installed. pgTAP is a unit testing framework for PostgreSQL that allows you to write tests for your database in a familiar TAP (Test Anything Protocol) format.

## Features

- Based on the official PostgreSQL 17 image.
- Includes pgTAP for database unit testing.
- Pre-configured to enable the `pgTAP` extension on container startup.
- Ready-to-use container for testing PostgreSQL databases.

## What is pgTAP?

pgTAP is a unit testing framework for PostgreSQL that provides a set of functions for writing tests in SQL. It supports functions like `ok()`, `is()`, and `isnt()` to test database objects, queries, and logic.

> TAP, the Test Anything Protocol, is a simple text-based interface between testing modules in a test harness. It decouples the reporting of errors from the presentation of the reports.

## How to Use

### Pull the Pre-Built Image

You can pull the pre-built image from Docker Hub:

```sh
docker pull pshaddel/postgres-pgtap:latest
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

Once connected to the database, you can verify that the `pgTAP` extension is installed by running:

```sql
SELECT * FROM pg_available_extensions WHERE name = 'pgtap';
```

You should see `pgTAP` listed as an available extension.

### Writing Tests with pgTAP

To write tests, you can use pgTAP functions like `ok()`, `is()`, and `isnt()`. For example:

```sql
SELECT plan(2);

SELECT ok(1 = 1, '1 equals 1');
SELECT is(2 + 2, 4, '2 plus 2 equals 4');

SELECT * FROM finish();
```

## Building the Image Locally

If you want to build the image locally, clone this repository and run:

```sh
docker build -t postgres-pgtap .
```

Then, run the container as described above.

## How It Works

The Dockerfile performs the following steps:

1. Starts with the official PostgreSQL 17 image.
2. Installs pgTAP from Debian using apt.
3. Enables the `pgTAP` extension by adding it to the PostgreSQL initialization scripts.

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
