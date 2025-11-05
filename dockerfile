# Start with the official PostgreSQL image
FROM postgres:17

# Install pgTAP using apt
RUN apt-get update && apt-get install -y \
    postgresql-17-pgtap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# enable the extension
RUN echo "CREATE EXTENSION pgtap;" > /docker-entrypoint-initdb.d/01_pgtap.sql
